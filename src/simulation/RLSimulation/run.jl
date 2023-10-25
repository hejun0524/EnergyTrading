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

            # market remove old orders

            while _get_time_counter_from_continuous_time(
                    instance.clock, arrival_time) < instance.clock.time_counter
                # get next sample
                arrival_time += instance.market.arrival === nothing ? 1.0 : rand(instance.market.arrival)
                # choose an agent
                selected_agent = _random_enter_market(instance.agents, instance.clock.time_counter)
                # let agent submit the order 
            end

            # market match and process order 
        end
    end
end