function _construct_PPO_trader(
    market::Market,
    grid::Grid;
    buffer_size::Int = 400,
    batch_size::Int = 20,
)::PPOTrader
    n_actions, n_states = _cardinality(market)
    return PPOTrader(
        buying_limit_price = grid.sell_out_price,
        selling_limit_price = grid.buy_in_price,
        actor_network = _construct_neural_network(
            "actor", n_states, n_actions, activation = "softmax"
        ),
        critic_network = _construct_neural_network(
            "critic", n_states, 1
        ),
        buffer = _construct_PPO_memory(
            n_states, n_actions
        ),
        batch_size = batch_size,
    )
end