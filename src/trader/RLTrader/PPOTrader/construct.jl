function _construct_PPO_trader(
    market::Market,
    grid::Grid;
    reward_type::String = "conventional",
    batch_size::Int = 20,
)::PPOTrader
    n_actions, n_states = _cardinality(market)
    return PPOTrader(
        buying_limit_price = grid.sell_out_price,
        selling_limit_price = grid.buy_in_price,
        reward_type = reward_type,
        actor_network = _construct_neural_network("actor", n_states, n_actions),
        critic_network = _construct_neural_network("critic", n_states, 1),
        buffer = _construct_PPO_memory(n_states, n_actions),
        batch_size = batch_size,
        ε = 0.02,
    )
end
