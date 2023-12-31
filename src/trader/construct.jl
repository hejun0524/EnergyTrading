function _construct_trader(
    trader_type::String,
    market::Market,
    grid::Grid,
)::Trader
    if trader_type == "DDPG trader"
        return _construct_DDPG_trader(market, grid)
    elseif trader_type == "PPO trader"
        return _construct_PPO_trader(market, grid)
    elseif trader_type == "ZIP trader"
        # return _construct_RL_trader(grid)
    end
    error("The trader type $(trader_type) is not supported.")
end