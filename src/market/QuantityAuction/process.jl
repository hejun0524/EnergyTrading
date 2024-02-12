function _match_and_process_orders!(
    market::QuantityCDAMarket,
    network::NetworkInstance,
    grid::Grid,
    clock::Clock,
)::Transaction
    best_ask, ask_index = _get_best_order(market.book_sell)
    best_bid, bid_index = _get_best_order(market.book_buy)

    if !(best_ask === nothing || best_bid === nothing)
        last_shout =
            best_bid.time_counter_submit >= best_ask.time_counter_submit ? best_bid :
            best_ask
        if best_bid.price >= best_ask.price
            cleared_quantity = min(best_bid.quantity, best_ask.quantity)
            cleared_price = (best_bid.price + best_ask.price) / 2
            from_agent_cleared = best_ask.quantity == cleared_quantity
            to_agent_cleared = best_bid.quantity == cleared_quantity
            # generate deal 
            deal = Deal(
                from_agent = best_ask.agent,
                from_agent_cleared = from_agent_cleared,
                to_agent = best_bid.agent,
                to_agent_cleared = to_agent_cleared,
                price = cleared_price,
                quantity = cleared_quantity,
                time_counter = clock.time_counter,
                last_shout = last_shout,
            )
            # validate deal 
            _validate_transaction_and_update_network!(deal, network, grid, clock)
            # alter market data
            if deal.is_valid
                # sell power from storage 
                _sell_power_from_storage!(best_ask.agent.storage, cleared_quantity)
                # update order quantity
                # from agent will be free immediately
                if from_agent_cleared
                    best_ask.agent.in_market = false
                    best_ask.agent.next_free_time = clock.time_counter + 1
                    (best_ask.agent isa Prosumer) && (best_ask.agent.in_market_as = "")
                    splice!(market.book_sell, ask_index)
                else
                    best_ask.quantity -= cleared_quantity
                    best_ask.priority = -999
                end
                # to agent will be subject to flexible demand time length
                if to_agent_cleared
                    best_bid.agent.in_market = false
                    (best_bid.agent isa Prosumer) && (best_bid.agent.in_market_as = "")
                    splice!(market.book_buy, bid_index)
                else
                    best_bid.quantity -= cleared_quantity
                    best_bid.priority = -999
                end
                deal.reward =
                    cleared_price * cleared_quantity - deal.utilization_charge -
                    deal.loss_charge
                # update market
                market.current_demand -= cleared_quantity
                market.current_supply -= cleared_quantity
                _update_ratio!(market, clock)
            else
                # mark skip flag for whichever comes second 
                last_shout.skip = true
            end
            _add_deal_snapshot_to_agents!(deal, clock)
            return deal
        else
            return Rejection(
                price = last_shout.price,
                time_counter = clock.time_counter,
                last_shout = last_shout,
            )
        end
    end
    return Waiting(time_counter = clock.time_counter)
end

function _proportionally_clear_orders!(
    market::QuantityCDAMarket,
    network::NetworkInstance,
    grid::Grid,
    clock::Clock;
    ε::Float64 = 1e-3,
)::Vector{Transaction}
    if length(market.book_buy) > 0 && length(market.book_sell) > 0
        transactions = []
        bids_to_splice = []
        asks_to_splice = []
        r = min(market.current_ratio, 1.0)
        ask_ratios = Dict(ask => ask.quantity / market.current_supply for ask in market.book_sell)
        cleared_price = market.current_price

        for (bid_index, bid) in enumerate(market.book_buy)
            for (ask_index, ask) in enumerate(market.book_sell)
                last_shout = bid.time_counter_submit >= ask.time_counter_submit ? bid : ask
                cleared_quantity = bid.quantity * r * ask_ratios[ask]
                from_agent_cleared = abs(ask.quantity - cleared_quantity) < ε
                to_agent_cleared = abs(bid.quantity - cleared_quantity) < ε
                # generate proportional deal 
                deal = Deal(
                    from_agent = ask.agent,
                    from_agent_cleared = from_agent_cleared,
                    to_agent = bid.agent,
                    to_agent_cleared = to_agent_cleared,
                    price = cleared_price,
                    quantity = cleared_quantity,
                    time_counter = clock.time_counter,
                    last_shout = last_shout,
                )
                # validate deal 
                _validate_transaction_and_update_network!(deal, network, grid, clock)
                # alter market data
                if deal.is_valid
                    # sell power from storage 
                    _sell_power_from_storage!(ask.agent.storage, cleared_quantity)
                    # update order quantity
                    # from agent will be free immediately
                    if from_agent_cleared
                        ask.agent.in_market = false
                        ask.agent.next_free_time = clock.time_counter + 1
                        (ask.agent isa Prosumer) && (ask.agent.in_market_as = "")
                        # splice!(market.book_sell, ask_index)
                        ask.quantity = 0.0
                        push!(asks_to_splice, ask_index)
                    else
                        ask.quantity -= cleared_quantity
                        ask.priority = -999
                    end
                    # to agent will be subject to flexible demand time length
                    if to_agent_cleared
                        bid.agent.in_market = false
                        (bid.agent isa Prosumer) && (bid.agent.in_market_as = "")
                        # splice!(market.book_buy, bid_index)
                        bid.quantity = 0.0
                        push!(bids_to_splice, bid_index)
                    else
                        bid.quantity -= cleared_quantity
                        bid.priority = -999
                    end
                    deal.reward =
                        cleared_price * cleared_quantity - deal.utilization_charge -
                        deal.loss_charge
                    # update market
                    market.current_demand -= cleared_quantity
                    market.current_supply -= cleared_quantity
                    _update_ratio!(market, clock)
                else 
                    # mark skip flag for whichever comes second 
                    last_shout.skip = true
                end
                _add_deal_snapshot_to_agents!(deal, clock)
                push!(transactions, deal)
            end
        end
        return transactions
    end
    return [Waiting(time_counter = clock.time_counter)]
end
