function _update_market_history!(
    market::QuantityCDAMarket,
    clock::Clock;
    deals::Vector{Deal} = Deal[]
)
    t = _get_time_counter_of_day(clock)
    market.price_history[t] = market.current_price
    market.supply_history[t] = market.current_supply
    market.demand_history[t] = market.current_demand
    market.ratio_history[t] = market.current_ratio
end

function _update_ratio!(
    market::QuantityCDAMarket,
    clock::Clock,
)
    s = market.current_supply
    d = market.current_demand
    if s == 0.0
        market.current_ratio = 0.0
    elseif d == 0.0
        market.current_ratio = 10.0 # set to a big number 
    else
        market.current_ratio = s / d 
    end
    market.current_price = _compute_sdr_price(market, clock)
end