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

Base.@kwdef mutable struct RLTrader <: Trader
    buying_limit_price::Vector{Float64}
    selling_limit_price::Vector{Float64}
    current_price::Float64 = 0.0
    price_history::Vector{Float64} = Float64[]
    # define the 4 network + buffer
    actor_network = nothing
    critic_network = nothing
    target_actor_network = nothing 
    target_critic_network = nothing
    buffer = nothing
    batch_size::Int = 50
end