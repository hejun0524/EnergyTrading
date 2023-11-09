function _allocate_time_counts()::Int
    return rand(10:60)
end

function _get_forecast(
    shape::Shape,
    time_counter_start::Int,
    total_time_counts::Int
)::Vector{Float64}
    time_counter_end = time_counter_start + total_time_counts - 1
    time_counter_end = min(time_counter_end, length(shape.data))
    total_time_counts = time_counter_end - time_counter_start + 1
    forecast = _randomize.(shape.data[time_counter_start:time_counter_end])
    return forecast
end