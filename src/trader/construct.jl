function _construct_trader(
    trader_type::String
)::Trader
    if trader_type == "RL trader"
        return _construct_RL_trader()
    elseif trader_type == "ZIP trader"
        # return _construct_RL_trader()
    end
    error("The trader type $(trader_type) is not supported.")
end