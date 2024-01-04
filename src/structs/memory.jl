abstract type ReplayBuffer end

Base.@kwdef mutable struct DDPGMemory <: ReplayBuffer
    max_memory_size::Int 
    n_states::Int
    n_actions::Int
    memory_counter::Int
    state_memory::Vector{Any} = []
    next_state_memory::Vector{Any} = []
    action_memory::Vector{Any} = []
    reward_memory::Vector{Reward} = []
    terminal_memory::Vector{Bool} = []
end

Base.@kwdef mutable struct PPOMemory <: ReplayBuffer
    n_states::Int
    n_actions::Int
    state_memory::Vector{Any} = []
    probability_memory::Vector{Float64} = []
    value_memory::Vector{Float64} = []
    action_memory::Vector{Any} = []
    reward_memory::Vector{Reward} = []
    terminal_memory::Vector{Bool} = []
end
