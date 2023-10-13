mutable struct Bus
    name::String
    offset::Int
    index::Int
    load::Float64
    q_load::Float64
    v_max::Float64
    v_min::Float64
    v_mag::Float64
    v_ang::Float64
    basekv::Float64
end

mutable struct TransmissionLine
    name::String
    offset::Int
    index::Int
    source::Bus
    target::Bus
    reactance::Float64
    susceptance::Float64
    normal_flow_limit::Float64
    emergency_flow_limit::Float64
    current_flow::Float64
    utilization_fee::Float64
end

Base.@kwdef mutable struct NetworkInstance
    name::String
    buses_by_name::Dict{AbstractString,Bus}
    buses::Vector{Bus}
    lines_by_name::Dict{AbstractString,TransmissionLine}
    lines::Vector{TransmissionLine}
    Y::Matrix{Complex}
    G::Matrix{Float64}
    isf::Matrix{Float64}
end