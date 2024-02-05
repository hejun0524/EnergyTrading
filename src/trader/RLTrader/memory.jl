function _store_memory_interface!(buffer::ReplayBuffer; arguments::Dict)
    if buffer isa DDPGMemory
        _store_new_memory!(
            buffer,
            state = arguments[:state],
            action = arguments[:action],
            reward = arguments[:reward],
            next_state = get(arguments, :next_state, Float64[]),
            done = get(arguments, :next_state, false),
        )
    elseif buffer isa PPOMemory
        _store_new_memory!(
            buffer,
            state = arguments[:state],
            probability = get(arguments, :probability, 0.0),
            value = get(arguments, :value, 0.0),
            action = arguments[:action],
            reward = arguments[:reward],
            done = get(arguments, :done, false),
        )
    else
        error("Replay buffer type is not supported.")
    end
end

function _modify_memory_interface!(buffer::ReplayBuffer; arguments::Dict)
    if buffer isa DDPGMemory
        _modify_memory!(
            buffer,
            buffer.memory_counter,
            state = get(arguments, :state, nothing),
            action = get(arguments, :action, nothing),
            reward = get(arguments, :reward, nothing),
            reward_replace = get(arguments, :reward_replace, false),
            next_state = get(arguments, :next_state, nothing),
            done = get(arguments, :done, nothing),
        )
    elseif buffer isa PPOMemory
        _modify_memory!(
            buffer,
            state = get(arguments, :state, nothing),
            action = get(arguments, :action, nothing),
            probability = get(arguments, :probability, nothing),
            value = get(arguments, :value, nothing),
            reward = get(arguments, :reward, nothing),
            reward_replace = get(arguments, :reward_replace, false),
            done = get(arguments, :done, nothing),
        )
    else
        error("Replay buffer type is not supported.")
    end
end
