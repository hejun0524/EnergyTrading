function _get_observations!(
    agent::Agent,
    market::Market,
    clock::Clock,
    demand_shape::Shape,
)::Vector{Float64}
    time_of_day = _get_time_counter_of_day(clock)
    agent_can_produce = agent isa Prosumer || agent isa Producer
    panel_efficiency = agent_can_produce ? agent.panel.efficiency : 0.0
    panel_max_rate = agent_can_produce ? agent.panel.max_rate : 0.0
    storage_status = agent_can_produce ? agent.storage.current_level : 0.0
    storage_size = agent_can_produce ? agent.storage.capacity : 0.0
    # 12 time slots demand forecast (6 - 17)
    demand_forecast = zeros(12)
    if agent isa Prosumer || agent isa Consumer 
        demand_forecast = _get_forecast(demand_shape, clock.time_counter, 12)
    end
    demand_forecast[1] = agent.current_basic_demand

    _size_correction!(demand_forecast, 12)
    # market price and quantity of next 12 time slots (18 - 41)
    t0 = clock.time_counter
    t1 = min(clock.n_steps, t0 + 11)
    ts = [_get_time_counter_of_day(clock, k) for k = t0:t1]
    market_data = _get_market_observations(market, ts)
    # return states
    return [
        time_of_day,
        panel_efficiency,
        panel_max_rate,
        storage_status,
        storage_size,
        demand_forecast...,
        market_data...,
    ]
end

function _size_correction!(v::Vector, k::Int)
    if length(v) < k
        push!(v, zeros(k - length(v))...)
    end
end

function _get_market_observations(market::CDAMarket, ts::Vector{Int})
    market_price = market.price_history[ts]
    market_quantity = market.quantity_history[ts]
    _size_correction!(market_price, 12)
    _size_correction!(market_quantity, 12)
    # 24 elements
    return [market_price..., market_quantity...]
end

function _get_market_observations(market::QuantityCDAMarket, ts::Vector{Int})
    market_ratio = market.ratio_history[ts]
    _size_correction!(market_ratio, 12)
    # 16 elements
    return [
        market.current_supply,
        market.current_demand,
        market.current_ratio,
        market.current_price,
        market_ratio...,
    ]
end
