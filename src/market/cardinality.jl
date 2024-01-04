function _cardinality(market::Market)::Tuple{Int, Int}
    (market isa CDAMarket) && return (3, 41)
    (market isa QuantityCDAMarket) && return (2, 33)
    error("The market type is not defined.")
end