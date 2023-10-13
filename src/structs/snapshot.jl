Base.@kwdef mutable struct TradingSnapshot <: Snapshot
    target::Union{Grid, Agent}
    action::String
    time_counter::Int
    price::Float64
    quantity::Float64
    trader_group::Int
    spending::Float64
    loss_charge::Float64
    utilization_charge::Float64
    blocked::Bool
end
