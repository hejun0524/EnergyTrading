function _finalize_reward!(r::ConventionalReward)
    direction = 0.0
    if r.order_type == "bid"
        direction = -1.0
    elseif r.order_type == "ask"
        direction = 1.0
    end
    difference = r.raw_reward - r.price_baseline * r.quantity
    r.reward = difference * direction
end

function _finalize_reward!(r::NormalizedReward)
    lb = r.quantity * r.price_lb
    ub = r.quantity * r.price_ub
    rew = (r.raw_reward - lb) / (ub - lb)
    r.reward = clamp(rew, 0.0, 1.0)
end

function _accumulate_raw_reward!(r::Reward, val::Float64; replace::Bool = false)
    r.raw_reward = (replace ? 0.0 : r.discount * r.raw_reward) + val
end

function _get_reward_value(r::Reward)
    return r.reward
end
