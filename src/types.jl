#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

"supertype for clocks in `Simulate.jl`"
abstract type AbstractClock end

"supertype for events"
abstract type AbstractEvent end

"supertype for clock states"
abstract type ClockState end

"supertype for clock events"
abstract type ClockEvent end

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
Fun(f::Function, arg...; kw...)
```
Store a function and its arguments for being called later as an event.

# Arguments, fields
- `f::Function`:  event function to be executed at event time,
- `arg...`: arguments to the event function,
- `kw...`: keyword arguments to the event function.

Arguments and keyword arguments can be 1) values or variables mixed with 2) symbols,
expressions or even other functions. In the 2nd cases they are evaluated at
event time before they are passed to the event function.

!!! note
    Composite types or variables given symbolically can change until they
    are evaluated later at event time.

# Examples
```jldoctest
julia> using Simulate

julia> f(a,b,c; d=4, e=5) = a+b+c+d+e       # if you define a function and ...
f (generic function with 1 method)

julia> sf = Fun(f, 10, 20, 30, d=14, e=15);  # store it as Fun

julia> sf.f(sf.arg...; sf.kw...)         # it can be executed later
89

julia> d = Dict(:a => 1, :b => 2);          # we set up a dictionary

julia> g(t) = t[:a] + t[:b]                 # and a function adding :a and :b
g (generic function with 1 method)

julia> g(d)                                 # our add function gives 3
3

julia> ff = Fun(g, d);              # we set up a Fun

julia> d[:a] = 10;                          # later somehow we change d

julia> ff.f(ff.arg...)                   # calling ff then gives a different result
12
```
"""
struct Fun
    f::Function
    arg::Union{Nothing, Tuple}
    kw::Union{Nothing, Base.Iterators.Pairs}

    Fun(f::Function, arg...; kw...) =
        new(f, ifelse(isempty(arg), nothing, arg), ifelse(isempty(kw), nothing, kw))
end

"An action is either an `Expr` or a `Fun` or a `Tuple` of them."
const Action = Union{Expr, Fun, Tuple}

"""
```
DiscreteEvent{T<:Action}
```
A discrete event is a function or an expression or a tuple of them to be
executed at an event time.

# Arguments, fields
- `ex::T`: a function or an expression or a tuple of them,
- `scope::Module`: evaluation scope,
- `t::Float64`: event time,
- `Δt::Float64`: repeat rate with for repeating events.
"""
struct DiscreteEvent{T<:Action} <: AbstractEvent
    ex::T
    scope::Module
    t::Float64
    Δt::Float64
end
DiscreteEvent(ex::T, scope::Module, t::Real, Δt::Real) where {T<:Action} =
    DiscreteEvent(ex, scope, float(t), float(Δt))

"""
```
DiscreteCond{S<:Action, T<:Action}
```
A condition to be evaluated repeatedly with expressions or functions
to be executed if conditions are met.

# Arguments, fields
- `cond::S`: a conditional function or an expression or a tuple of them
    (conditions must evaluate to `Bool`),
- `ex::T`: a function or an expression or a tuple of them to be executed
    if conditions are met,
- `scope::Module`: evaluation scope
"""
struct DiscreteCond{S<:Action, T<:Action} <: AbstractEvent
    cond::S
    ex::T
    scope::Module
end

"""
    Sample{T<:Union{Fun,Expr}}

A sampling function or expression is called at sampling time.

# Arguments, fields
- `ex::T`: expression or function to be called at sample time,
- `scope::Module`: evaluation scope.
"""
struct Sample{T<:Union{Fun,Expr}} <: AbstractEvent
    ex::T
    scope::Module
end

"""
    ClockException(ev::ClockEvent, value=nothing)

Define a ClockException, which can be thrown to processes.

# Arguments, fields
- `ev::ClockEvent`: delivers an event to the interrupted task
- `value=nothing`: deliver some other value
"""
struct ClockException <: Exception
  ev::ClockEvent
  value::Any
  ClockException(ev::ClockEvent, value=nothing) = new(ev, value)
end

"""
```
Prc( id, f::Function, arg...; kw...)
alias   SP( id, f::Function, arg...; kw...)
```
Prepare a function to run as a process in a simulation.

# Arguments, fields
- `id`: some unique identification for registration,
- `task::Union{Task,Nothing}`: a task structure,
- `clk::Union{AbstractClock,Nothing}`: clock where the process is registered,
- `state::ClockState`: process state,
- `f::Function`: a function `f(clk, arg...; kw...)`, must take `clk` as its
    first argument,
- `arg...`: further arguments to `f`
- `kw...`: keyword arguments to `f`

!!! note
    A function started as a Prc most often runs in a loop. It has to
    give back control by e.g. doing a `take!(input)` or by calling
    `delay!` etc., which will `yield` it. Otherwise it will starve everything else!

!!! warn
    That `f` nust take `clk` as first argument is a breaking change in v0.3!

# Examples
```jldoctest
julia> using Simulate

