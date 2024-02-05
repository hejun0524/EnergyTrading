function _logging_after_sorting_order(
    instance::SimulationInstance,
    new_order::Union{Order,Nothing},
)
    # print time 
    println("Current time: $(instance.clock.time_counter)")
    if new_order !== nothing
        println("New Agent: $(new_order.agent.index)")
    else
        println("New Agent: None")
    end
    # print market 
    println("--------- BIDS ---------")
    for (index, order) in enumerate(instance.market.book_buy)
        println(
            "$(index): Buyer=$(order.agent.index), P=$(order.price), Q=$(order.quantity), T=[$(order.time_counter_submit), $(order.time_counter_expire)], ($(order.priority))",
        )
    end
    println("--------- ASKS ---------")
    for (index, order) in enumerate(instance.market.book_sell)
        println(
            "$(index): Seller=$(order.agent.index), P=$(order.price), Q=$(order.quantity), T=[$(order.time_counter_submit), $(order.time_counter_expire)], ($(order.priority))",
        )
    end
end

function _logging_after_transaction(transaction::Transaction)
    # print transaction
    println("The transaction is a $(typeof(transaction))")
    if transaction isa Deal
        println("Dealt at time counter: $(transaction.time_counter)")
        println("Price: \$ $(transaction.price)")
        println("Quantity: $(transaction.quantity) MW")
        println("Shout type: $(transaction.last_shout.order_type)")
        println("Flow: $(transaction.from_agent.index) -> $(transaction.to_agent.index)")
        if transaction.from_agent_cleared
            println("From agent is cleared")
        elseif transaction.to_agent_cleared
            println("To agent is cleared")
        end
        if transaction.is_valid
            println("Loss charge: \$\$ $(transaction.loss_charge)")
            println("Utilization charge: \$\$ $(transaction.utilization_charge)")
        else
            println("[IMPORTANT] This transaction is blocked by the network")
            if !transaction.is_valid_voltage
                println("[ISSUE] Voltage issue detected")
            end
            if !transaction.is_valid_flow
                println("[ISSUE] Congestion issue detected")
            end
        end
    elseif transaction isa Rejection
        println("Rejected at time counter: $(transaction.time_counter)")
        println("Price: $(transaction.price)")
        println("Shout type: $(transaction.last_shout.order_type)")
    end
    println(".............................................................")
end
