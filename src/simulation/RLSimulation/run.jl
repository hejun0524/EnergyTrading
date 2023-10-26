using Random 

function simulate!(
    instance::SimulationInstance,
    method::RLSimulation,
)
    Random.seed!(method.random_seed)
    @info "Running RL simulation instance..."
    for episode in 1:method.episodes
        @info "Training episode $(episode)/$(method.episodes)"
        # initiate arrival time 
        arrival_time = 0.0
        # clock must be discrete to sync with system
        while !_is_over(instance.clock)
            # proceed the time at the beginning
            _proceed_time!(instance.clock)

            # market remove old orders, some agents receive reward

            # learning 

            # select agents
            selected_agents = []
            while _get_time_counter_from_continuous_time(
                    instance.clock, arrival_time) < instance.clock.time_counter
                # get next sample
                arrival_time += instance.market.arrival === nothing ? 1.0 : rand(instance.market.arrival)
                # choose an agent
                selected_agent = _random_enter_market(instance.agents, instance.clock.time_counter)
                push!(selected_agents, selected_agent)
            end

            # all agents not selected prosume 

            # generate agent decision 

            # market receive and sort orders 

            # market match and process order, some agents receive reward

            # reset flow to prevent carry over
            for line in instance.network.lines
                _reset_line_flow!(line)
            end

            # finally snapshot all traders' current price & storage
            for agent in instance.agents    
                _append_current_trader_price!(agent.trader)
            end
        end
    end
end