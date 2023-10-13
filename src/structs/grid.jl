Base.@kwdef mutable struct Grid
    sell_out_price::Vector{Float64}
    buy_in_price::Vector{Float64}
    bus::Bus
    sell_out_quantity::Float64 = 0.0
    buy_in_quantity::Float64 = 0.0
    revenue::Float64 = 0.0
    cost::Float64 = 0.0
end