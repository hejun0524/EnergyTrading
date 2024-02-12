Base.@kwdef mutable struct Consumer <: Agent
    index::Int
    name::String
    bus::Bus
    trader::Trader
    next_free_time::Int = 1
    in_market::Bool = false
    current_basic_demand::Float64 = 0.0
    trading_history::Vector{Snapshot} = []
end

Base.@kwdef mutable struct Producer <: Agent
    index::Int
    name::String
    bus::Bus
    trader::Trader
    next_free_time::Int = 1
    in_market::Bool = false
    current_basic_demand::Float64 = 0.0 # always 0.0
    trading_history::Vector{Snapshot} = []
    storage::Asset
    panel::Asset
end

Base.@kwdef mutable struct Prosumer <: Agent
    index::Int
    name::String
    bus::Bus
    trader::Trader
    next_free_time::Int = 1
    in_market::Bool = false
    in_market_as::String = ""
    current_basic_demand::Float64 = 0.0
    trading_history::Vector{Snapshot} = []
    storage::Asset
    panel::Asset
end
