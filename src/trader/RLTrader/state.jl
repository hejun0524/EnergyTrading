function _get_observations!(
    agent::Agent,
    market::CDAMarket,
    clock::Clock,
    grid::Grid,
    network::NetworkInstance,
)::Vector{Any}
    time_of_day = _get_time_counter_of_day(clock)
    agent_can_produce = agent isa Prosumer || agent isa Producer 
    panel_efficiency = agent_can_produce ? agent.panel.efficiency : 0.0
    panel_max_rate = agent_can_produce ? agent.panel.max_rate : 0.0
    storage_status = agent_can_produce ? agent.storage.current_level : 0.0
    storage_size = agent_can_produce ? agent.storage.capacity : 0.0
    # 12 time slots demand forecast (6 - 17)
    demand_forecast = agent isa Producer ? zeros(12) : _get_forecast(
        agent.demand, clock.time_counter, 12)
    # some agent may need to prosume 
    if agent_can_produce
        current_supply = _get_real_time(supply_shape, clock.time_counter)
        # store into storage unit by satisfying current demand first
        current_storage_flow = _update_storage!(agent.storage, 
            current_supply - demand_forecast[1])
        # if there is surplus, need to deal with grid first, no learning
        # else this is a demand
        if current_storage_flow > 0.0
            _grid_buy_from_agent!(grid, agent, current_storage_flow, network, clock)
        else 
            demand_forecast[1] = abs(current_storage_flow)
        end
    end
    # market price and quantity of next 12 time slots (18 - 41)
    t0 = clock.time_counter
    t1 = min(clock.n_steps, t0 + 11)
    ts = [_get_time_counter_of_day(clock, k) for k = t0:t1]
    market_price = market.price_history[ts]
    market_quantity = market.quantity_history[ts]
    # return states
    return [
        time_of_day,
        panel_efficiency,
        panel_max_rate,
        storage_status,
        storage_size,
        demand_forecast...,
        market_price...,
        market_quantity...,
    ]
end