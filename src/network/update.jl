function _update_network!(
    network::NetworkInstance,
    ΔP::Float64,
    vsc::Vector{Complex},
    ptdf::Vector{Float64},
)
    # change system voltages if valid 
    for bus in network.buses
        _update_bus_voltage!(bus, vsc[bus.index], ΔP)
    end
    # change line flows if valid
    for line in network.lines 
        _update_line_flow!(line, ptdf[line.index], ΔP)
    end
end

function _update_bus_voltage!(
    bus::Bus,
    ∂v::Complex,
    ΔP::Float64,
)
    Δv_mag, Δθ = _complex_to_polar(ΔP * ∂v)
    bus.v_mag += Δv_mag
    bus.v_ang += Δθ
end

function _update_line_flow!(
    line::TransmissionLine,
    ptdf::Float64,
    ΔP::Float64,
)
    Δflow = ptdf * ΔP
    line.current_flow += Δflow
end

function _reset_bus_voltage!(bus::Bus)
    bus.v_mag = 0
    bus.v_ang = 0
end

function _reset_line_flow!(line::TransmissionLine)
    line.current_flow = 0
end