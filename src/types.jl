#
# types for Simulate.jl
#

"""
    Timing

Enumeration type for scheduling events and timed conditions:

- `at`: schedule an event at a given time
- `after`: schedule an event a given time after current time
- `every`: schedule an event every given time from now on
- `before`: a timed condition is true before a given time.
"""
@enum Timing at after every before

"""
    SimFunction(func::Function, arg...; kw...)

Type for preparing a function as an event to a simulation.

# Arguments
- `func::Function`: function to be executed at a later simulation time
- `arg...`: arguments to the function
- `kw...`: keyword arguments

Be aware that, if the variables stored in a SimFunction are composite types,
they can change until they are evaluated later by `func`. But that's the nature
of simulation.

# Example
```jldoctest
julia> using Simulate

julia> f(a,b,c; d=4, e=5) = a+b+c+d+e  # define a function
f (generic function with 1 method)

julia> sf = SimFunction(f, 10, 20, 30, d=14, e=15)  # store it as SimFunction
SimFunction(f, (10, 20, 30), Base.Iterators.Pairs(:d => 14,:e => 15))

julia> sf.func(sf.arg...; sf.kw...)  # and it can be executed later
89

julia> d = Dict(:a => 1, :b => 2) # now we set up a dictionary
Dict{Symbol,Int64} with 2 entries:
  :a => 1
  :b => 2

julia> f(t) = t[:a] + t[:b] # and a function adding :a and :b
f (generic function with 2 methods)

julia> f(d)  # our add function gives 3
3

julia> ff = SimFunction(f, d)   # we set up a SimFunction
SimFunction(f, (Dict(:a => 1,:b => 2),), Base.Iterators.Pairs{Union{},Union{},Tuple{},NamedTuple{(),Tuple{}}}())

julia> d[:a] = 10  # later somehow we need to change d
10

julia> ff  # our SimFunction ff has changed too
SimFunction(f, (Dict(:a => 10,:b => 2),), Base.Iterators.Pairs{Union{},Union{},Tuple{},NamedTuple{(),Tuple{}}}())

julia> ff.func(ff.arg...; ff.kw...)  # and calling it gives a different result
12
```
"""
struct SimFunction
    func::Function
    arg::Tuple
    kw::Base.Iterators.Pairs

    SimFunction(func, arg...; kw...) = new(func, arg, kw)
end

"""
    SimEvent(expr::Expr, scope::Module, t::Float64, Δt::Float64)

Create a simulation event: an expression to be executed at event time.

# Arguments
- `expr::Expr`: expression to be evaluated at event time
- `scope::Module`: evaluation scope
- `t::Float64`: event time
- `Δt::Float64`: repeat rate with which the event gets repeated
"""
struct SimEvent
    "expression to be evaluated at event time"
    ex::Union{Expr, SimFunction}
    "evaluation scope"
    scope::Module
    "event time"
    t::Float64
    "repeat time"
    Δt::Float64
end

"""
    Sample(ex::Union{Expr, SimFunction}, scope::Module)

Create a sampling expression.

# Arguments
- `ex::{Expr, SimFunction}`: expression or function to be called at sample time
- `scope::Module`: evaluation scope
"""
struct Sample
    "expression or function to be called at sample time"
    ex::Union{Expr, SimFunction}
    "evaluation scope"
    scope::Module
end

"""
    SimException(ev::SEvent, value=nothing)

Define a SimException, which can be thrown to processes.

# Parameters
- `ev::SEvent`: delivers an event to the interrupted task
- `value=nothing`: deliver some other value
"""
struct SimException <: Exception
  ev::Any
  value::Any
  SimException(ev::SEvent, value=nothing) = new(ev, value)
end


"""
```
SimProcess( id, func::Function, body,
            in::Channel=Channel(Inf), out::Channel=Channel(Inf),
            arg...; kw...) =
```
Prepare a function to run as a process in a simulation.

# Arguments
- `id`: some unique identification
- `func::Function`: a function `f(in::Channel, out::Channel, arg...; kw...)`
- `in::Channel=Channel(Inf)`: `f`s input channel
- `out::Channel=Channel(Inf)`: `f`s output channel
- `arg...`: further arguments to `f`
- `kw...`: keyword arguments to `f`

**Note:** A function `f` running as a SimProcess is put in a loop. So it has to
give back control by e.g. doing a `take!(in)` on its input channel or by calling
`delay!` etc., which will `yield` it. Otherwise it will after start starve
everything else!

#Examples
```jldoctest
```
"""
mutable struct SimProcess
    id
    task
    state::SState
    func::Function
    in::Channel
    out::Channel
    arg::Tuple
    kw::Base.Iterators.Pairs

    SimProcess( id, func::Function,
                in::Channel=Channel(Inf), out::Channel=Channel(Inf),
                arg...; kw...) =
        new(id, nothing, Undefined(), func, in, out, arg, kw)
