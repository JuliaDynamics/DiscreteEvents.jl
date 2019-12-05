#
# types for Simulate.jl
#

"""
    Timing

Enumeration type for scheduling events and timed conditions:

- `at`: schedule an event at a given time,
- `after`: schedule an event a given time after current time,
- `every`: schedule an event every given time from now on,
- `before`: a timed condition is true before a given time,
- `until`: delay until t.
"""
@enum Timing at after every before until

"""
```
SimFunction([emod::Module], efun::Function, arg...; kw...)
alias    SF([emod::Module], efun::Function, arg...; kw...)
```
Store a function and its arguments for being called later as an event.

# Arguments, fields
- `emod::Module`: evaluation scope for symbols or expressions given as arguments.
    If `emod` is not supplied, the evaluation scope is `Main`.
- `efun::Function`:  event function to be executed at event time,
- `arg...`: arguments to the event function,
- `kw...`: keyword arguments to the event function.

Arguments and keyword arguments can be 1) values or variables mixed with 2) symbols,
expressions or even other SimFunctions. In the 2nd cases they are evaluated at
event time before they are passed to the event function.

!!! note
    Composite types or variables given symbolically can change until they
    are evaluated later at event time.

# Examples
```jldoctest
julia> using Simulate

julia> f(a,b,c; d=4, e=5) = a+b+c+d+e       # if you define a function and ...
f (generic function with 1 method)

julia> sf = SF(f, 10, 20, 30, d=14, e=15);  # store it as SimFunction

julia> sf.efun(sf.arg...; sf.kw...)         # it can be executed later
89

julia> d = Dict(:a => 1, :b => 2);          # we set up a dictionary

julia> g(t) = t[:a] + t[:b]                 # and a function adding :a and :b
g (generic function with 1 method)

julia> g(d)                                 # our add function gives 3
3

julia> ff = SimFunction(g, d);              # we set up a SimFunction

julia> d[:a] = 10;                          # later somehow we change d

julia> ff.efun(ff.arg...)                   # calling ff then gives a different result
12
```
"""
struct SimFunction
    emod::Module
    efun::Function
    arg::Union{Nothing, Tuple}
    kw::Union{Nothing, Base.Iterators.Pairs}

    function SimFunction(emod::Module, efun::Function, arg...; kw...)
        !isempty(arg) || ( arg = nothing )
        !isempty(kw)  || ( kw  = nothing )
        new(emod, efun, arg, kw)
    end

    function SimFunction(efun::Function, arg...; kw...)
        !isempty(arg) || ( arg = nothing )
        !isempty(kw)  || ( kw  = nothing )
        new(Main, efun, arg, kw,)
    end
end
const SF = SimFunction

"""
    SimExpr = Union{Expr, SimFunction}

A type which is either a `SimFunction` or Julia expression, `Expr`-type.
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

# Arguments, fields
- `ex::Array{SimExpr, 1}`: an array of SimExpr to be evaluated at event time,
- `scope::Module`: evaluation scope,
- `t::Float64`: event time,
- `Δt::Float64`: repeat rate with which the event gets repeated.
"""
struct SimEvent
    ex::Array{SimExpr, 1}
    scope::Module
    t::Float64
    Δt::Float64

    SimEvent(ex::Array{SimExpr, 1}, scope::Module, t::Number, Δt::Number) =
        new(ex, scope, t, Δt)
end

"""
    SimCond(cond::Array{SimExpr, 1}, ex::Array{SimExpr, 1}, scope::Module)

Create a condition to be evaluated repeatedly with expressions or functions
to be executed if conditions are met.

# Arguments, fields
- `cond::Array{SimExpr, 1}`: Expr or SFs to be evaluated as conditions
- `ex::Array{SimExpr, 1}`: Expr or SFs to be evaluated if conditions are all true
- `scope::Module`: evaluation scope
"""
struct SimCond
    cond::Array{SimExpr, 1}
    ex::Array{SimExpr, 1}
    scope::Module
end

"""
    Sample(ex::SimExpr, scope::Module)

Create a sampling expression.

# Arguments, fields
- `ex::SimExpr`: expression or SimFunction to be called at sample time
- `scope::Module`: evaluation scope
"""
struct Sample
    ex::SimExpr
    scope::Module
end

"""
    SimException(ev::SEvent, value=nothing)

Define a SimException, which can be thrown to processes.

# Arguments, fields
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
SimProcess( id, func::Function, arg...; kw...)
SP(id, func::Function, arg...; kw...)
```
Prepare a function to run as a process in a simulation.

# Arguments, fields
- `id`: some unique identification, it should get registered with
- `func::Function`: a function `f(arg...; kw...)`
- `arg...`: further arguments to `f`
- `kw...`: keyword arguments to `f`

!!! note
    A function as a SimProcess most often runs in a loop. It has to
    give back control by e.g. doing a `take!(input)` or by calling
    `delay!` etc., which will `yield` it. Otherwise it will starve everything else!

# Examples
```jldoctest
julia> using Simulate

```
"""
mutable struct SimProcess
    id::Any
    task::Union{Task,Nothing}
    sim::Union{SEngine,Nothing}
    state::SState
    func::Function
    arg::Tuple
    kw::Base.Iterators.Pairs

    SimProcess( id, func::Function, arg...; kw...) =
        new(id, nothing, nothing, Undefined(), func, arg, kw)
end
const SP = SimProcess

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

# Fields
- `state::SState`: clock state
- `time::Float64`: clock time
- `unit::FreeUnits`: time unit
- `events::PriorityQueue{SimEvent,Float64}`: scheduled events
- `cevents::Array{SimCond,1}`: conditional events
- `processes::Dict{Any, SimProcess}`: registered processes
- `end_time::Float64`: end time for simulation
- `evcount::Int64`: event counter
- `scount::Int64`: sample count
- `tev::Float64`: next event time
- `Δt::Float64`: sampling time, timestep between ticks
- `sexpr::Array{Sample,1}`: sampling expressions to evaluate at each tick
- `tsa::Float64`: next sample time

# Examples
```jldoctest
julia> using Simulate, Unitful

julia> import Unitful: s, minute, hr

julia> c = Clock()                 # create a unitless clock (standard)
Clock: state=Simulate.Undefined(), time=0.0, unit=, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=0.0

julia> init!(c)                    # initialize it explicitly (normally done implicitly)
Simulate.Idle()

julia> c = Clock(1s, unit=minute)  # create a clock with units, does conversions automatically
Clock: state=Simulate.Undefined(), time=0.0, unit=minute, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=0.016666666666666666

julia> c = Clock(1s)               # create a clock with implicit unit setting
Clock: state=Simulate.Undefined(), time=0.0, unit=s, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=1.0

julia> c = Clock(t0=60s)           # another example of implicit unit setting
Clock: state=Simulate.Undefined(), time=60.0, unit=s, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=0.0

julia> c = Clock(1s, t0=1hr)       # if given times with different units, Δt takes precedence
Clock: state=Simulate.Undefined(), time=3600.0, unit=s, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=1.0
```
"""
mutable struct Clock <: SEngine
    state::SState
    time::Float64
    unit::FreeUnits
    events::PriorityQueue{SimEvent,Float64}
    cevents::Array{SimCond,1}
    processes::Dict{Any, SimProcess}
    end_time::Float64
    evcount::Int64
    scount::Int64
    tev::Float64
    Δt::Float64
    sexpr::Array{Sample,1}
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
            Dict{Any, SimProcess}(), t0, 0, 0, t0, Δt, Sample[],
            t0 + Δt)
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
