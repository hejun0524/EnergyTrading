Base.@kwdef mutable struct ZIPTrader <: Trader
    action_type::String
    trader_group::Int
    limit_price::Vector{Float64}
    current_price::Float64
    price_history::Vector{Float64}
    margin::Float64 = 0.0
    momentum::Float64 = 0.0
    beta::Float64 = 0.3
    gamma::Float64 = 0.05
end

abstract type RLTrader <: Trader end

Base.@kwdef mutable struct DDPGTrader <: RLTrader
    buying_limit_price::Vector{Float64}
    selling_limit_price::Vector{Float64}
    current_price::Float64 = 0.0
    price_history::Vector{Float64} = Float64[]
    reward_type::String = "conventional"
    # define the 4 network + buffer
    actor_network = nothing
    critic_network = nothing
    target_actor_network = nothing
    target_critic_network = nothing
    buffer::DDPGMemory
    batch_size::Int = 50
    training_frequency::Int = 1 # train every 1 time stamp
    # define parameters 
    α::Float64 = 0.001
    β::Float64 = 0.002
    γ::Float64 = 0.99
    τ::Float64 = 0.005
end

Base.@kwdef mutable struct PPOTrader <: RLTrader
    buying_limit_price::Vector{Float64}
    selling_limit_price::Vector{Float64}
    current_price::Float64 = 0.0
    price_history::Vector{Float64} = Float64[]
    reward_type::String = "conventional"
    # define the 2 network + buffer
    actor_network = nothing
    critic_network = nothing
    buffer::PPOMemory
    batch_size::Int = 50
    training_frequency::Int = 20 # train every 20 time stamp
    # define parameters 
    α::Float64 = 0.0003
    γ::Float64 = 0.99
    λ::Float64 = 0.95
    ε::Float64 = 0.2
    epochs::Int = 4
end
