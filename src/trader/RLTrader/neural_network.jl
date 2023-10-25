using Flux 

# construct split neural network, pre-definition
struct Split{T}
    paths::T
end

Split(paths...) = Split(paths)

Flux.@functor Split

(m::Split)(x::AbstractArray) = map(f -> f(x), m.paths)

# store model and opt state in a struct 
struct Network 
    model
    opt_state
end

# construct basic neural network
function _construct_basic_neural_network(;
    in_dim::Int, 
    out_dim::Int,
)::Network
    # specify the model
    model = Chain(
        Dense(in_dim => 64, relu), 
        Dense(64 => 64, relu), 
        Dense(64 => out_dim)
    ) |> gpu 

    opt_state = Flux.setup(Adam(), model)

    return Network(model, opt_state)
end

# construct multiple out layer nn 
function _construct_split_neural_network(;
    in_dim::Int, 
    out_dim::Int,
)::Network
    # specify the model
    model = Chain(
        Dense(in_dim => 64, relu), 
        Dense(64 => 64, relu), 
        Split(
            Dense(64 => out_dim), # μ
            Dense(64 => out_dim), # σ
        ),
    ) |> gpu 

    opt_state = Flux.setup(Adam(), model)

    return Network(model, opt_state)
end

# set up trader neural network
function _set_up_trader!(
    agent::Agent,
)
    agent.trader isa RLTrader || error("Trader must be a RL trader!")
    N_ACTIONS = 4
    N_STATES = 14
    agent.trader.actor_network = _construct_split_neural_network(
        in_dim = N_STATES, out_dim = N_ACTIONS
    )
    agent.trader.critic_network = _construct_basic_neural_network(
        in_dim = N_STATES + N_ACTIONS, out_dim = 1
    )
    agent.trader.auxiliary_critic_network = _construct_basic_neural_network(
        in_dim = N_STATES + N_ACTIONS, out_dim = 1
    )
    agent.trader.value_network = _construct_basic_neural_network(
        in_dim = N_STATES, out_dim = 1
    )
    agent.trader.target_value_network = _construct_basic_neural_network(
        in_dim = N_STATES, out_dim = 1
    )
    agent.trader.buffer = _construct_replay_buffer(
        100, N_STATES, N_ACTIONS
    )
end