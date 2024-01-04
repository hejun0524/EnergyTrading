using Shuffle

# construct the replay buffer 
function _construct_PPO_memory(
    n_states::Int,
    n_actions::Int
)::PPOMemory
    return PPOMemory(
        n_states = n_states,
        n_actions = n_actions,
    )
end

# store new memory to replay buffer 
function _store_new_memory!(
    buffer::PPOMemory;
    state::Vector{Float64},
    probability::Float64 = 0.0,
    value::Float64 = 0.0,
    action::Vector{Float64},
    reward::Reward,
    done::Bool = false,
)
    push!(buffer.state_memory, state)
    push!(buffer.probability_memory, probability)
    push!(buffer.value_memory, value)
    push!(buffer.action_memory, action)
    push!(buffer.reward_memory, reward)
    push!(buffer.terminal_memory, done)
end

# modify memory in replay buffer 
function _modify_memory!(
    buffer::PPOMemory;
    state::Union{Vector{Float64}, Nothing} = nothing,
    action::Union{Vector{Float64}, Nothing} = nothing,
    probability::Union{Float64, Nothing} = nothing,
    value::Union{Float64, Nothing} = nothing,
    reward::Union{Float64, Nothing} = nothing,
    reward_replace::Bool = false,
    done::Union{Bool, Nothing} = nothing,
)
    # store the memory 
    if state !== nothing
        buffer.state_memory[end] = state 
    end
    if action !== nothing
        buffer.action_memory[end] = action
    end
    if probability !== nothing
        buffer.probability_memory[end] = probability
    end
    if value !== nothing
        buffer.value_memory[end] = value
    end
    if reward !== nothing
        _accumulate_raw_reward!(
            buffer.reward_memory[end],
            reward,
            replace = reward_replace,
        )
    end
    if done !== nothing 
        buffer.terminal_memory[end] = done
    end
end

function _clear_buffer!(
    buffer::PPOMemory
)
    buffer.state_memory = []
    buffer.probability_memory = []
    buffer.value_memory = []
    buffer.action_memory = []
    buffer.reward_memory = []
    buffer.terminal_memory = []
end