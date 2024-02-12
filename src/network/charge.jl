function _allocate_charge!(
    transaction::Deal,
    network::NetworkInstance,
    grid::Grid,
    ptdf::Vector{Float64},
    clock::Clock,
)
    bec = _compute_loss(network, transaction.from_agent.bus, transaction.to_agent.bus)
    transaction.loss_charge = grid.sell_out_price[clock.time_counter] * bec / 60
    utilization_charge = 0.0
    for l in network.lines
        if l.current_flow != 0.0
            utilization_charge +=
                l.utilization_fee * ptdf[l.index] * transaction.quantity / l.current_flow
        end
    end
    transaction.utilization_charge = utilization_charge / 60
end

function _compute_loss(network::NetworkInstance, from_bus::Bus, to_bus::Bus)::Float64
    v = [_polar_to_complex(bus.v_mag, bus.v_ang) for bus in network.buses]
    VG = transpose(conj(v)) * network.G
    lsf_i = real(VG * _compute_vsc(network, from_bus))
    lsf_j = real(VG * _compute_vsc(network, to_bus))
    bec = lsf_i - lsf_j
    return bec
end
