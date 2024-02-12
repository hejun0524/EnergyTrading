function _receive_and_sort_order_books!(
    market::QuantityCDAMarket,
    orders::Vector{Order},
    clock::Clock,
)
    length(orders) > 0 || return
    for order in orders
        _receive_order!(market, order, clock)
    end
    for order in orders
        _fix_price!(market, order)
    end
    _sort_order_books!(market)
end

function _receive_order!(
    market::QuantityCDAMarket,
    order::Order,
    clock::Clock,
)
    if order.order_type == "bid"
        push!(market.book_buy, order)
        order.agent.in_market = true
        (order.agent isa Prosumer) && (order.agent.in_market_as = "buyer")
        market.most_recent_order = order
        market.current_demand += order.quantity
        market.current_demand -= order.agent.current_basic_demand
    elseif order.order_type == "ask"
        push!(market.book_sell, order)
        order.agent.in_market = true
        (order.agent isa Prosumer) && (order.agent.in_market_as = "seller")
        market.most_recent_order = order
        market.current_supply += order.quantity
        market.current_demand -= order.agent.current_basic_demand
    else
        error("The order has an invalid order type.")
    end
    _update_ratio!(market, clock)
end

function _sort_order_books!(
    market::QuantityCDAMarket,
)
    sort!(market.book_buy, by = o -> (o.priority, -o.price, o.time_counter_submit))
    sort!(market.book_sell, by = o -> (o.priority, o.price, o.time_counter_submit))
end

function _fix_price!(
    market::QuantityCDAMarket,
    order::Order,
)
    order.price = market.current_price
    order.agent.trader.current_price = market.current_price
end