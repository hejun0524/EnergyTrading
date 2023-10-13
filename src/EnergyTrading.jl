module EnergyTrading 

# include all the data structs
include("structs/abstract.jl")
include("structs/agent.jl")
include("structs/asset.jl")
include("structs/environment.jl")
include("structs/grid.jl")
include("structs/market.jl")
include("structs/network.jl")
include("structs/order.jl")
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
include("network/matrix.jl")
include("network/charge.jl")
include("network/congestion.jl")
include("network/voltage.jl")
include("network/update.jl")
include("simulation/read.jl")
include("simulation/RLSimulation/run.jl")


end