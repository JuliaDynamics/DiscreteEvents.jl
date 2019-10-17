module Sim

using Random, DataStructures, DataFrames

include("Components.jl")
include("Clock.jl")
include("Logger.jl")

export  Logger, Record, switch!, setup!, init!, record!, clear!,  # Logger.jl

        Clock, now, sample_time!, event!, sample!,                # Clock.jl
        incr!, run!, stop!, resume!,
        Timing, at, after, every, before

Random.seed!(123)

end # module
