function _get_real_time(
    shape::Shape,
    time_counter::Int;
    randomize = true
)::Float64
    time_counter <= length(shape.data) || error(
        "Time counter at $time_counter exceeds the length of shape data.")
    return _randomize(shape.data[time_counter])
    !randomize || return round(_randomize(shape.data[time_counter]), digits = 5)
    return round(shape.data[time_counter], digits = 5)
end