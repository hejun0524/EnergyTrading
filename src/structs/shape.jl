mutable struct Shape
    name::String
    data::Vector{Float64}
    raw_data::Vector{Float64}
    average::Float64
    time_step::Int
    total_time::Int
end