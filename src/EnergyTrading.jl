module EnergyTrading 

# include all the data structs
include("structs/abstract.jl")
include("structs/environment.jl")
include("structs/network.jl")
include("structs/grid.jl")
include("structs/order.jl")
include("structs/market.jl")
include("structs/agent.jl")
include("structs/asset.jl")
include("structs/shape.jl")
include("structs/snapshot.jl")
include("structs/trader.jl")
include("structs/transaction.jl")
include("structs/simulation.jl")

# include all the utils
include("utils/conversion.jl")
include("utils/time_series.jl")
include("utils/logging.jl")
include("utils/randomize.jl")
include("utils/solution.jl")
include("utils/write.jl")

# include all function files 
include("environment/clock.jl")
include("agent/enter.jl")
include("agent/prosume.jl")
include("asset/photovoltaic.jl")
include("asset/storage.jl")
include("network/matrix.jl")
include("network/charge.jl")
include("network/congestion.jl")
include("network/voltage.jl")
include("network/update.jl")
include("market/ContinuousDoubleAuction/process.jl")
include("market/ContinuousDoubleAuction/receive.jl")
include("market/ContinuousDoubleAuction/remove.jl")
include("market/ContinuousDoubleAuction/update.jl")
include("market/ContinuousDoubleAuction/reset.jl")
include("grid/action.jl")
include("shape/forecast.jl")
include("shape/real_time.jl")
include("shape/reload.jl")
include("transaction/validate.jl")
include("snapshot/snapshot.jl")
include("snapshot/trader_price.jl")
include("trader/RLTrader/replay_buffer.jl")
include("trader/RLTrader/neural_network.jl")
include("trader/RLTrader/construct.jl")
include("trader/RLTrader/state.jl")
include("trader/RLTrader/action.jl")
include("trader/RLTrader/learn.jl")
include("trader/RLTrader/jld2.jl")
include("trader/construct.jl")

# include all simulation entry file
include("simulation/read.jl")
include("simulation/RLSimulation/episode.jl")
include("simulation/RLSimulation/run.jl")


end