```
"""
mutable struct Prc
    id::Any
    task::Union{Task,Nothing}
    clk::Union{AbstractClock,Nothing}
    f::Function
    arg::Tuple
    kw::Base.Iterators.Pairs

    Prc( id, f::Function, arg...; kw...) = new(id, nothing, nothing, f, arg, kw)
end

"""
    Schedule()

A Schedule contains events, conditional events and sampling functions to be
executed or evaluated on the clock's time line.

# Fields
- `events::PriorityQueue{DiscreteEvent,Float64}`: scheduled events,
- `cevents::Array{DiscreteCond,1}`: conditional events to evaluate at each tick,
- `samples::Array{Sample,1}`: sampling expressions to evaluate at each tick,
"""
mutable struct Schedule
    events::PriorityQueue{DiscreteEvent,Float64}
    cevents::Array{DiscreteCond,1}
    samples::Array{Sample,1}

    Schedule() = new(PriorityQueue{DiscreteEvent,Float64}(), DiscreteCond[], Sample[])
end

"""
    ClockChannel

Provide a channel to an active clock or a real time clock.

# Fields
- `ref::Ref{Task}`: a pointer to an active clock,
- `ch::Channel`: a communication channel to an active clock,
- `id::Int`: the thread id of the active clock.
- `done::Bool`: flag indicating if the active clock has completed its cycle.
"""
mutable struct ClockChannel{T <: ClockEvent}
    ref::Ref{Task}
    forth::Channel{T}
    back::Channel{T}
    thread::Int
    done::Bool
end

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
- `id::Int`: thread on which the clock is running,
- `state::ClockState`: clock state,
- `time::Float64`: clock time,
- `unit::FreeUnits`: time unit,
- `end_time::Float64`: end time for simulation,
- `Δt::Float64`: sampling time, timestep between ticks,
- `ac::Vector{ClockChannel}`: active clocks running on parallel threads,
- `sc::Schedule`: the clock schedule (events, cond events and sampling),
- `processes::Dict{Any, Prc}`: registered `Prc`es,
- `tn::Float64`: next timestep,
- `tev::Float64`: next event time,
- `evcount::Int`: event counter,
- `scount::Int`: sample counter

# Examples

```jldoctest
julia> using Simulate, Unitful

julia> import Unitful: s, minute, hr

julia> c = Clock()                 # create a unitless clock (standard)
Clock thread 1 (+ 0 ac): state=Simulate.Undefined(), t=0.0 , Δt=0.0 , prc:0
  scheduled ev:0, cev:0, sampl:0

julia> c = Clock(1s, unit=minute)  # create a clock with units, does conversions automatically
Clock thread 1 (+ 0 ac): state=Simulate.Undefined(), t=0.0 minute, Δt=0.01667 minute, prc:0
  scheduled ev:0, cev:0, sampl:0

