function _construct_DDPG_trader(
    market::Market,
    grid::Grid;
    buffer_size::Int = 400,
    batch_size::Int = 20,
)::DDPGTrader
    n_actions, n_states = _cardinality(market)
    return DDPGTrader(
        buying_limit_price = grid.sell_out_price,
        selling_limit_price = grid.buy_in_price,
        actor_network = _construct_neural_network(
            "actor", n_states, n_actions, activation = "softmax"
        ),
        critic_network = _construct_neural_network(
            "critic", n_states + n_actions, 1
        ),
        target_actor_network = _construct_neural_network(
            "target_actor", n_states, n_actions, activation = "softmax"
        ),
        target_critic_network = _construct_neural_network(
            "target_critic", n_states + n_actions, 1
        ),
        buffer = _construct_DDPG_memory(
            buffer_size, n_states, n_actions
        ),
        batch_size = batch_size,
    )
end