using Distributions

Base.@kwdef mutable struct CDAMarket <: Market
    arrival::Union{Distribution, Nothing} = nothing
    book_buy::Vector{Order} = Order[]
    book_sell::Vector{Order} = Order[]
    most_recent_order::Union{Order, Nothing} = nothing 
    clearing_history::Vector{Transaction} = Transaction[]
end