function _construct_trader(
    trader_type::String,
    grid::Grid,
)::Trader
    if trader_type == "RL trader"
        return _construct_RL_trader(grid)
    elseif trader_type == "ZIP trader"
        # return _construct_RL_trader(grid)
    end
    error("The trader type $(trader_type) is not supported.")
end