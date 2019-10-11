module Sim

using Random, DataStructures, DataFrames

include("Components.jl")
include("Clock.jl")
include("Logger.jl")

export  Logger, Record, switch!,                            # Logger.jl
        Clock, now, event!, run!, stop!, resume!, step!

Random.seed!(123)

end # module
