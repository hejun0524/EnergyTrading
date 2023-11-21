using Flux, DataStructures, JLD2

function _get_trader_networks(
    trader::RLTrader,
)::Vector{Network}
    return [
        trader.actor_network,
        trader.critic_network,
        trader.target_actor_network,
        trader.target_critic_network,
    ]
end

# load models 
function load_models!(
    instance::SimulationInstance;
    filename::String
)
    if !ispath(filename)
        @warn "Cannot find $(filename). Model loading skipped."
        return
    end
    model_states = load_object(filename)
    for agent in instance.agents
        agent_key = "Agent_$(agent.index)"
        for n in _get_trader_networks(agent.trader)
            weights = model_states[agent_key][n.name]
            Flux.loadparams!(n.model, weights)
        end
    end
    @info "All model states have been loaded."
end

# save models 
function save_models(
    instance::SimulationInstance;
    filename::String,
)
    model_states = OrderedDict()
    for agent in instance.agents
        agent_key = "Agent_$(agent.index)"
        model_states[agent_key] = OrderedDict()
        for n in _get_trader_networks(agent.trader)
            weights = collect(Flux.params(cpu(n.model)))
            model_states[agent_key][n.name] = weights
        end
    end
    save_object(filename, model_states)
    @info "All model states have been saved to $(filename)"
end