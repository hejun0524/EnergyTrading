using SparseArrays, Base.Threads, LinearAlgebra

"""
    _injection_shift_factors(; buses, lines)

Returns a (B-1)xL matrix M, where B is the number of buses and L is the number
of transmission lines. For a given bus b and transmission line l, the entry
M[l.offset, b.offset] indicates the amount of power (in MW) that flows through
transmission line l when 1 MW of power is injected at the slack bus (the bus
that has offset zero) and withdrawn from b.
"""
function _injection_shift_factors(;
    buses::Vector{Bus},
    lines::Vector{TransmissionLine},
)::Matrix{Float64}
    # L*L diagonal matrix for susceptance
    B = Diagonal([l.susceptance for l in lines])
    # reduced incidence matrix
    A = spzeros(Float64, length(lines), length(buses) - 1)
    for l in lines
        if l.source.offset > 0
            A[l.offset, l.source.offset] = 1
        end
        if l.target.offset > 0
            A[l.offset, l.target.offset] = -1
        end
    end
    # laplacian matrix
    L = A' * B * A
    # get ISF
    isf = B * A * inv(Array(L))
    return isf
end

function _admittance_matrix(;
    buses::Vector{Bus},
    lines::Vector{TransmissionLine},
)::Matrix{Complex}
    # get line and buses number
    n_lines = length(lines)
    n_buses = length(buses)
    r = [l.reactance for l in lines]
    x = [l.susceptance for l in lines]

    # construct z, y and Y
    z = r + x * im # line impedance
    y = ones(n_lines) ./ z # line admittance
    Y = zeros(Complex, n_buses, n_buses)

    for k = 1:n_lines
        l = lines[k]
        i, j = l.source.index, l.target.index
        Y[i, j] = Y[i, j] - y[k]
        Y[j, i] = Y[i, j]
    end

    for n = 1:n_buses
        for k = 1:n_lines
            l = lines[k]
            i, j = l.source.index, l.target.index
            if i == n || j == n
                Y[n, n] = Y[n, n] + y[k]
            end
        end
    end

    return Y
end

function _conductance_matrix(Y::Matrix)::Matrix{Union{Float64,Int}}
    return real(Y)
end