julia> c = Clock(1s)               # create a clock with implicit unit setting
Clock thread 1 (+ 0 ac): state=Simulate.Undefined(), t=0.0 s, Δt=1.0 s, prc:0
  scheduled ev:0, cev:0, sampl:0

julia> c = Clock(t0=60s)           # another example of implicit unit setting
Clock thread 1 (+ 0 ac): state=Simulate.Undefined(), t=60.0 s, Δt=0.0 s, prc:0
  scheduled ev:0, cev:0, sampl:0

julia> c = Clock(1s, t0=1hr)       # if given times with different units, Δt takes precedence
Clock thread 1 (+ 0 ac): state=Simulate.Undefined(), t=3600.0 s, Δt=1.0 s, prc:0
  scheduled ev:0, cev:0, sampl:0
```
"""
mutable struct Clock <: AbstractClock
    id::Int
    state::ClockState
    time::Float64
    unit::FreeUnits
    Δt::Float64
    ac::Vector{ClockChannel}
    sc::Schedule
    processes::Dict{Any, Prc}
    tn::Float64
    tev::Float64
    end_time::Float64
    evcount::Int
    scount::Int

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
        new(0, Undefined(), t0, unit, Δt, ClockChannel[], Schedule(),
            Dict{Any, Prc}(), t0 + Δt, t0, t0, 0, 0)
    end
end

"""
```
ActiveClock(clock::Clock, master::Ref{Clock},
            cmd::Channel{ClockEvent}, ans::Channel{ClockEvent})
```
A thread specific clock which can be operated via a channel.

# Fields
- `clock::Clock`: the thread specific clock,
- `master::Ref{Clock}`: a pointer to the master clock (on thread 1),
- `cmd::Channel{ClockEvent}`: the command channel from master,
- `ans::Channel{ClockEvent}`: the response channel to master.
- `id::Int`: the id in master's ac array,
- `thread::Int`: the thread, the active clock runs on.

!!! note
You should not setup an `ActiveClock` explicitly. Rather this is done
implicitly by [`fork!`](@ref)ing a [`Clock`](@ref) to other available threads
or directly with [`PClock`](@ref).
It then can be accessed via [`pclock`](@ref) as in the following example.

# Example
```jldoctest
julia> using Simulate

julia> clk = Clock()
Clock thread 1 (+ 0 ac): state=Simulate.Undefined(), t=0.0 , Δt=0.0 , prc:0
  scheduled ev:0, cev:0, sampl:0


julia> fork!(clk)

julia> clk    #  ⬇ you got 3 parallel active clocks
Clock thread 1 (+ 3 ac): state=Simulate.Undefined(), t=0.0 , Δt=0.0 , prc:0
  scheduled ev:0, cev:0, sampl:0


julia> clk = PClock()
Clock thread 1 (+ 3 ac): state=Simulate.Undefined(), t=0.0 , Δt=0.01 , prc:0
  scheduled ev:0, cev:0, sampl:0

julia> pclock(clk, 1)    # get access to the 1st active clock (on thread 2)
Active clock 1 on thrd 2: state=Simulate.Idle(), t=0.0 , Δt=0.01 , prc:0
   scheduled ev:0, cev:0, sampl:0
```
"""
mutable struct ActiveClock{T <: ClockEvent} <: AbstractClock
    clock::Clock
    master::Ref{Clock}
    forth::Channel{T}
    back ::Channel{T}
    id::Int
    thread::Int
end

"""
```
RTClock
```
Real time clocks use system time for time keeping and are controlled over
a channel. They are independent from each other and other clocks and run
asynchronously as tasks on arbitrary threads. Multiple real time clocks
can be setup with arbitrary frequencies to do different things.

# Fields
- `clock::Clock`:
- `cmd::Channel{T}`:
- `back::Channel{T}`:
- `id::Int`:
- `thread::Int`:
- `t0::Float64`:
"""
mutable struct RTClock{T <: ClockEvent} <: AbstractClock
    clock::Clock
    cmd::Channel{T}
    back::Channel{T}
    id::Int
    thread::Int
    t0::Float64
end
