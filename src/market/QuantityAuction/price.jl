function _compute_sdr_price(market::QuantityCDAMarket, clock::Clock)::Float64
    # unpack values
    r = market.current_ratio
    h = market.max_price[clock.time_counter]
    l = market.min_price[clock.time_counter]
    # clip values
    market.current_demand > 0 || return h
    r < 1.0 || return l
    # get price
    return (1 - r) * h + r * l
end
