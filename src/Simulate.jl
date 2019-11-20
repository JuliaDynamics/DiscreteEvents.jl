
"""
    Simulate

A Julia package for discrete event simulation based on state machines.
"""
module Simulate

using Unitful, Random, DataStructures, DataFrames
import Unitful: FreeUnits, Time
import Base.show

include("components.jl")
include("types.jl")
include("clock.jl")
include("process.jl")
include("utils.jl")
include("logger.jl")


export  Logger, switch!, setup!, init!, record!, clear!,
        Clock, setUnit!, SimExpr, SimFunction, SF, @SF,
        𝐶, Clk, Timing, at, after, every, before, until,
        tau, τ, @tau, sample_time!, event!, sample!, val, @val,
        incr!, run!, stop!, resume!, reset!, sync!,
        SimProcess, SP, @SP, process!, interrupt!, delay!, wait!, now!


Random.seed!(123)
𝐶.state == Undefined() ? init!(𝐶) : nothing

end # module
