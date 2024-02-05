function _match_and_process_orders!(
    market::CDAMarket,
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

function _get_best_order(book::Vector{Order})::Tuple{Union{Order,Nothing},Int}
    n = length(book)
    for i = 1:n
        book[i].skip || return (book[i], i)
    end
    return (nothing, 0)
end

function _remove_skip_flags!(market::Union{CDAMarket,QuantityCDAMarket})
    for order in market.book_sell
        order.skip = false
    end
    for order in market.book_buy
        order.skip = false
    end
end
