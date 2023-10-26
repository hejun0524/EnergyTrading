function _learn(
    trader::RLTrader,
)
    # sample from buffer 
    states, next_states, actions, rewards, dones = sample_from_buffer(
        trader.buffer, trader.batch_size)
    
    # compute targets for the Q functions 

    # update Q functions

    # update policy 

    # update target network
    
end