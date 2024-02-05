function _polar_to_complex(magnitude::Float64, angle::Float64)::Complex
    a = magnitude * cosd(angle)
    b = magnitude * sind(angle)
    return a + b * im
end

function _complex_to_polar(complex::Complex)::Tuple{Float64,Float64}
    magnitude = abs(complex)
    θ = rad2deg(angle(complex))
    return magnitude, θ
end
