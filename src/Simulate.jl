
"""
    Simulate

A Julia package for discrete event simulation based on state machines.
"""
module Simulate

using Unitful, Random, DataStructures, DataFrames
import Unitful: FreeUnits, Time
import Base.show

include("components.jl")
include("clock.jl")
include("logger.jl")


export  Logger, switch!, setup!, init!, record!, clear!,    # Logger.jl
        Clock, setUnit!, SimFunction, τ, tau,                # Clock.jl
        sample_time!, event!, sample!,
        incr!, run!, stop!, resume!, reset!, sync!,
        𝐶, Clk, Timing, at, after, every, before

Random.seed!(123)
𝐶.state == Undefined() ? init!(𝐶) : nothing

end # module
