function _produce_and_consume!(
    agent::Agent,
    clock::Clock;
    demand_shape::Shape,
    supply_shape::Shape,
    network::NetworkInstance,
    grid::Grid,
)
    t = clock.time_counter
    # generate current demand 
    current_demand = _get_real_time(demand_shape, t)
    current_solar_rate = min(_get_real_time(supply_shape, t), 1.0)
    # get current information
    if agent isa Consumer 
        # consumers only consume if not in market
        if !agent.in_market
            _grid_sell_to_agent!(grid, agent, current_demand, network, clock)
        end
    elseif agent isa Producer 
        # producers always produce, never consume
        current_supply = _generate_solar_energy(agent.panel, current_solar_rate)
        current_storage_flow = _update_storage!(agent.storage, current_supply)
        if current_storage_flow > 0.0
            _grid_buy_from_agent!(grid, agent, current_storage_flow, network, clock)
        end
    elseif agent isa Prosumer 
        # prosumers always produce, and only consume if not in market
        current_supply = _generate_solar_energy(agent.panel, current_solar_rate)
        current_demand = agent.in_market && agent.in_market_as == "buyer" ? 0.0 : current_demand
        current_storage_flow = _update_storage!(agent.storage, current_supply - current_demand)
        # overflow sells to grid, underflow buys from grid
        if current_storage_flow > 0.0
            _grid_buy_from_agent!(grid, agent, current_storage_flow, network, clock)
        elseif current_storage_flow < 0.0
            _grid_sell_to_agent!(grid, agent, -current_storage_flow, network, clock)
        end
    end 
end