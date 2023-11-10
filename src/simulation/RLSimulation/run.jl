using Random 

function simulate!(
    instance::SimulationInstance,
    method::RLSimulation,
)
    Random.seed!(method.random_seed)
    @info "Running RL simulation instance..."
    for episode in 1:method.episodes
        @info "Training episode $(episode)/$(method.episodes)"
        time_episode = @elapsed begin
            _run_episode!(instance)
        end
        @info "Episode $(episode) done in $(round(time_episode, digits=2))s"
    end
end