include("src/EnergyTrading.jl")
using .EnergyTrading 

fpath = "./sample.json"

CONTINUE_TRAINING = false 

# training
@info "Training starts"
instance = EnergyTrading.read(fpath)
if CONTINUE_TRAINING
    EnergyTrading.load_models!(instance, filename="saved_states.jld2")
end
EnergyTrading.simulate!(instance, EnergyTrading.RLSimulation(evaluate=false))
EnergyTrading.save_models(instance, filename="saved_states.jld2")