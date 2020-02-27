#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

"""
```
Simulate
```
A Julia package for discrete event simulation.

The current stable, registered version is installed with
```julia
pkg> add Simulate
```

The development version is installed with:
```julia
pkg> add("https://github.com/pbayer/Simulate.jl")
```
"""
module Simulate

"""
    version

Gives the package version:

```jldoctest
julia> using Simulate

julia> Simulate.version
v"0.3.0"
```
"""
const version = v"0.3.0"

using Unitful, Random, DataStructures, Logging, .Threads
import Unitful: FreeUnits, Time

include("types.jl")
include("components.jl")
include("fclosure.jl")
include("schedule.jl")
include("events.jl")
include("clock.jl")
include("process.jl")
include("threads.jl")
include("timer.jl")
include("printing.jl")

export  Clock, ActiveClock, RTClock, RTC, setUnit!, 𝐶,
        Timing, at, after, every, before, until, tau, sample_time!,
        Action, fun, event!, periodic!,
        incr!, run!, stop!, resume!, reset!, sync!,
        Prc, process!, interrupt!, delay!, wait!, now!,
        PClock, fork!, collapse!, pclock, diagnose, onthread


Random.seed!(123)
rng = MersenneTwister(2020)
𝐶.state == Undefined() ? init!(𝐶) : nothing

end # module
