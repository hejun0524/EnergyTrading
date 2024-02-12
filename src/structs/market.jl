using Distributions

Base.@kwdef mutable struct CDAMarket <: Market
    arrival::Union{Distribution,Nothing} = nothing
    book_buy::Vector{Order} = Order[]
    book_sell::Vector{Order} = Order[]
    most_recent_order::Union{Order,Nothing} = nothing
    clearing_history::Vector{Transaction} = Transaction[]
    price_history::Vector{Float64}
    quantity_history::Vector{Float64}
    clearing_method::String = "Conventional"
end

Base.@kwdef mutable struct QuantityCDAMarket <: Market
    arrival::Union{Distribution,Nothing} = nothing
    max_price::Vector{Float64}
    min_price::Vector{Float64}
    book_buy::Vector{Order} = Order[]
    book_sell::Vector{Order} = Order[]
    most_recent_order::Union{Order,Nothing} = nothing
    clearing_history::Vector{Transaction} = Transaction[]
    clearing_method::String # Conventional or Proportional
    current_supply::Float64 = 0.0
    current_demand::Float64 = 0.0
    current_ratio::Float64 = 0.0
    current_price::Float64 = 0.0
    price_history::Vector{Float64}
    supply_history::Vector{Float64}
    demand_history::Vector{Float64}
    ratio_history::Vector{Float64}
end
