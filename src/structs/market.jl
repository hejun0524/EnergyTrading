Base.@kwdef mutable struct CDAMarket <: Market
    book_buy::Vector{Order}
    book_sell::Vector{Order}
    most_recent_order::Union{Order, Nothing} = nothing 
    clearing_history::Vector{Transaction}
    bid_quantities::Matrix{Float64}
end