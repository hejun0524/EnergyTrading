using DataStructures, Statistics

function solution(instance::SimulationInstance)::OrderedDict
    @info "Generating solution..."
    sol = OrderedDict()
    # report market transaction history
    market_clearing_log = _retrieve_log(instance.market)
    sol["Market clearing history"] = OrderedDict(
        "Total number" => length(market_clearing_log),
        # "Cached clearing prices" => vec(mean(instance.market.clearing_prices, dims = 1)),
        # "Cached bid quantities" => vec(mean(instance.market.bid_quantities, dims = 1)),
        "Log" => market_clearing_log,
    )

    # report trader shout prices
    sol["Trader bid price history"] = OrderedDict(
        agent.name => OrderedDict(
            "Bus" => agent.bus.name,
            "Traders (buyers)" => agent.trader.price_history,
        ) for agent in instance.agents if (agent isa Consumer || agent isa Prosumer)
    )

    sol["Trader ask price history"] = OrderedDict(
        agent.name => OrderedDict(
            "Bus" => agent.bus.name,
            "Traders (sellers)" => agent.trader.price_history,
        ) for agent in instance.agents if (agent isa Producer || agent isa Prosumer)
    )

    # report agent revenue
    sol["Agent revenue history"] = OrderedDict(
        agent.name => OrderedDict(
            "Bus" => agent.bus.name,
            # "Total spending" => sum([snap.spending for snap in agent.trading_history]),
            # "Log" => _retrieve_log(agent)
        ) for agent in instance.agents
    )

    # report grid revenue
    sol["Grid revenue history"] = OrderedDict(
        "Grid total sold" => instance.grid.sell_out_quantity,
        "Grid total revenue" => instance.grid.revenue,
        "Grid total purchased" => instance.grid.buy_in_quantity,
        "Grid total cost" => instance.grid.cost,
        "Grid net earning" => instance.grid.revenue - instance.grid.cost,
        "Note" => "For detailed transaction history, please refer to agent revenue history.",
    )

    return sol
end

function _get_target_name(target::Union{Grid,Agent})
    typeof(target) <: Agent || return "grid"
    return "$(target.name) at $(target.bus.name)"
end

function _retrieve_log(agent::Agent)
    log = [
        OrderedDict(
            "Time counter" => snap.time_counter,
            "Action" => snap.action,
            "Target" => _get_target_name(snap.target),
            "Price" => snap.price,
            "Quantity" => snap.quantity,
            "Spending" => snap.spending,
            "Loss charge" => snap.loss_charge,
            "Utilization charge" => snap.utilization_charge,
            "Blocked" => snap.blocked,
        ) for snap in agent.trading_history
    ]
    return []
end

function _retrieve_log(market::Market)
    log = [
        OrderedDict(
            "Time counter" => tsc.time_counter,
            # "From" => tsc.from_agent.name,
            "From bus" => tsc.from_agent.bus.name,
            # "To" => tsc.to_agent.name,
            "To bus" => tsc.to_agent.bus.name,
            "Price" => tsc.price,
            "Quantity" => tsc.quantity,
            "Loss charge" => tsc.loss_charge,
            "Utilization charge" => tsc.utilization_charge,
            "V Blocked" => !tsc.is_valid_voltage,
            "I Blocked" => !tsc.is_valid_flow,
        ) for tsc in market.clearing_history if typeof(tsc) === Deal
    ]
    return log
end
