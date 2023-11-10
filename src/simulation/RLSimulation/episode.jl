function _run_episode!(
    instance::SimulationInstance,
)
    # initiate arrival time 
    arrival_time = 0.0
    # reset clock and market
    _reset_clock!(instance.clock)
    _reset_market!(instance.market, instance.agents)
    # clock must be discrete to sync with system
    fred = 0
    while !_is_over(instance.clock)
        # proceed the time at the beginning
        _proceed_time!(instance.clock)

        # market remove old orders, some agents receive reward
        expired_transactions = _remove_expired_orders!(
            instance.market, instance.grid, instance.network, instance.clock)

        for rejection in expired_transactions
            agent = rejection.last_shout.agent
            _modify_memory!(
                agent.trader.buffer,
                agent.trader.buffer.memory_counter,
                reward = rejection.reward,
                done = _is_over(instance.clock),
            )
        end

        # select agents
        selected_agents = []
        while _get_time_counter_from_continuous_time(
                instance.clock, arrival_time) < instance.clock.time_counter
            # get next sample
            arrival_time += instance.market.arrival === nothing ? 1.0 : rand(instance.market.arrival)
            # choose an agent
            selected_agent = _random_enter_market(instance.agents, instance.clock.time_counter)
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

        # generate agent decision 
        new_orders = Order[]
        for agent in selected_agents 
            curr_state = _get_observations!(
                agent, 
                instance.market, 
                instance.clock, 
                instance.demand,
                instance.supply,
                instance.grid, 
                instance.network,
            )
            # append the states to the previous memory
            if agent.trader.buffer.memory_counter >= 1
                _modify_memory!(
                    agent.trader.buffer,
                    agent.trader.buffer.memory_counter,
                    next_state = deepcopy(curr_state),
                    done = _is_over(instance.clock),
                )
                # learning
                _learn!(agent.trader)
                fred += 1
            end
            # generate new action
            new_order, action = _generate_trader_order!(
                agent,
                agent.trader,
                instance.clock,
                curr_state,
            )
            push!(new_orders, new_order)
            # store as new memory
            _store_new_memory!(
                agent.trader.buffer,
                state = deepcopy(curr_state),
                action = action,
                done = _is_over(instance.clock),
            )
        end

        # market receive and sort orders 
        _receive_and_sort_order_books!(instance.market, new_orders, instance.clock)

        # market match and process order, some agents receive reward
        deals = Deal[]
        while true
            transaction = _match_and_process_orders!(
                instance.market, instance.network, instance.grid, instance.clock)
            
            # logging
            push!(instance.market.clearing_history, transaction)

            # no more matches if no more deals
            if !(transaction isa Deal)
                _remove_skip_flags!(instance.market)
                break
            else 
                push!(deals, transaction)
                _modify_memory!(
                    transaction.from_agent.trader.buffer,
                    transaction.from_agent.trader.buffer.memory_counter,
                    reward = transaction.reward,
                    done = _is_over(instance.clock),
                )
                _modify_memory!(
                    transaction.to_agent.trader.buffer,
                    transaction.to_agent.trader.buffer.memory_counter,
                    reward = transaction.reward,
                    done = _is_over(instance.clock),
                )
            end
        end
        # update market history
        _update_market_history!(instance.market, instance.clock, deals = deals)

        # reset flow to prevent carry over
        for line in instance.network.lines
            _reset_line_flow!(line)
        end

        # finally snapshot all traders' current price & storage
        for agent in instance.agents    
            _append_current_trader_price!(agent.trader)
        end
    end
    println("Learned $(fred) times")
end