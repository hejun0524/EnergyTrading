function _proceed_time!(clock::Clock)
    clock.time_counter += 1
    clock.time_now += clock.time_step
end

function _is_over(clock::Clock)
    return clock.time_now >= clock.T
end

function _get_time_counter_of_day(clock::Clock)
    return _get_time_counter_of_day(clock, clock.time_counter)
end

function _get_time_counter_of_day(clock::Clock, time_counter::Int)
    n_steps = clock.n_steps_one_day
    counter_of_day = time_counter % n_steps
    return counter_of_day == 0 ? n_steps : counter_of_day
end