using Random

function simulate!(instance::SimulationInstance, method::RLSimulation)
    Random.seed!(method.random_seed)
    @info "Running RL simulation instance..."
    if method.evaluate
        @info "Evaluating model..."
        time_eval = @elapsed begin
            _run_episode!(instance, method.evaluate)
        end
        @info "Evaluation done in $(round(time_eval, digits=2))s"
    else
        for episode = 1:method.episodes
            @info "Training episode $(episode)/$(method.episodes)"
            println("Training episode $(episode)/$(method.episodes)")
            time_episode = @elapsed begin
                _run_episode!(instance, method.evaluate)
            end
            @info "Episode $(episode) done in $(round(time_episode, digits=2))s"
        end
    end
end
