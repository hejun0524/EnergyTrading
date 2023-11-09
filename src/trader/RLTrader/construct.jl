function _construct_RL_trader(
    grid::Grid;
    n_actions::Int = 3,
    n_states::Int = 41,
    buffer_size::Int = 100,
    batch_size::Int = 50,
)::RLTrader
    return RLTrader(
        buying_limit_price = grid.sell_out_price,
        selling_limit_price = grid.buy_in_price,
        actor_network = _construct_neural_network(
            n_states, n_actions, activation = "tanh"
        ),
        critic_network = _construct_neural_network(
            n_states + n_actions, 1
        ),
        target_actor_network = _construct_neural_network(
            n_states, n_actions, activation = "tanh"
        ),
        target_critic_network = _construct_neural_network(
            n_states + n_actions, 1
        ),
        buffer = _construct_replay_buffer(
            buffer_size, n_states, n_actions
        ),
        batch_size = batch_size,
    )
end