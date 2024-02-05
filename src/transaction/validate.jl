function _validate_transaction_and_update_network!(
    transaction::Transaction,
    network::NetworkInstance,
    grid::Grid,
    clock::Clock,
)
    (transaction isa Deal) || return
    # unpack values 
    from_bus = transaction.from_agent.bus
    to_bus = transaction.to_agent.bus
    ΔP = transaction.quantity
    # first compute current vsc
    vsc = _compute_vsc(network, to_bus)
    # validate voltage
    valid_voltage = _validate_voltage_change(network, ΔP, vsc)

    # second compute ptdf
    ptdf = _compute_ptdf(network, from_bus, to_bus)
    # validate transmission
    valid_transmission = _validate_line_congestion(network, ΔP, ptdf)

    # update valid flag
    transaction.is_valid_voltage = valid_voltage
    transaction.is_valid_flow = valid_transmission
    transaction.is_valid = valid_voltage && valid_transmission

    # update network
    transaction.is_valid && _update_network!(network, ΔP, vsc, ptdf)
    transaction.is_valid && _allocate_charge!(transaction, network, grid, ptdf, clock)
    # orginal logic
    # if not valid, no modification on `next_free_time` for all agents
    # return storage to seller and buyer needs to trade with the grid
    # _return_storage_sell!(transaction.from_agent.storage, transaction.quantity)
    # _grid_sell_to_agent!(grid, transaction.to_agent, transaction.quantity, clock)
end
