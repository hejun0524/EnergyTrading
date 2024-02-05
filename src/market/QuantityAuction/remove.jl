function _remove_expired_orders!(
    market::QuantityCDAMarket,
    grid::Grid,
    network::NetworkInstance,
    clock::Clock;
    tol::Float64 = 1e-5,
)::Vector{Rejection}
    expired_transactions = Rejection[]
    current_time_counter = clock.time_counter
    # remove small amount (precision fix)
    filter!(o -> o.quantity >= tol, market.book_buy)
    filter!(o -> o.quantity >= tol, market.book_sell)
    # remove expired orders
    expired_bids =
        [o for o in market.book_buy if o.time_counter_expire < current_time_counter]
    expired_asks =
        [o for o in market.book_sell if o.time_counter_expire < current_time_counter]
    # mutate the books
    filter!(o -> o.time_counter_expire >= current_time_counter, market.book_buy)
    filter!(o -> o.time_counter_expire >= current_time_counter, market.book_sell)
    # reset agent in-market status
    for o in expired_bids
        o.agent.in_market = false
        (o.agent isa Prosumer) && (o.agent.in_market_as = "")
        # reward should be positive (encourage both actions)
        reward = _grid_sell_to_agent!(grid, o.agent, o.quantity, network, clock)
        push!(
            expired_transactions,
            Rejection(
                price = grid.sell_out_price[current_time_counter],
                time_counter = current_time_counter,
                last_shout = o,
                reward = reward,
            ),
        )
        market.current_demand -= o.quantity
    end
    for o in expired_asks
        o.agent.in_market = false
        (o.agent isa Prosumer) && (o.agent.in_market_as = "")
        # reward should be positive (encourage both actions)
        reward = _grid_buy_from_agent!(grid, o.agent, o.quantity, network, clock)
        push!(
            expired_transactions,
            Rejection(
                price = grid.buy_in_price[current_time_counter],
                time_counter = current_time_counter,
                last_shout = o,
                reward = reward,
            ),
        )
        market.current_supply -= o.quantity
    end
    _update_ratio!(market, clock)
    return expired_transactions
end
