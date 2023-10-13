function _validate_line_congestion(
    network::NetworkInstance,
    ΔP::Union{Float64, Int},
    ptdf::Vector{Float64}
)::Bool
    # source bus and target bus
    Δflow = ptdf * ΔP
    for line in network.lines 
        new_flow = line.current_flow + Δflow[line.index]
        abs(new_flow) <= line.normal_flow_limit || return false
    end
    # all lines have been checked, return true
    return true
end

function _compute_ptdf(
    network::NetworkInstance,
    from_bus::Bus,
    to_bus::Bus
)::Vector{Float64}
    n_lines = length(network.lines)
    isf_i = from_bus.offset === 0 ? zeros(n_lines) : network.isf[:, from_bus.offset]
    isf_j = to_bus.offset === 0 ? zeros(n_lines) : network.isf[:, to_bus.offset]
    return isf_i - isf_j
end