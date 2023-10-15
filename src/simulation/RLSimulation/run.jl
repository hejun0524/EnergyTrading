using Random 

function simulate!(
    instance::SimulationInstance,
    method::RLSimulation;
    callback = nothing,
    verbose = false,
)
    Random.seed!(method.random_seed)
    @info "Running RL simulation instance..."
    # initiate arrival time 
    arrival = 0.0
    # clock must be discrete to sync with system
    while !_is_over(instance.clock)
        # proceed the time at the beginning
        _proceed_time!(instance.clock)

        while _get_time_counter_from_continuous_time(
                instance.clock, arrival) <= instance.clock.time_counter
            arrival = 0.0 # next sample
        end
        
        # if there is a callback specified by the user
        if callback !== nothing 
            callback(instance)
        end
    end
end