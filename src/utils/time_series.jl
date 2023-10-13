function _time_series(x, T; default = nothing)
    x !== nothing || return default
    x isa Array || return [x for _ in 1:T]
    return x
end