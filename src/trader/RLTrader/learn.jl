using Flux 

function _learn!(
    trader::RLTrader,
)
    # make sure sufficient samples are available
    trader.buffer.memory_counter >= trader.batch_size || return
    # sample from buffer 
    states, next_states, actions, rewards, dones = sample_from_buffer(
        trader.buffer, trader.batch_size)
    
    # get data for critic
    critic_inputs = [] # array of arrays
    critic_labels = []
    for i = 1:trader.batch_size
        target_actions = trader.target_actor_network.model(next_states[i])
        next_critic_value = trader.target_critic_network.model([next_states[i]; target_actions])
        target = rewards[i] + trader.γ * (1 - dones[i]) * sum(next_critic_value)
        push!(critic_inputs, [states[i]; actions[i]])
        push!(critic_labels, target)
    end
    # optimize critic
    # critic_loss(x, y) = sum(Flux.mse(trader.critic_network.model(x...), y))
    critic_data = Flux.DataLoader((critic_inputs, critic_labels))
    # critic_ps = Flux.params(trader.critic_network.model)
    # Flux.train!(critic_loss, critic_ps, critic_data, trader.critic_network.opt_state)
    for data in critic_data
        input, label = data
        grads = Flux.gradient(trader.critic_network.model) do m
            result = m(input[1])
            Flux.mse(result, label)
        end
        Flux.update!(
            trader.critic_network.opt_state, 
            trader.critic_network.model, 
            grads[1]
        )
    end

    # get data for actor
    actor_inputs = []
    for i = 1:trader.batch_size
        push!(actor_inputs, states[i])
    end
    # optimize actor
    actor_loss(x) = sum(Flux.mean(
        -trader.critic_network.model(x..., trader.actor_network.model(x...))))
    actor_data = Flux.DataLoader(actor_inputs)
    # actor_ps = Flux.params(trader.actor_network.model)
    # Flux.train!(actor_loss, actor_ps, actor_data, trader.actor_network.opt_state)
    for input in actor_data
        grads = Flux.gradient(trader.actor_network.model) do m
            result = m(input[1])
            Flux.mean(-trader.critic_network.model([input[1]; result]))
        end
        Flux.update!(
            trader.actor_network.opt_state, 
            trader.actor_network.model, 
            grads[1]
        )
    end

    # update target network parameters
    ps_critic = Flux.params(trader.critic_network.model)
    ps_target_critic = Flux.params(trader.target_critic_network.model)
    for (k, p) in enumerate(ps_target_critic)
        p .= trader.τ * p + (1 - trader.τ) * ps_critic[k]
    end

    ps_actor = Flux.params(trader.actor_network.model)
    ps_target_actor = Flux.params(trader.target_actor_network.model)
    for (k, p) in enumerate(ps_target_actor)
        p .= trader.τ * p + (1 - trader.τ) * ps_actor[k]
    end
end