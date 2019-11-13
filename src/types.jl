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
```
SimFunction(func::Function, arg...; kw...)
𝐅(func::Function, arg...; kw...)
```
Prepare a function for being called as event in a simulation (𝐅 = \\bfF+tab).

# Arguments
- `func::Function`: function to be executed at a later simulation time
- `arg...`: arguments to the function
- `kw...`: keyword arguments

!!! note
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
const 𝐅 = SimFunction

"""
    SimExpr = Union{Expr, SimFunction}

A type which is either a `SimFunction` or any Julia expression `Expr`.
"""
SimExpr = Union{Expr, SimFunction}

"""
    sconvert(ex::Union{SimExpr,Array,Tuple})::Array{SimExpr,1}

convert a SimExpr or an array or a tuple of it to an Array{SimExpr,1}
"""
function sconvert(ex::Union{SimExpr,Array,Tuple})::Array{SimExpr,1}
    if isa(ex, SimExpr)
        return convert(Array{SimExpr,1}, [ex])
    elseif isa(ex, Array)
        return convert(Array{SimExpr,1}, ex)
    else
        return convert(Array{SimExpr,1}, [i for i in ex])
    end
end

"""
```
SimEvent(ex::Array{SimExpr, 1}, scope::Module, t::Float64, Δt::Float64)
```
Create a simulation event: a SimExpr or an array of SimExpr to be
executed at event time.

# Arguments
- `ex::Array{SimExpr, 1}`: an array of SimExpr to be evaluated at event time,
- `scope::Module`: evaluation scope,
- `t::Float64`: event time,
- `Δt::Float64`: repeat rate with which the event gets repeated.
"""
struct SimEvent
    "expression or SimFunction to be evaluated at event time"
    ex::Array{SimExpr, 1}
    "evaluation scope"
    scope::Module
    "event time"
    t::Float64
    "repeat time"
    Δt::Float64

    SimEvent(ex::Array{SimExpr, 1}, scope::Module, t::Number, Δt::Number) =
        new(ex, scope, t, Δt)
end

"""
    SimCond(cond::Array{SimExpr, 1}, ex::Array{SimExpr, 1}, scope::Module)

create a condition to be evaluated repeatedly with expressions or functions
to be executed if conditions are met.

# Arguments
- `cond::Array{SimExpr, 1}`: Expr or 𝐅s to be evaluated as conditions
- `ex::Array{SimExpr, 1}`: Expr or 𝐅s to be evaluated if conditions are all true
- `scope::Module`: evaluation scope
"""
struct SimCond
    "Expr or 𝐅s to be evaluated as conditions"
    cond::Array{SimExpr, 1}
    "Expr or 𝐅s to be evaluated if all conditions are True"
    ex::Array{SimExpr, 1}
    "evaluation scope"
    scope::Module
end

"""
    Sample(ex::SimExpr, scope::Module)

Create a sampling expression.

# Arguments
- `ex::SimExpr`: expression or SimFunction to be called at sample time
- `scope::Module`: evaluation scope
"""
struct Sample
    "expression or function to be called at sample time"
    ex::SimExpr
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
            input::Channel=Channel(Inf), output::Channel=Channel(Inf),
            arg...; kw...)
𝐏(id, func::Function, body,
  input::Channel=Channel(Inf), output::Channel=Channel(Inf), arg...; kw...)
```
Prepare a function to run as a process in a simulation (𝐏 = \\bfP+tab).

# Arguments
- `id`: some unique identification
- `func::Function`: a function `f(in::Channel, out::Channel, arg...; kw...)`
- `input::Channel=Channel(Inf)`: `f`s input channel
- `output::Channel=Channel(Inf)`: `f`s output channel
- `arg...`: further arguments to `f`
- `kw...`: keyword arguments to `f`

!!! note
    A function `f` running as a SimProcess is put in a loop. So it has to
    give back control by e.g. doing a `take!(input)` on its input channel or by calling
    `delay!` etc., which will `yield` it. Otherwise it will after start starve
    everything else!

# Examples
```jldoctest
```
"""
mutable struct SimProcess
    id
    task
    state::SState
    func::Function
    input::Channel
    output::Channel
    arg::Tuple
    kw::Base.Iterators.Pairs

    SimProcess( id, func::Function,
                input::Channel=Channel(Inf), output::Channel=Channel(Inf),
                arg...; kw...) =
        new(id, nothing, Undefined(), func, input, output, arg, kw)
end
const 𝐏 = SimProcess

"""
```
Clock(Δt::Number=0; t0::Number=0, unit::FreeUnits=NoUnits)
```
Create a new simulation clock.

# Arguments
- `Δt::Number=0`: time increment. If no Δt is given, the simulation doesn't tick,
    but jumps from event to event. Δt can be set later with `sample_time!`.
- `t0::Number=0`: start time for simulation
- `unit::FreeUnits=NoUnits`: clock time unit. Units can be set explicitely by
    setting e.g. `unit=minute` or implicitly by giving Δt as a time or else setting
    t0 to a time, e.g. `t0=60s`.

# Examples
```jldoctest
julia> using Simulate, Unitful

julia> import Unitful: s, minute, hr

julia> c = Clock()
Clock: state=Simulate.Undefined(), time=0.0, unit=, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=0.0
julia> init!(c)
Simulate.Idle()
julia> c = Clock(1s, unit=minute)
Clock: state=Simulate.Undefined(), time=0.0, unit=minute, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=0.016666666666666666
julia> c = Clock(1s)
Clock: state=Simulate.Undefined(), time=0.0, unit=s, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=1.0
julia> c = Clock(t0=60s)
Clock: state=Simulate.Undefined(), time=60.0, unit=s, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=0.0
julia> c = Clock(1s, t0=1hr)
Clock: state=Simulate.Undefined(), time=3600.0, unit=s, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=1.0
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
    "conditional events"
    cevents::Array{SimCond,1}
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
    sexpr::Array{Sample,1}
    "next sample time"
    tsa::Float64

    function Clock(Δt::Number=0;
                   t0::Number=0, unit::FreeUnits=NoUnits)
        if 1unit isa Time
            Δt = isa(Δt, Time) ? uconvert(unit, Δt).val : Δt
            t0 = isa(t0, Time) ? uconvert(unit, t0).val : t0
        elseif Δt isa Time
            unit = Unitful.unit(Δt)
            t0 = isa(t0, Time) ? uconvert(unit, t0).val : t0
            Δt = Δt.val
        elseif t0 isa Time
            unit = Unitful.unit(t0)
            t0 = t0.val
        else
            nothing
        end
        new(Undefined(), t0, unit, PriorityQueue{SimEvent,Float64}(), SimCond[],
            Dict{Any, SimProcess}(), t0, 0, t0, Δt, Sample[], t0 + Δt)
    end
end

function show(io::IO, sim::Clock)
    s1::String = "Clock: "
    s2::String = "state=$(sim.state), "
    s3::String = "time=$(sim.time), "
    s4::String = "unit=$(sim.unit), "
    s5::String = "events: $(length(sim.events)), "
    s6::String = "cevents: $(length(sim.cevents)), "
    s7::String = "processes: $(length(sim.processes)), "
    s8::String = "sampling: $(length(sim.sexpr)), "
    s9::String = "sample rate Δt=$(sim.Δt)"
    print(io, s1 * s2 * s3 * s4 * s5 * s6 * s7 * s8 * s9)
end
