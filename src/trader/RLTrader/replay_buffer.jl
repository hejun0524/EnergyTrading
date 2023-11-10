# define the replay buffer struct
Base.@kwdef mutable struct ReplayBuffer
    max_memory_size::Int 
    n_states::Int
    n_actions::Int
    memory_counter::Int
    state_memory::Vector{Any} = []
    next_state_memory::Vector{Any} = []
    action_memory::Vector{Any} = []
    reward_memory::Vector{Float64} = []
    terminal_memory::Vector{Bool} = []
end

# construct the replay buffer 
function _construct_replay_buffer(
    max_memory_size::Int,
    n_states::Int,
    n_actions::Int
)::ReplayBuffer
    return ReplayBuffer(
        max_memory_size = max_memory_size,
        n_states = n_states,
        n_actions = n_actions,
        memory_counter = 0,
    )
end

function _get_memory_index(
    target_counter::Int, 
    max_size::Int, 
)::Int 
    idx = target_counter % max_size
    if idx == 0 && target_counter > 0
        return max_size
    end
    return idx
end

# store new memory to replay buffer 
function _store_new_memory!(
    buffer::ReplayBuffer;
    state::Vector{Float64},
    action::Vector{Float64},
    reward::Float64 = 0.0,
    next_state::Vector{Float64} = Float64[],
    done::Bool = false,
)
    # increase the counter by 1
    buffer.memory_counter += 1   
    # store the memory 
    if buffer.memory_counter <= buffer.max_memory_size
        push!(buffer.state_memory, state)
        push!(buffer.action_memory, action)
        push!(buffer.reward_memory, reward)
        push!(buffer.next_state_memory, next_state)
        push!(buffer.terminal_memory, done)
    else
        idx = _get_memory_index(buffer.memory_counter, buffer.max_memory_size)
        buffer.state_memory[idx] = state 
        buffer.action_memory[idx] = action
        buffer.reward_memory[idx] = reward
        buffer.next_state_memory[idx] = next_state
        buffer.terminal_memory[idx] = done
    end 
end

# modify memory in replay buffer 
function _modify_memory!(
    buffer::ReplayBuffer,
    target_memory_counter::Int;
    state::Union{Vector{Float64}, Nothing} = nothing,
    action::Union{Vector{Float64}, Nothing} = nothing,
    reward::Union{Float64, Nothing} = nothing,
    reward_discount::Float64 = 1.0,
    next_state::Union{Vector{Float64}, Nothing} = nothing,
    done::Union{Bool, Nothing} = nothing,
)
    # get the buffer index 
    idx = _get_memory_index(target_memory_counter, buffer.max_memory_size)
    # store the memory 
    if state !== nothing
        buffer.state_memory[idx] = state 
    end
    if action !== nothing
        buffer.action_memory[idx] = action
    end
    if reward !== nothing
        # reward_discount = 1.0 for cumulating
        # reward_discount = 0.0 for replacing
        prev_reward = buffer.reward_memory[idx] * reward_discount
        buffer.reward_memory[idx] = prev_reward + reward
    end
    if next_state !== nothing 
        buffer.next_state_memory[idx] = next_state
    end
    if done !== nothing 
        buffer.terminal_memory[idx] = done
    end
end

# sample the memory buffer
function sample_from_buffer(
    buffer::ReplayBuffer,
    batch_size::Int,
)
    # do not sample initialized 
    max_sample_size = min(buffer.memory_counter, buffer.max_memory_size)
    batch = rand(1:max_sample_size, batch_size)
    # get samples 
    states = buffer.state_memory[batch]
    next_states = buffer.next_state_memory[batch]
    actions = buffer.action_memory[batch]
    rewards = buffer.reward_memory[batch]
    dones = buffer.terminal_memory[batch]
    return states, next_states, actions, rewards, dones
end