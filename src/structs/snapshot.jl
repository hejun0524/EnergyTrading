Base.@kwdef mutable struct TradingSnapshot <: Snapshot
    target::Union{Grid,Agent}
    action::String
    time_counter::Int
    price::Float64
    quantity::Float64
    spending::Float64
    loss_charge::Float64
    utilization_charge::Float64
    blocked::Bool
end
