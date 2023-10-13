Base.@kwdef mutable struct SimulationInstance
    clock::Clock
    grid::Grid
    network::NetworkInstance
    demand::Shape 
    supply::Shape
    market::Market
    agents::Vector{Agent}
end

Base.@kwdef mutable struct ZIPSimulation <: BaseSimulationMethod 
    random_seed::Int = 100
end

Base.@kwdef mutable struct RLSimulation <: BaseSimulationMethod 
    random_seed::Int = 100
end

Base.@kwdef mutable struct GridOnlySimulation <: BaseSimulationMethod 
    random_seed::Int = 100
end
