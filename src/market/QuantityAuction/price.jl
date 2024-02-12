function _compute_sdr_price(market::QuantityCDAMarket, clock::Clock)::Float64
    # unpack values
    r = market.current_ratio
    h = market.max_price[clock.time_counter] # 15
    l = market.min_price[clock.time_counter] # 2
    # clip values
    market.current_supply > 0 || return h # no supply gives 15
    market.current_demand > 0 || return l # no demand gives 2
    r < 1.0 || return l # too much supply
    # get price
    return (1 - r) * h + r * l
end
