using Flux, JLD2

# get file name 
function _model_state_name(
    dir, agent, network
)::String
    return "$(dir)/agent_$(agent.index)_$(network.name).jld2"
end

# load models 
function load_models!(
    instance::SimulationInstance;
    dir::String = ".",
    ignore_nonexisiting::Bool = false,
)
    for agent in instance.agents
        networks = [
            agent.trader.actor_network,
            agent.trader.critic_network,
            agent.trader.target_actor_network,
            agent.trader.target_critic_network,
        ]
        for n in networks
            jld2fname = _model_state_name(dir, agent, n)
            if !ispath(jld2fname)
                ignore_nonexisiting || error("File does not exist.")
            else
                model_state = JLD2.load(jld2fname, "model_state")
                Flux.loadmodel!(n.model, model_state)
            end            
        end
    end
end

# save models 
function save_models(
    instance::SimulationInstance;
    dir::String = ".",
)
    isdir(dir) || mkdir(dir)
    for agent in instance.agents
        networks = [
            agent.trader.actor_network,
            agent.trader.critic_network,
            agent.trader.target_actor_network,
            agent.trader.target_critic_network,
        ]
        for n in networks
            jld2fname = _model_state_name(dir, agent, n)
            model_state = Flux.state(n.model);
            jldsave(jld2fname; model_state)
        end
    end
end