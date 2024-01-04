using Flux, Distributions, LinearAlgebra

function _learn!(
    trader::PPOTrader,
)
    states = trader.buffer.state_memory
    actions = trader.buffer.action_memory
    probs = trader.buffer.probability_memory
    values = trader.buffer.value_memory
    rewards = _get_reward_value.(trader.buffer.reward_memory)
    dones = trader.buffer.terminal_memory
    T = length(rewards)
    # compute the advantage 
    advantages = zeros(T)
    for t = 1:T-1
        β = 1 # discount set to 1
        for k = 1:T-1
            next_value = dones[k] ? trader.γ * values[k+1] : 0
            advantages[t] += β * (rewards[k] + next_value - values[k])
            β *= trader.γ * trader.λ
        end
    end
    returns = advantages + values
    # update the policy (Adam) & re-fit the value function (GD)
    cov_mat = diagm([0.5 for _ in 1:length(actions[1])])
    for _ in 1:trader.epochs
        # calculate losses and optimize actor and critic
        actor_data = Flux.DataLoader((states, actions)) |> gpu
        for (idx, data) in enumerate(actor_data)
            s, a = data
            grads = Flux.gradient(trader.actor_network.model) do m
                dist = MvNormal(m(s[1]), cov_mat)
                new_prob = loglikelihood(dist, a[1])
                ratio = exp(new_prob - probs[idx])
                clipped_ratio = clamp(ratio, 1 - trader.ε, 1 + trader.ε)
                Flux.mean(-advantages[idx] * min(ratio, clipped_ratio))
            end
            Flux.update!(
                trader.actor_network.opt_state, 
                trader.actor_network.model, 
                grads[1]
            )
        end

        critic_data = Flux.DataLoader((states, returns)) |> gpu
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
    
    end
    # clear the memory buffer
    _clear_buffer!(trader.buffer)
end