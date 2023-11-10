function _reset_market!(
    market::CDAMarket,
    agents::Vector{Agent}
)
    market.book_buy = Order[]
    market.book_sell = Order[]
    market.most_recent_order = nothing 
    for agent in agents 
        agent.in_market = false
        (agent isa Prosumer) && (agent.in_market_as = "")
    end
end