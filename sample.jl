include("src/EnergyTrading.jl")
using .EnergyTrading 

fpath = "./sample.json"
instance = EnergyTrading.read(fpath);
EnergyTrading.simulate!(instance, EnergyTrading.RLSimulation())
