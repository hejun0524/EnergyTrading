include("src/EnergyTrading.jl")
using .EnergyTrading 

fpath = "./sample.json"

# testing
@info "Testing starts"
instance = EnergyTrading.read(fpath)
EnergyTrading.load_models!(instance, filename="saved_states.jld2")
EnergyTrading.simulate!(instance, EnergyTrading.RLSimulation(evaluate=true))
# get test results and write to output.json
solution = EnergyTrading.solution(instance)
EnergyTrading.write("output.json", solution)