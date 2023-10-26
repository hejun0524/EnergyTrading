function _append_current_trader_price!(
    trader::RLTrader, 
)
    push!(trader.price_history, trader.current_price)
end