function _receive_and_sort_order_books!(
    market::CDAMarket,
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
            elseif order.order_type == "ask"
                push!(market.book_sell, order)
                order.agent.in_market = true
                (order.agent isa Prosumer) && (order.agent.in_market_as = "seller")
                market.most_recent_order = order
            else
                error("The order has an invalid order type.")
            end
        end
    end
    sort!(market.book_buy, by = o -> (o.priority, -o.price, o.time_counter_submit))
    sort!(market.book_sell, by = o -> (o.priority, o.price, o.time_counter_submit))
end
