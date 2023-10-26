function _construct_RL_trader(;
    n_actions = 5,
    n_states = 14,
)::RLTrader
    return RLTrader(
        buying_limit_price = [],
        selling_limit_price = [],
        actor_network = _construct_split_neural_network(
            in_dim = n_states, out_dim = n_actions
        ),
        critic_network = _construct_basic_neural_network(
            in_dim = n_states + n_actions, out_dim = 1
        ),
        auxiliary_critic_network = _construct_basic_neural_network(
            in_dim = n_states + n_actions, out_dim = 1
        ),
        value_network = _construct_basic_neural_network(
            in_dim = n_states, out_dim = 1
        ),
        target_value_network = _construct_basic_neural_network(
            in_dim = n_states, out_dim = 1
        ),
        buffer = _construct_replay_buffer(
            100, n_states, n_actions
        ),
        batch_size = 50,
    )
end