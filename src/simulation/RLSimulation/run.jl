using Random 

function simulate!(
    instance::SimulationInstance,
    method::RLSimulation;
    callback = nothing,
    verbose = false,
)
    Random.seed!(method.random_seed)
    @info "Running P2P simulation instance..."
    while !_is_over(instance.clock)
        # proceed the time at the beginning
        _proceed_time!(instance.clock)
        
        # if there is a callback specified by the user
        if callback !== nothing 
            callback(instance)
        end
    end
end