end


"""
```
Clock(Δt::Number=0; t0::Number=0, unit::FreeUnits=NoUnits)
```
Create a new simulation clock.

# Arguments
- `Δt::Number=0`: time increment
- `t0::Number=0`: start time for simulation
- `unit::FreeUnits=NoUnits`: clock time unit. Units can be set explicitely by
setting e.g. `unit=minute` or implicitly by giving Δt as a time or else setting
t0 to a time, e.g. `t0=60s`.

If no Δt is given, the simulation doesn't tick, but jumps from event to event.
Δt can be set later with `sample_time!`.

# Examples
```jldoctest
julia> using Simulate, Unitful

julia> import Unitful: s, minute, hr

julia> c = Clock()
Clock: state=Simulate.Undefined(), time=0.0, unit=, events: 0, processes: 0, sampling: 0, sample rate Δt=0.0
julia> init!(c)
Simulate.Idle()
julia> c = Clock(1s, unit=minute)
Clock: state=Simulate.Undefined(), time=0.0, unit=minute, events: 0, processes: 0, sampling: 0, sample rate Δt=0.016666666666666666
julia> c = Clock(1s)
Clock: state=Simulate.Undefined(), time=0.0, unit=s, events: 0, processes: 0, sampling: 0, sample rate Δt=1.0
julia> c = Clock(t0=60s)
Clock: state=Simulate.Undefined(), time=60.0, unit=s, events: 0, processes: 0, sampling: 0, sample rate Δt=0.0
julia> c = Clock(1s, t0=1hr)
Clock: state=Simulate.Undefined(), time=3600.0, unit=s, events: 0, processes: 0, sampling: 0, sample rate Δt=1.0
```
"""
mutable struct Clock <: SEngine
    "clock state"
    state::SState
    "clock time"
    time::Float64
    "time unit"
    unit::FreeUnits
    "scheduled events"
    events::PriorityQueue{SimEvent,Float64}
    "registered processes"
    processes::Dict{Any, SimProcess}
    "end time for simulation"
    end_time::Float64
    "event evcount"
    evcount::Int64
    "next event time"
    tev::Float64

    "sampling time, timestep between ticks"
    Δt::Float64
    "Array of sampling expressions to evaluate at each tick"
    sexpr::Array{Sample}
    "next sample time"
    tsa::Float64

    function Clock(Δt::Number=0;
                   t0::Number=0, unit::FreeUnits=NoUnits)
        if isa(1unit, Time)
            Δt = isa(Δt, Time) ? uconvert(unit, Δt).val : Δt
            t0 = isa(t0, Time) ? uconvert(unit, t0).val : t0
        elseif isa(Δt, Time)
            unit = Unitful.unit(Δt)
            t0 = isa(t0, Time) ? uconvert(unit, t0).val : t0
            Δt = Δt.val
        elseif isa(t0, Time)
            unit = Unitful.unit(t0)
            t0 = t0.val
        else
            nothing
        end
        new(Undefined(), t0, unit, PriorityQueue{SimEvent,Float64}(),
            Dict{Any, SimProcess}(), t0, 0, t0, Δt, Sample[], t0 + Δt)
    end
end

function show(io::IO, sim::Clock)
    s1::String = "Clock: "
    s2::String = "state=$(sim.state), "
    s3::String = "time=$(sim.time), "
    s4::String = "unit=$(sim.unit), "
    s5::String = "events: $(length(sim.events)), "
    s6::String = "processes: $(length(sim.processes)), "
    s7::String = "sampling: $(length(sim.sexpr)), "
    s8::String = "sample rate Δt=$(sim.Δt)"
    print(io, s1 * s2 * s3 * s4 * s5 * s6 * s7 * s8)
end
