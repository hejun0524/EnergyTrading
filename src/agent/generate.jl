function _generate_agent_order!(
    agent::Union{Agent, Nothing};
    clock::Clock,
    market::Market,
    demand_shape::Shape,
    supply_shape::Shape,
    network::NetworkInstance,
    grid::Grid,
)::Union{Order, Nothing}
    agent !== nothing || return nothing 
    t_start = clock.time_counter # time counter at start
    t_length = _allocate_time_counts() # total time counts
    t_expire = t_start + t_length - 1
    trader_group = clock.time_groups[t_start]
    if typeof(agent) === Consumer 
        # consumer get flexible demand
        current_demand = _get_real_time(demand_shape, t_start)
        flexible_demand = _get_forecast(
            demand_shape, t_start, t_length, first_element_value = current_demand)
        if flexible_demand > 0.0
            return _generate_trader_order!(
                agent, 
                agent.buyers[trader_group],
                quantity = flexible_demand,
                order_type = "bid",
                time_counter_submit = t_start,
                time_counter_expire = t_expire
            )
        end
    elseif typeof(agent) === Producer 
        # producer get generation
        current_supply = _get_real_time(supply_shape, t_start)
        current_storage_flow = _update_storage!(agent.storage, current_supply)
        # if there is surplus, need to deal with grid first 
        if current_storage_flow > 0.0
            _grid_buy_from_agent!(grid, agent, current_storage_flow, network, clock)
        end
        # then generate order with all storage quantity
        ask_quantity = agent.storage.current_level * agent.storage.efficiency
        # only trade if ask quantity is positive 
        if ask_quantity > 0.0
            _freeze_storage!(agent.storage, ask_quantity)
            return _generate_trader_order!(
                agent, 
                agent.sellers[trader_group],
                quantity = ask_quantity,
                order_type = "ask",
                time_counter_submit = t_start,
                time_counter_expire = t_expire
            )
        end
    elseif typeof(agent) === Prosumer 
        # get flexible demand 
        current_demand = _get_real_time(demand_shape, t_start)
        flexible_demand = _get_forecast(
            demand_shape, t_start, t_length, first_element_value = current_demand)
        # get generation
        current_supply = _get_real_time(supply_shape, t_start)
        current_storage_flow = _update_storage!(agent.storage, current_supply - flexible_demand)
        # handle overflow (grid)
        if current_storage_flow > 0.0 
            _grid_buy_from_agent!(grid, agent, current_storage_flow, network, clock)
        end
        # place ask
        max_quantity = (agent.storage.current_level - flexible_demand) * agent.storage.efficiency
        if max_quantity > 0.0
            ask_quantity = _estimate_selling_quantity(market, 
                max_quantity, flexible_demand, t_start, t_expire, clock)
            _freeze_storage!(agent.storage, ask_quantity)
            return _generate_trader_order!(
                agent, 
                agent.sellers[trader_group],
                quantity = ask_quantity,
                order_type = "ask",
                time_counter_submit = t_start,
                time_counter_expire = t_expire
            )
        end
        # handle underflow (bid)
        if current_storage_flow < 0.0 
            return _generate_trader_order!(
                agent, 
                agent.buyers[trader_group],
                quantity = -current_storage_flow,
                order_type = "bid",
                time_counter_submit = t_start,
                time_counter_expire = t_expire
            )
        end
    end
    return nothing
end
