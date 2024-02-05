using Distributions

function _generate_trader_order!(
    agent::Agent,
    market::CDAMarket,
    trader::DDPGTrader,
    clock::Clock,
    states::Vector{Float64},
)::Tuple{Order,Vector{Float64},Dict}
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
    min_q =
        -sum(states[DEMAND_FORECAST:DEMAND_FORECAST+dt]) -
        (states[STORAGE_SIZE] - states[STORAGE_STATUS])
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
    return new_order, actions, Dict(:reward => ConventionalReward())
end

function _generate_trader_order!(
    agent::Agent,
    market::QuantityCDAMarket,
    trader::DDPGTrader,
    clock::Clock,
    states::Vector{Float64},
)::Tuple{Order,Vector{Float64},Dict}
    actions = trader.actor_network.model(states)
    # add some noise to the actions
    actions += rand(Normal(0, 0.1), length(actions))
    clamp!(actions, -1.0, 1.0)
    actions = (actions .+ 1.0) ./ 2.0
    # define constants 
    Q = 1
    STORAGE_STATUS, STORAGE_SIZE = 4, 5
    DEMAND_FORECAST = 6

    # get dt
    # min_t = 5
    # max_t = 60 # minutes
    # dt = min_t + (max_t - min_t) * actions[DT]
    # dt = _get_time_counter_from_continuous_time(clock, dt)
    dt = 1
    time_counter_expire = min(clock.time_counter + dt, clock.n_steps)
    dt = time_counter_expire - clock.time_counter
    # get some data 
    demand_forecast = sum(states[DEMAND_FORECAST:DEMAND_FORECAST+dt])
    storage_status = states[STORAGE_STATUS]
    storage_to_go = states[STORAGE_SIZE] - states[STORAGE_STATUS]

    # get q, p 
    min_q = -demand_forecast
    max_q = 0
    if agent isa Prosumer
        min_q -= storage_to_go
        max_q = storage_status - demand_forecast
    elseif agent isa Producer
        min_q = 0
        max_q = storage_status
    end
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

    # initialize reward
    if trader.reward_type == "conventional"
        reward = ConventionalReward(quantity = abs(q))
    elseif trader.reward_type == "normalized"
        reward = NormalizedReward(
            price_ub = q > 0 ? 15.0 : 2.0,
            price_lb = q > 0 ? 2.0 : 15.0,
            quantity = abs(q),
        )
    else
        error("Trader's reward type is not defined.")
    end

    # return order, actions and extra info
    return new_order, actions, Dict(:reward => reward)
end
