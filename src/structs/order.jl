Base.@kwdef mutable struct Order
    agent::Agent
    trader::Trader
    order_type::String
    price::Float64
    quantity::Float64
    time_counter_submit::Int
    time_counter_expire::Int
    priority::Int = 999
    skip::Bool = false
end
