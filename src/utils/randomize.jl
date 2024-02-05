using Distributions

function _randomize(base_number::Float64, dist = TriangularDist(0.9, 1.1, 1.0))::Float64
    return base_number * rand(dist)
end
