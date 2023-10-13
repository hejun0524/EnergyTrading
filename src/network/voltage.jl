function _validate_voltage_change(
    network::NetworkInstance,
    ΔP::Union{Float64, Int},
    vsc::Vector{Complex},
)::Bool
    # target bus get power, get all buses' dv/dP
    Δv = _compute_voltage_changes(network, ΔP, vsc)
    for bus in network.buses
        if bus.index !== 1 # do not check slack bus
            new_v_mag = bus.v_mag + Δv[bus.index]
            (bus.v_min <= new_v_mag <= bus.v_max) || return false
        end
    end
    # all buses have been checked, return true
    return true
end

function _compute_voltage_changes(
    network::NetworkInstance,
    ΔP::Union{Float64, Int},
    vsc::Vector{Complex},
)::Vector{Float64}
    v = [_polar_to_complex(bus.v_mag, bus.v_ang) for bus in network.buses]
    Δv = [ΔP / abs(v[i]) * real(conj(v[i]) * vsc[i]) 
        for i = 1:length(network.buses)]
    return Δv
end

function _compute_vsc(
    network::NetworkInstance,
    target_bus::Bus,
)::Vector{Complex}
    target_bus.index != 1 || error("Slack bus does not have partial derivatives.")
    n = length(network.buses)
    M = zeros(Complex, n, n)
    N = zeros(Complex, n, n)
    v = [_polar_to_complex(bus.v_mag, bus.v_ang) for bus in network.buses]
    vstar = conj(v)

    for i = 1:n 
        # update non-slack entries on M
        M[i, :] = [0 (vstar[i] * network.Y[i, 2:end])']
        # update entries on N
        N[i, i] = network.Y[i, :]' * v
    end

    # solve the linear complex system 
    A = [ M N; conj(N) conj(M) ]
    b = zeros(n)
    b[target_bus.index] = 1
    b = [b; b]
    # length of 2n (complex and conjugate)
    vsc = A \ b
    # return only the complex part
    return vsc[1:n]
end