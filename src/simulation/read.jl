using JSON
using DataStructures
using Statistics
using Distributions

function read(path::String)::SimulationInstance
    @info "Reading input file from $(path)..."
    file = open(path)
    json = JSON.parse(file, dicttype = () -> DefaultOrderedDict(nothing))
    clock = _read_parameters(json["Parameters"], json["Time groups"])
    demand_shape = _read_shape_data(json["Demands"], clock, "demand")
    supply_shape = _read_shape_data(json["Supplies"], clock, "supply", use_time_divisor = false)
    network = _read_network_instance(json["Buses"], json["Transmission lines"])
    grid = _read_grid(json["Grid"], network, clock)
    agents = _read_agents(json["Agents"], network, clock, grid, demand_shape)
    market = _read_market(json["Market"], clock)
    close(file)
    return SimulationInstance(
        clock = clock,
        grid = grid,
        network = network,
        market = market,
        demand = demand_shape,
        supply = supply_shape,
        agents = agents,
    )  
end

```
This function synchronizes the dimensions of any vector to system clock
```
function _time_dimension_adjust(
    arr::Vector;
    arr_time_step::Int,
    sys_time_step::Int,
    arr_total_time::Int,
    sys_total_time::Int,
    max_steps::Int,
)::Union{Vector{Int}, Vector{Float64}}
    # repeat single
    (arr_time_step % sys_time_step == 0) || error("System time step is not a divisor.")
    repeat_single = arr_time_step ÷ sys_time_step
    # repeat all 
    extra_repeat = sys_total_time % arr_total_time == 0 ? 0 : 1
    repeat_all = sys_total_time ÷ arr_total_time + extra_repeat
    # repeat and truncate
    new_arr = [i for _ in 1:repeat_all for i in arr for _ in 1:repeat_single]
    return new_arr[1:max_steps]
end

```
This function reads the parameters and initiates the clock
```
function _read_parameters(
    parameters::DefaultOrderedDict,
    groups::DefaultOrderedDict
)::Clock
    total_time = parameters["Total time (d)"]
    total_time = total_time * 24 * 60 
    time_step = parameters["Time step (min)"]
    # construct clock
    (total_time % time_step == 0) || error(
        "The total time length is not divisible by the time step.")
    time_one_day = 24 * 60
    (time_one_day % time_step == 0) || error(
        "The total time length of one day is not divisible by the time step.")
    n_steps = total_time ÷ time_step
    n_steps_one_day = time_one_day ÷ time_step
    # construct clock groups
    group_params = groups["Parameters"]
    group_time_step = group_params["Time step (min)"]
    group_total_time = group_params["Total time (h)"] * 60
    group_labels = groups["Labels"]
    group_label_notes = groups["Label notes"]
    if group_labels === nothing 
        group_labels = [1 for _ in 1:(group_total_time ÷ group_time_step)]
    end
    if group_label_notes === nothing 
        group_label_notes = Dict(1 => "One group")
    else 
        group_label_notes = Dict(parse(Int, index) => note 
            for (index, note) in group_label_notes)
    end
    time_groups = _time_dimension_adjust(
        group_labels,
        arr_time_step = group_time_step,
        sys_time_step = time_step,
        arr_total_time = group_total_time,
        sys_total_time = total_time,
        max_steps = n_steps,
    )
    if time_groups === nothing
        time_groups = ones(n_steps)
    end
    (n_steps == length(time_groups)) || error(
        "The total number of time groups do not match other information.")
    clock = Clock(
        T = total_time,
        time_step = time_step,
        n_steps = n_steps,
        n_steps_one_day = n_steps_one_day,
        time_groups = time_groups,
        time_group_notes = group_label_notes,
        n_groups = length(Set(time_groups))
    )
    return clock
end

```
This function reads the grid settings
```
function _read_grid(
    dict::DefaultOrderedDict,
    network:: NetworkInstance,
    clock::Clock,
)::Grid
    params = dict["Parameters"]
    total_time = params["Total time (h)"] * 60
    time_step = params["Time step (min)"]
    (total_time % time_step == 0) || error(
        "Shape file total time length is not divisible by the time step.")
    # read prices
    sell_out_price = _time_dimension_adjust(
        _time_series(dict["Prices"]["Sell-out price"], total_time ÷ time_step),
        arr_time_step = time_step,
        sys_time_step = clock.time_step,
        arr_total_time = total_time,
        sys_total_time = clock.T,
        max_steps = clock.n_steps,
    )
    buy_in_price = _time_dimension_adjust(
        _time_series(dict["Prices"]["Buy-in price"], total_time ÷ time_step),
        arr_time_step = time_step,
        sys_time_step = clock.time_step,
        arr_total_time = total_time,
        sys_total_time = clock.T,
        max_steps = clock.n_steps,
    )
    return Grid(
        sell_out_price = sell_out_price,
        buy_in_price = buy_in_price,
        bus = network.buses[1], # slack bus
    )
end

