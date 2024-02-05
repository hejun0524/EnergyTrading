function _update_market_history!(
    market::CDAMarket,
    clock::Clock;
    deals::Vector{Deal} = Deal[],
)
    n_deals = length(deals)
    n_deals > 0 || return
    prices = [d.price for d in deals]
    quantities = [d.quantity for d in deals]
    total_profit = prices' * quantities
    total_quantity = sum(quantities)
    t = _get_time_counter_of_day(clock)
    market.price_history[t] = total_profit / total_quantity
    market.quantity_history[t] = total_quantity / n_deals
end
