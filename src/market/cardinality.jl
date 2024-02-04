function _cardinality(
    market::Market;
    simple_action::Bool = true
)::Tuple{Int, Int}
    (market isa CDAMarket) && return (simple_action ? 1 : 3, 41)
    (market isa QuantityCDAMarket) && return (simple_action ? 1 : 2, 33)
    error("The market type is not defined.")
end