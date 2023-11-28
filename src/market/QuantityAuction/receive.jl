function _receive_and_sort_order_books!(
    market::QuantityCDAMarket,
    orders::Vector{Order},
    clock::Clock,
)
    if length(orders) > 0
        for order in orders
            if order.order_type == "bid"
                push!(market.book_buy, order)
                order.agent.in_market = true 
                (order.agent isa Prosumer) && (order.agent.in_market_as = "buyer")
                market.most_recent_order = order
                market.current_demand += order.quantity
            elseif order.order_type == "ask"
                push!(market.book_sell, order)
                order.agent.in_market = true
                (order.agent isa Prosumer) && (order.agent.in_market_as = "seller")
                market.most_recent_order = order
                market.current_supply += order.quantity
            else
                error("The order has an invalid order type.")
            end
        end
    end
    _update_ratio!(market, clock)
    for o in orders 
        o.price = market.current_price
        o.agent.trader.current_price = market.current_price
    end
    sort!(market.book_buy, 
        by = o -> (o.priority, -o.price, o.time_counter_submit))
    sort!(market.book_sell, 
        by = o -> (o.priority, o.price, o.time_counter_submit))
end