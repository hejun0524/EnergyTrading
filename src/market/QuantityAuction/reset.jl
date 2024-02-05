function _reset_market!(market::QuantityCDAMarket, agents::Vector{Agent})
    market.book_buy = Order[]
    market.book_sell = Order[]
    market.most_recent_order = nothing
    for agent in agents
        agent.in_market = false
        (agent isa Prosumer) && (agent.in_market_as = "")
    end
    market.current_supply = 0.0
    market.current_demand = 0.0
    market.current_ratio = 0.0
    market.current_price = 0.0
end
