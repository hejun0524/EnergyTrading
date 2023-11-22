using Statistics

function _reload_shape!(
    shape::Shape,
    clock::Clock,
)
    shape.total_time > clock.T || return
    # get total time in min of a simulation period
    period = clock.n_steps * clock.time_step
    range = (1:period:shape.total_time)[1:end-1]
    p0 = rand(range)
    p1 = p0 + period - 1
    # get idx in raw data
    raw_p0 = p0 ÷ shape.time_step + 1
    raw_p1 = p1 ÷ shape.time_step + 1
    # time dim adjust
    shape.data = _time_dimension_adjust(
        shape.raw_data[raw_p0:raw_p1],
        arr_time_step = shape.time_step,
        sys_time_step = clock.time_step,
        arr_total_time = shape.total_time,
        sys_total_time = clock.T,
        max_steps = clock.n_steps,
    )
end