#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

"""
    DiscreteEvents

A Julia package for generating and simulating discrete events. It runs on Julia
`VERSION ≥ v"1.0"`. Multithreading requires `VERSION ≥ v"1.3"`.

Its Github repo is [https://github.com/pbayer/DiscreteEvents.jl].

The current stable, registered version is installed with
```julia
pkg> add DiscreteEvents
```

The development version is installed with:
```julia
pkg> add("https://github.com/pbayer/DiscreteEvents.jl")
```
"""
module DiscreteEvents

"Gives the package version."
const version = v"0.3.3"

using Unitful, Random, DataStructures, Logging, .Threads, Distributions
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
include("resources.jl")
include("utils.jl")
include("macros.jl")

export  Clock, PClock, RTClock, setUnit!, 𝐶,
        Action, Timing, at, after, every, before, until,
        tau, sample_time!, fun, event!, periodic!, register!,
        incr!, run!, stop!, resume!, sync!, resetClock!,
        Prc, process!, interrupt!, delay!, wait!, now!,
        fork!, collapse!, pclock, diagnose, 
        createRTClock, stopRTClock, 
        PrcException, 
        Resource,
        onthread, pseed!,
        @process, @event, @periodic, @delay, @wait, @run!

Random.seed!(123)
rng = MersenneTwister(2020)
𝐶.state == Undefined() ? init!(𝐶) : nothing

end # module
