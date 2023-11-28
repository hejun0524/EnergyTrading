using Distributions 

function _generate_trader_order!(
    agent::Agent,
    market::CDAMarket,
    trader::RLTrader,
    clock::Clock,
    states::Vector{Float64},
)::Tuple{Order, Vector{Float64}}
    actions = trader.actor_network.model(states)
    # add some noise to the actions
    actions += rand(Normal(0, 0.1), length(actions))
    clamp!(actions, -1.0, 1.0)
    actions = (actions .+ 1.0) ./ 2.0
    # define constants 
    Q, P, DT = 1, 2, 3
    STORAGE_STATUS, STORAGE_SIZE = 4, 5
    DEMAND_FORECAST = 6

    # get dt
    min_t = 5
    max_t = 60 # minutes
    dt = min_t + (max_t - min_t) * actions[DT]
    dt = _get_time_counter_from_continuous_time(clock, dt)
    time_counter_expire = min(clock.time_counter + dt, clock.n_steps)
    dt = time_counter_expire - clock.time_counter

    # get q, p 
    min_q = - sum(states[DEMAND_FORECAST:DEMAND_FORECAST+dt]) - (states[STORAGE_SIZE] - states[STORAGE_STATUS])
    max_q = states[STORAGE_STATUS] - sum(states[DEMAND_FORECAST:DEMAND_FORECAST+dt])
    q = min_q + (max_q - min_q) * actions[Q]
    max_p = trader.buying_limit_price[clock.time_counter]
    min_p = trader.selling_limit_price[clock.time_counter]
    p = min_p + (max_p - min_p) * actions[P]

    # freeze storage if selling
    if q > 0
        q *= agent.storage.efficiency
        _freeze_storage!(agent.storage, q)
    end

    # generate order
    new_order = Order(
        agent = agent,
        trader = trader,
        order_type = q > 0 ? "ask" : "bid", 
        price = p,
        quantity = abs(q),
        time_counter_submit = clock.time_counter,
        time_counter_expire = time_counter_expire,
    )
    # update the current price
    trader.current_price = p
    return new_order, actions
end

function _generate_trader_order!(
    agent::Agent,
    market::QuantityCDAMarket,
    trader::RLTrader,
    clock::Clock,
    states::Vector{Float64},
)::Tuple{Order, Vector{Float64}}
    actions = trader.actor_network.model(states)
    # add some noise to the actions
    actions += rand(Normal(0, 0.1), length(actions))
    clamp!(actions, -1.0, 1.0)
    actions = (actions .+ 1.0) ./ 2.0
    # define constants 
    Q, DT = 1, 2
    STORAGE_STATUS, STORAGE_SIZE = 4, 5
    DEMAND_FORECAST = 6

    # get dt
    min_t = 5
    max_t = 60 # minutes
    dt = min_t + (max_t - min_t) * actions[DT]
    dt = _get_time_counter_from_continuous_time(clock, dt)
    time_counter_expire = min(clock.time_counter + dt, clock.n_steps)
    dt = time_counter_expire - clock.time_counter

    # get q, p 
    min_q = - sum(states[DEMAND_FORECAST:DEMAND_FORECAST+dt]) - (states[STORAGE_SIZE] - states[STORAGE_STATUS])
    max_q = states[STORAGE_STATUS] - sum(states[DEMAND_FORECAST:DEMAND_FORECAST+dt])
    q = min_q + (max_q - min_q) * actions[Q]

    # freeze storage if selling
    if q > 0
        q *= agent.storage.efficiency
        _freeze_storage!(agent.storage, q)
    end

    # generate order
    # price will be modified later after all agents submit
    new_order = Order(
        agent = agent,
        trader = trader,
        order_type = q > 0 ? "ask" : "bid", 
        price = 0.0, 
        quantity = abs(q),
        time_counter_submit = clock.time_counter,
        time_counter_expire = time_counter_expire,
    )
    return new_order, actions
end