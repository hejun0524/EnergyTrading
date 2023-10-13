Base.@kwdef mutable struct Clock <: EnvironmentObject
    T::Int 
    time_step::Int 
    n_steps::Int
    n_steps_one_day::Int
    time_now::Int = 0
    time_counter::Int = 0
    time_groups::Union{Nothing, Vector{Int}} = nothing
    time_group_notes::Union{Nothing, Dict{Int, String}} = nothing
    n_groups::Int = 1
end