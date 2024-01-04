using Distributions 

function _generate_trader_order!(
    agent::Agent,
    market::CDAMarket,
    trader::PPOTrader,
    clock::Clock,
    states::Vector{Float64},
)#::Tuple{Order, Vector{Float64}, Dict}
    error("This method is not implemented")
end

function _generate_trader_order!(
    agent::Agent,
    market::QuantityCDAMarket,
    trader::PPOTrader,
    clock::Clock,
    states::Vector{Float64},
)::Tuple{Order, Vector{Float64}, Dict}
    mean_actions = trader.actor_network.model(states)
    cov_mat = diagm([0.5 for _ in 1:length(mean_actions)])
    dist = MvNormal(mean_actions, cov_mat)
    # sample action from the distribution
    actions = rand(dist)
    # define constants 
    Q = 1
    STORAGE_STATUS, STORAGE_SIZE = 4, 5
    DEMAND_FORECAST = 6

    # get dt
    dt = 1
    time_counter_expire = min(clock.time_counter + dt, clock.n_steps)
    dt = time_counter_expire - clock.time_counter
    # get some data 
    demand_forecast = sum(states[DEMAND_FORECAST:DEMAND_FORECAST+dt])
    storage_status = states[STORAGE_STATUS]
    storage_to_go = states[STORAGE_SIZE] - states[STORAGE_STATUS]

    # get q, p 
    min_q = - demand_forecast
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
        if agent isa Consumer 
            q = 0
        else
            q *= agent.storage.efficiency
            _freeze_storage!(agent.storage, q)
        end
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
    return new_order, actions, Dict(
        :probability => loglikelihood(dist, actions),
        :value => Float64(trader.critic_network.model(states)[1]),
        :reward => NormalizedReward(
            price_ub = q > 0 ? 15.0 : 2.0,
            price_lb = q > 0 ? 2.0 : 15.0,
            quantity = abs(q),
        )
    )
end