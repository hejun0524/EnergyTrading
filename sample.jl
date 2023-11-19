include("src/EnergyTrading.jl")
using .EnergyTrading 

fpath = "./sample.json"
instance = EnergyTrading.read(fpath)
EnergyTrading.load_models!(instance, dir = "./saved_states", ignore_nonexisiting=true)
EnergyTrading.simulate!(instance, EnergyTrading.RLSimulation(evaluate=false))
EnergyTrading.save_models(instance, dir = "./saved_states")

solution = EnergyTrading.solution(instance)
EnergyTrading.write("output.json", solution)