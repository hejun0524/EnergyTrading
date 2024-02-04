abstract type Reward end

Base.@kwdef mutable struct ConventionalReward <: Reward
    quantity::Float64 = 0.0
    order_type::String
    price_baseline::Float64 = 0.0
    raw_reward::Float64 = 0.0
    reward::Float64 = 0.0
    discount::Float64 = 1.0
end

Base.@kwdef mutable struct NormalizedReward <: Reward
    price_ub::Float64
    price_lb::Float64
    quantity::Float64 = 0.0
    raw_reward::Float64 = 0.0
    reward::Float64 = 0.0
    discount::Float64 = 1.0
end