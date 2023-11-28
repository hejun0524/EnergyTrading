function _construct_RL_trader(
    market::Market,
    grid::Grid;
    buffer_size::Int = 100,
    batch_size::Int = 20,
)::RLTrader
    n_actions, n_states = _cardinality(market)
    return RLTrader(
        buying_limit_price = grid.sell_out_price,
        selling_limit_price = grid.buy_in_price,
        actor_network = _construct_neural_network(
            "actor", n_states, n_actions, activation = "tanh"
        ),
        critic_network = _construct_neural_network(
            "critic", n_states + n_actions, 1
        ),
        target_actor_network = _construct_neural_network(
            "target_actor", n_states, n_actions, activation = "tanh"
        ),
        target_critic_network = _construct_neural_network(
            "target_critic", n_states + n_actions, 1
        ),
        buffer = _construct_replay_buffer(
            buffer_size, n_states, n_actions
        ),
        batch_size = batch_size,
    )
end

function _cardinality(market::Market)::Tuple{Int, Int}
    (market isa CDAMarket) && return (3, 41)
    (market isa QuantityCDAMarket) && return (2, 33)
    error("The market type is not defined.")
end