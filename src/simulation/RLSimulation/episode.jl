using Distributions
using Random

function _run_episode!(instance::SimulationInstance, evaluate::Bool)
    # initiate arrival time 
    arrival_time = 0.0
    # reset clock and market
    _reset_clock!(instance.clock)
    _reset_market!(instance.market, instance.agents)
    _reload_shape!(instance.demand, instance.clock)
    _reload_shape!(instance.supply, instance.clock)
    # clock must be discrete to sync with system
    learning_counter = 0
    while !_is_over(instance.clock)
        # proceed the time at the beginning
        _proceed_time!(instance.clock)
        # get done flag
        done = _is_over(instance.clock)

        # market remove old orders, some agents receive reward
        expired_transactions = _remove_expired_orders!(
            instance.market,
            instance.grid,
            instance.network,
            instance.clock,
        )

        for rejection in expired_transactions
            agent = rejection.last_shout.agent
            _modify_memory_interface!(
                agent.trader.buffer,
                arguments = Dict(:reward => rejection.reward, :done => done),
            )
            _finalize_reward!(agent.trader.buffer.reward_memory[end])
        end

        # select agents
        selected_agents = []
        if instance.market.arrival !== nothing
            while _get_time_counter_from_continuous_time(instance.clock, arrival_time) <
                  instance.clock.time_counter
                # get next sample
                arrival_time += rand(instance.market.arrival)
                # choose an agent
                selected_agent =
                    _random_enter_market(instance.agents, instance.clock.time_counter)
                selected_agent === nothing || push!(selected_agents, selected_agent)
            end
            # all agents non-selected prosume, no learning
            selected_agents_idx = [a.index for a in selected_agents]
            for agent in instance.agents
                if !(agent.index in selected_agents_idx)
                    _produce_and_consume!(
                        agent,
                        instance.clock,
                        demand_shape = instance.demand,
                        supply_shape = instance.supply,
                        network = instance.network,
                        grid = instance.grid,
                    )
                end
            end
        else
            # agents are always in the market
            selected_agents = Random.shuffle([a for a in instance.agents])
        end

        # basic agent demands 
        for agent in selected_agents
            agent_can_consume = agent isa Prosumer || agent isa Consumer
            agent_can_produce = agent isa Prosumer || agent isa Producer
            if agent_can_consume 
                agent.current_basic_demand = _get_real_time(instance.demand, instance.clock.time_counter)
            end
            if agent_can_produce
                current_supply = _get_real_time(instance.supply, instance.clock.time_counter)
                # store into storage unit by satisfying current demand first
                current_storage_flow =
                    _update_storage!(agent.storage, current_supply - agent.current_basic_demand)
                # if there is surplus, need to deal with grid first, no learning
                # else this is a demand
                if current_storage_flow > 0.0
                    _grid_buy_from_agent!(
                        instance.grid, agent, current_storage_flow, instance.network, instance.clock)
                    agent.current_basic_demand = 0.0
                else
                    agent.current_basic_demand = abs(current_storage_flow)
                end
            end
        end
        _update_initial_ratio!(instance.market, selected_agents, instance.clock)

        # generate agent decision 
        new_orders = Order[]
        for agent in selected_agents
            curr_state = _get_observations!(
                agent,
                instance.market,
                instance.clock,
                instance.demand,
            )
            ## Note: if counter >= 1, DDPG should modify mem's next_state
            if agent.trader isa DDPGTrader
                if agent.trader.buffer.memory_counter >= 1
                    _modify_memory_interface!(
                        agent.trader.buffer,
                        arguments = Dict(:next_state => curr_state),
                    )
                    _learn!(agent.trader)
                    learning_counter += 1
                end
            elseif agent.trader isa PPOTrader
                # PPO should evaluate every few time stamps
                if !evaluate &&
                   (instance.clock.time_counter % agent.trader.training_frequency == 0)
                    _learn!(agent.trader)
                    learning_counter += 1
                end
            end

            # generate new action
            new_order, action, extra = _generate_trader_order!(
                agent,
                instance.market,
                agent.trader,
                instance.clock,
                curr_state,
            )
            push!(new_orders, new_order)
            _receive_order!(instance.market, new_order, instance.clock)
            
            # store as new memory
            _store_memory_interface!(
                agent.trader.buffer,
                arguments = Dict(
                    :state => curr_state,
                    :action => action,
                    :done => done,
                    extra...,
                ),
            )
        end

        for order in new_orders 
            _fix_price!(instance.market, order)
        end

        _sort_order_books!(instance.market)

        # market receive and sort orders 
        # _receive_and_sort_order_books!(instance.market, new_orders, instance.clock)

        # market match and process order, some agents receive reward
        if instance.market.clearing_method === "Conventional"
            deals = Deal[]
            while true
                transaction = _match_and_process_orders!(
                    instance.market,
                    instance.network,
                    instance.grid,
                    instance.clock,
                )

                # logging
                push!(instance.market.clearing_history, transaction)

                # no more matches if no more deals
                if !(transaction isa Deal)
                    _remove_skip_flags!(instance.market)
                    break
                else
                    push!(deals, transaction)
                    for (agent, cleared) in [
                        (transaction.from_agent, transaction.from_agent_cleared),
                        (transaction.to_agent, transaction.to_agent_cleared),
                    ]
                        _modify_memory_interface!(
                            agent.trader.buffer,
                            arguments = Dict(:reward => transaction.reward, :done => done),
                        )
                        if cleared
                            _finalize_reward!(agent.trader.buffer.reward_memory[end])
                        end
                    end
                end
            end
            # update market history
            _update_market_history!(instance.market, instance.clock, deals = deals)
        elseif instance.market.clearing_method === "Proportional"
            deals = Deal[]
            transactions = _proportionally_clear_orders!(
                instance.market,
                instance.network,
                instance.grid,
                instance.clock,
            )
            for transaction in transactions
                # logging
                push!(instance.market.clearing_history, transaction)

                # no more matches if no more deals
                if !(transaction isa Deal)
                    _remove_skip_flags!(instance.market)
                    break
                else
                    push!(deals, transaction)
                    for (agent, cleared) in [
                        (transaction.from_agent, transaction.from_agent_cleared),
                        (transaction.to_agent, transaction.to_agent_cleared),
                    ]
                        _modify_memory_interface!(
                            agent.trader.buffer,
                            arguments = Dict(:reward => transaction.reward, :done => done),
                        )
                        if cleared
                            _finalize_reward!(agent.trader.buffer.reward_memory[end])
                        end
                    end
                end
            end
            # update market history
            _update_market_history!(instance.market, instance.clock, deals = deals)
        else 
            error("The market clearing method is not supported")
        end


        # reset flow to prevent carry over
        for line in instance.network.lines
            _reset_line_flow!(line)
        end

        # finally snapshot all traders' current price & storage
        for agent in instance.agents
            _append_current_trader_price!(agent.trader)
        end
    end
    @info "Learned $(learning_counter) times"
end
