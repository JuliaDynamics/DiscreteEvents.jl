
"""
    Sim

A Julia package for discrete event simulation based on state machines.
"""
module Sim

using Random, DataStructures, DataFrames

include("Components.jl")
include("Clock.jl")
include("Logger.jl")

export  Logger, switch!, setup!, init!, record!, clear!,  # Logger.jl
        Clock, SimFunction, now, sample_time!, event!, sample!,                # Clock.jl
        incr!, run!, stop!, resume!,
        Timing, at, after, every, before

Random.seed!(123)

end # module