```
This function reads the shape data
```
function _read_shape_data(
    dict::DefaultOrderedDict,
    clock::Clock,
    shape_name::String;
    use_time_divisor::Bool = true
)::Shape
    params = dict["Parameters"]
    total_time = params["Total time (h)"] * 60
    time_step = params["Time step (min)"]
    (total_time % time_step == 0) || error(
        "Shape file total time length is not divisible by the time step.")
    (time_step % clock.time_step == 0) || error(
        "Shape file time step is not divisible by the clock time step.")
    shape_data = zeros(total_time ÷ time_step)
    for (_, each_data) in dict["Data"]
        shape_data += each_data
    end
    if use_time_divisor
        shape_data /= time_step ÷ clock.time_step
    end

    shape_data_corrected = _time_dimension_adjust(
        shape_data,
        arr_time_step = time_step,
        sys_time_step = clock.time_step,
        arr_total_time = total_time,
        sys_total_time = clock.T,
        max_steps = clock.n_steps,
    )
    shape = Shape(
        shape_name,
        shape_data_corrected,
        shape_data,
        mean(shape_data),
        time_step,
        total_time,
    )
    return shape
end

```
This function reads the agents
```
function _read_agents(
    agent_dict::DefaultOrderedDict,
    network::NetworkInstance,
    clock::Clock,
    grid::Grid,
    demand_shape::Shape,
)::Vector{Agent}
    agents = []
    for (name, agent_info) in agent_dict
        if agent_info["Role"] == "Consumer"
            push!(agents, Consumer(
                index = length(agents) + 1,
                name = name,
                bus = network.buses_by_name[agent_info["Bus"]],
                trader = _construct_trader(agent_info["Trader"], grid),
            ))
        elseif agent_info["Role"] == "Producer"
            push!(agents, Producer(
                index = length(agents) + 1,
                name = name,
                bus = network.buses_by_name[agent_info["Bus"]],
                trader = _construct_trader(agent_info["Trader"], grid),
                storage = Storage(
                    capacity = agent_info["Storage capacity"] == -1 ? ceil(
                        16 * demand_shape.average * agent_info["PV type"]) : agent_info["Storage capacity"],
                    efficiency = agent_info["Storage efficiency"],
                ),
                panel = SolarPanel(
                    max_rate = ceil(demand_shape.average * agent_info["PV type"]),
                    efficiency = agent_info["PV efficiency"]
                )
            ))
        elseif agent_info["Role"] == "Prosumer"
            push!(agents, Prosumer(
                index = length(agents) + 1,
                name = name,
                bus = network.buses_by_name[agent_info["Bus"]],
                trader = _construct_trader(agent_info["Trader"], grid),
                storage = Storage(
                    capacity = agent_info["Storage capacity"] == -1 ? ceil(
                        16 * demand_shape.average * agent_info["PV type"]) : agent_info["Storage capacity"],
                    efficiency = agent_info["Storage efficiency"],
                ),
                panel = SolarPanel(
                    max_rate = ceil(demand_shape.average * agent_info["PV type"]),
                    efficiency = agent_info["PV efficiency"]
                )
            ))
        else
            error("The role of agent $name is undefined.")
        end
    end
    return agents
end

```
This function reads the network buses and lines
```
function _read_market(
    market_dict::DefaultOrderedDict,
    clock::Clock
)::Market 
    market_dict["Type"] !== nothing || error(
        "Please specify a market type")
    # get arrival
    arrival = nothing
    if market_dict["Arrival type"] == "Exponential"
        arrival = Exponential(market_dict["Interarrival time (min)"])
    end
    # construct the market
    if market_dict["Type"] === "CDA" 
        return CDAMarket(
            arrival = arrival,
            price_history = zeros(clock.n_steps_one_day),
            quantity_history = zeros(clock.n_steps_one_day),
        )
    end
    error("$(market_dict["Type"]) is not a supported market type.")
end

```
This function reads the network buses and lines
```
function _read_network_instance(
    bus_dict::DefaultOrderedDict,
    line_dict::DefaultOrderedDict;
    instance_name::Union{Nothing, String} = nothing,
    tol::Float64 = 1e-10,
)::NetworkInstance
    lines = TransmissionLine[]
    buses = Bus[]

    name_to_bus = Dict{String,Bus}()
    name_to_line = Dict{String,TransmissionLine}()

    # Read network buses
    for (bus_name, dict) in bus_dict
        bus = Bus(
            bus_name,
            length(buses),
            length(buses) + 1,
            dict["P Load (kW)"],
            dict["Q Load (kVar)"],
            dict["Maximum voltage (p.u.)"] * dict["Base KV"],
            dict["Minimum voltage (p.u.)"] * dict["Base KV"],
            dict["Voltage magnitude"] * dict["Base KV"],
            dict["Voltage angle"],
            dict["Base KV"],
        )
        name_to_bus[bus_name] = bus
        push!(buses, bus)
    end

    # Read network transmission lines
    for (line_name, dict) in line_dict
        line = TransmissionLine(
            line_name,
            length(lines) + 1,
            length(lines) + 1,
            name_to_bus[dict["Source bus"]],
            name_to_bus[dict["Target bus"]],
            dict["Reactance (ohms)"],
            dict["Susceptance (S)"],
            dict["Normal flow limit (kW)"],
            dict["Emergency flow limit (kW)"],
            0.0,
            dict["Utilization fee (\$/MW)"]
        )
        name_to_line[line_name] = line
        push!(lines, line)
    end

    # Construct network instance
    if instance_name === nothing 
        instance_name = "my_network_instance"
    end

    # compute advanced values
    Y = _admittance_matrix(buses = buses, lines = lines)
    G = _conductance_matrix(Y)
    isf = _injection_shift_factors(buses = buses, lines = lines)
    isf[abs.(isf).<tol] .= 0

    network = NetworkInstance(
        buses_by_name = name_to_bus,
        buses = buses,
        lines_by_name = name_to_line,
        lines = lines,
        name = instance_name,
        Y = Y,
        G = G,
        isf = isf,
    )
    
    return network
end
