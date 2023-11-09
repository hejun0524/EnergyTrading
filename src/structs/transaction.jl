Base.@kwdef mutable struct Waiting <: Transaction
    time_counter::Int
end

Base.@kwdef mutable struct Deal <: Transaction
    from_agent::Agent
    from_agent_cleared::Bool
    to_agent::Agent
    to_agent_cleared::Bool
    price::Float64
    quantity::Float64
    time_counter::Int
    last_shout::Order
    is_valid::Bool = true
    is_valid_voltage::Bool = true
    is_valid_flow::Bool = true
    loss_charge::Float64 = 0.0
    utilization_charge::Float64 = 0.0
    reward::Float64 = 0.0
end

Base.@kwdef mutable struct Rejection <: Transaction
    price::Float64
    time_counter::Int
    last_shout::Order
    reward::Float64 = 0.0
end
