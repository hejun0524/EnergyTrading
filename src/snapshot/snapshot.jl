function _add_snapshot_to_history!(
    agent::Agent;
    target::Union{Grid, Agent},
    action::String,
    clock::Clock,
    price::Float64,
    quantity::Float64,
    loss_charge::Float64 = 0.0,
    utilization_charge::Float64 = 0.0,
    blocked::Bool = false
)   
    λ = action === "buy" ? 1 : -1 
    extra_charge = (loss_charge + utilization_charge) / 2
    spending = blocked ? 0 : (λ * price * quantity + extra_charge)
    snapshot = TradingSnapshot(
        target = target,
        action = action,
        time_counter = clock.time_counter,
        price = price,
        quantity = quantity,
        spending = spending,
        loss_charge = loss_charge,
        utilization_charge = utilization_charge,
        blocked = blocked,
    )
    push!(agent.trading_history, snapshot)
end

function _add_deal_snapshot_to_agents!(
    deal::Deal,
    clock::Clock,
)
    _add_snapshot_to_history!(
        deal.from_agent,
        target = deal.to_agent,
        action = "sell",
        clock = clock,
        price = deal.price,
        quantity = deal.quantity,
        loss_charge = deal.loss_charge,
        utilization_charge = deal.utilization_charge,
        blocked = !deal.is_valid,
    )

    _add_snapshot_to_history!(
        deal.to_agent,
        target = deal.from_agent,
        action = "buy",
        clock = clock,
        price = deal.price,
        quantity = deal.quantity,
        loss_charge = deal.loss_charge,
        utilization_charge = deal.utilization_charge,
        blocked = !deal.is_valid,
    )
end