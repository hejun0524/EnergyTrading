function _grid_buy_from_agent!(
    grid::Grid,
    agent::Agent,
    quantity::Float64,
    network::NetworkInstance,
    clock::Clock,
)::Float64
    agent isa Producer ||
        agent isa Prosumer ||
        error("Grid can only buy from producers and prosumers.")
    # update grid
    grid.buy_in_quantity += quantity
    grid_cost = quantity * grid.buy_in_price[clock.time_counter]
    grid.cost += grid_cost
    # update network
    vsc = _compute_vsc(network, agent.bus)
    ptdf = _compute_ptdf(network, agent.bus, grid.bus) # agent to grid
    _update_network!(network, quantity, vsc, ptdf)
    # update agent
    _add_snapshot_to_history!(
        agent,
        target = grid,
        action = "sell",
        clock = clock,
        price = grid.buy_in_price[clock.time_counter],
        quantity = quantity,
    )
    return grid_cost
end

function _grid_sell_to_agent!(
    grid::Grid,
    agent::Agent,
    quantity::Float64,
    network::NetworkInstance,
    clock::Clock,
)::Float64
    agent isa Consumer ||
        agent isa Prosumer ||
        error("Grid can only sell to consumers and prosumers.")
    # update grid
    grid.sell_out_quantity += quantity
    grid_revenue = quantity * grid.sell_out_price[clock.time_counter]
    grid.revenue += grid_revenue
    # update network
    vsc = _compute_vsc(network, agent.bus)
    ptdf = _compute_ptdf(network, grid.bus, agent.bus) # grid to agent
    _update_network!(network, quantity, vsc, ptdf)
    # update agent
    _add_snapshot_to_history!(
        agent,
        target = grid,
        action = "buy",
        clock = clock,
        price = grid.sell_out_price[clock.time_counter],
        quantity = quantity,
    )
    return grid_revenue
end
