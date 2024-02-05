Base.@kwdef mutable struct Storage <: Asset
    capacity::Float64
    efficiency::Float64
    current_level::Float64 = 0.0
    frozen_quantity::Float64 = 0.0
end

Base.@kwdef mutable struct SolarPanel <: Asset
    max_rate::Float64
    efficiency::Float64
end
