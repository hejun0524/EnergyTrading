using JSON
using DataStructures
using Statistics

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
    market = _construct_market(clock)
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
This function makes sure the input is time series 
```
function _time_series(x, T; default = nothing)
    x !== nothing || return default
    x isa Array || return [x for _ in 1:T]
    return x
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
    clock = _construct_clock(total_time, time_step)

    group_params = groups["Parameters"]
    group_time_step = group_params["Time step (min)"]
    group_total_time = group_params["Total time (h)"] * 60
    group_labels = groups["Labels"]
    group_label_notes = groups["Label notes"]
    if group_labels === nothing 
        group_labels = [1 for _ in 1:(group_total_time ÷ group_time_step)]
    end
    if group_label_notes === nothing 
        group_label_notes = Dict("1" => "One group")
    end
    time_groups = _time_dimension_adjust(
        group_labels,
        arr_time_step = group_time_step,
        sys_time_step = time_step,
        arr_total_time = group_total_time,
        sys_total_time = total_time,
        max_steps = clock.n_steps,
    )
    _update_clock_groups!(
        clock,
        time_groups = time_groups,
        time_group_notes = Dict(parse(Int, index) => note 
            for (index, note) in group_label_notes),
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
    return _construct_grid(
        sell_out_price,
        buy_in_price,
        network.buses[1], # slack bus
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
    shape_data = zeros(total_time ÷ time_step)
    for (_, each_data) in dict["Data"]
        shape_data += each_data
    end

    shape_data_corrected = _time_dimension_adjust(
        shape_data,
        arr_time_step = time_step,
        sys_time_step = clock.time_step,
        arr_total_time = total_time,
        sys_total_time = clock.T,
        max_steps = clock.n_steps,
    ) / (use_time_divisor ? time_step : 1)
    shape = Shape(
        shape_name,
        shape_data_corrected,
        mean(shape_data),
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
                buyers = [ZIPTrader(
                    action_type = "buy",
                    trader_group = g,
                    limit_price = grid.sell_out_price,
                    current_price = grid.sell_out_price[findfirst(x -> x == g, clock.time_groups)],
                    price_history = [grid.sell_out_price[findfirst(x -> x == g, clock.time_groups)]],
                ) for g in 1:clock.n_groups]
            ))
        elseif agent_info["Role"] == "Producer"
            push!(agents, Producer(
                index = length(agents) + 1,
                name = name,
                bus = network.buses_by_name[agent_info["Bus"]],
                sellers = [ZIPTrader(
                    action_type = "sell",
                    trader_group = g,
                    limit_price = grid.buy_in_price,
                    current_price = grid.buy_in_price[findfirst(x -> x == g, clock.time_groups)],
                    price_history = [grid.buy_in_price[findfirst(x -> x == g, clock.time_groups)]],
                ) for g in 1:clock.n_groups],
                storage = Storage(
                    capacity = agent_info["Storage capacity"] == -1 ? 16 * demand_shape.average * agent_info["PV type"] : agent_info["Storage capacity"],
                    efficiency = agent_info["Storage efficiency"],
                ),
                panel = SolarPanel(
                    max_rate = demand_shape.average * agent_info["PV type"],
                    efficiency = agent_info["PV efficiency"]
                ),
                estimation_method = DiscountedFuture(
                    discount_factor = agent_info["Allow supply forecast"],
                    allow_supply_prediction = agent_info["Allow demand forecast"],
                    allow_demand_prediction = agent_info["Discount factor"],
                    lookahead_steps = agent_info["Forecast length (min)"] ÷ clock.time_step,
                )
            ))
        elseif agent_info["Role"] == "Prosumer"
            push!(agents, Prosumer(
                index = length(agents) + 1,
                name = name,
                bus = network.buses_by_name[agent_info["Bus"]],
                buyers = [ZIPTrader(
                    action_type = "buy",
                    trader_group = g,
                    limit_price = grid.sell_out_price,
                    current_price = grid.sell_out_price[findfirst(x -> x == g, clock.time_groups)],
                    price_history = [grid.sell_out_price[findfirst(x -> x == g, clock.time_groups)]],
                ) for g in 1:clock.n_groups],
                sellers = [ZIPTrader(
                    action_type = "sell",
                    trader_group = g,
                    limit_price = grid.buy_in_price,
                    current_price = grid.buy_in_price[findfirst(x -> x == g, clock.time_groups)],
                    price_history = [grid.buy_in_price[findfirst(x -> x == g, clock.time_groups)]],
                ) for g in 1:clock.n_groups],
                storage = Storage(
                    capacity = agent_info["Storage capacity"] == -1 ? 16 * demand_shape.average * agent_info["PV type"] : agent_info["Storage capacity"],
                    efficiency = agent_info["Storage efficiency"],
                ),
                panel = SolarPanel(
                    max_rate = demand_shape.average * agent_info["PV type"],
                    efficiency = agent_info["PV efficiency"]
                ),
                estimation_method = DiscountedFuture(
                    discount_factor = agent_info["Allow supply forecast"],
                    allow_supply_prediction = agent_info["Allow demand forecast"],
                    allow_demand_prediction = agent_info["Discount factor"],
                    lookahead_steps = agent_info["Forecast length (min)"] ÷ clock.time_step,
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
