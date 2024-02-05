function _freeze_storage!(storage::Storage, quantity::Float64)
    real_quantity = quantity / storage.efficiency
    storage.frozen_quantity = real_quantity
end

function _sell_power_from_storage!(storage::Storage, quantity::Float64)
    real_quantity = quantity / storage.efficiency
    storage.frozen_quantity -= real_quantity
    storage.current_level -= real_quantity
end

function _return_storage_sell!(storage::Storage, quantity::Float64)
    real_quantity = quantity / storage.efficiency
    storage.current_level += real_quantity
end

function _update_storage!(storage::Storage, quantity::Float64)::Float64
    storage.current_level += quantity
    # cannot go above cap
    if storage.current_level > storage.capacity
        overflow = storage.current_level - storage.capacity
        storage.current_level = storage.capacity
        return overflow
    end
    # cannot go below frozen quantity
    if storage.current_level < storage.frozen_quantity
        underflow = storage.current_level - storage.frozen_quantity
        storage.current_level = storage.frozen_quantity
        return underflow
    end
    return 0.0
end
