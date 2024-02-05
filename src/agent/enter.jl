function _random_enter_market(
    agents::Vector{Agent},
    current_time_counter::Int,
)::Union{Agent,Nothing}
    free_agents =
        [x for x in agents if !(x.next_free_time > current_time_counter || x.in_market)]
    length(free_agents) > 0 || return nothing
    return rand(free_agents)
end
