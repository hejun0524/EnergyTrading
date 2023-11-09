# define the replay buffer struct
Base.@kwdef mutable struct ReplayBuffer
    max_memory_size::Int 
    n_states::Int
    n_actions::Int
    memory_counter::Int
    state_memory::Vector{Any}
    next_state_memory::Vector{Any}
    action_memory::Vector{Any}
    reward_memory::Vector{Float64}
    terminal_memory::Vector{Bool}
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
        state_memory = [zeros(n_states) for _ in 1:max_memory_size],
        next_state_memory = [zeros(n_states) for _ in 1:max_memory_size],
        action_memory = [zeros(n_actions) for _ in 1:max_memory_size],
        reward_memory = [0.0 for _ in 1:max_memory_size],
        terminal_memory = [false for _ in 1:max_memory_size]
    )
end

# store new memory to replay buffer 
function _store_new_memory!(
    buffer::ReplayBuffer;
    state::Vector{Any},
    action::Vector{Any},
    reward::Float64 = 0.0,
    next_state::Vector{Any} = [],
    done::Bool = false,
)
    # get the buffer index 
    idx = (buffer.memory_counter % buffer.max_memory_size) + 1
    # store the memory 
    buffer.state_memory[idx] = state 
    buffer.action_memory[idx] = action
    buffer.reward_memory[idx] = reward
    buffer.next_state_memory[idx] = next_state
    buffer.terminal_memory[idx] = done
    # increase the counter by 1
    buffer.memory_counter += 1    
end

# modify memory in replay buffer 
function _modify_memory!(
    buffer::ReplayBuffer,
    target_memory_counter::Int;
    state::Union{Vector{Any}, Nothing} = nothing,
    action::Union{Vector{Any}, Nothing} = nothing,
    reward::Union{Float64, Nothing} = nothing,
    reward_discount::Float64 = 1.0,
    next_state::Union{Vector{Any}, Nothing} = nothing,
    done::Union{Bool, Nothing} = nothing,
)
    # get the buffer index 
    idx = (target_memory_counter % buffer.max_memory_size) + 1
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