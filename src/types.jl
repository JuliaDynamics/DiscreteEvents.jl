#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

"supertype for clocks in `DiscreteEvents.jl`"
abstract type AbstractClock end

"supertype for events"
abstract type AbstractEvent end

# abstract types for clock state machines
abstract type ClockState end
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
    Action

An action is either  a `Function` or an `Expr` or a `Tuple` of them. It can
be scheduled in an event for later execution.

!!! warning "Evaluating expressions is slow"
    Expr should be avoided in time critical parts of applications. You will get a one
    time warning if you use them. They can be replaced easily by `fun`s or function
    closures. They are evaluated at global scope in Module `Main` only. Other modules using
    `DiscreteEvents.jl` cannot use Expr in events and have to use functions.
"""
const Action = Union{Function, Expr, Tuple}

"""
    DiscreteEvent{T<:Action} <: AbstractEvent

A discrete event is an `Action` to be executed at an event time.

# Arguments, fields
- `ex::T`: a function or an expression or a tuple of them,
- `t::Float64`: event time,
- `Δt::Float64`: repeat rate with for repeating events.
"""
struct DiscreteEvent{T<:Action} <: AbstractEvent
    ex::T
    t::Float64
    Δt::Float64
end
DiscreteEvent(ex::T, t::Real, Δt::Real) where {T<:Action} =
    DiscreteEvent(ex, float(t), float(Δt))

"""
    DiscreteCond{S<:Action, T<:Action} <: AbstractEvent

A condition to be evaluated repeatedly with expressions or functions
to be executed if conditions are met.

# Arguments, fields
- `cond::S`: a conditional function or an expression or a tuple of them
    (conditions must evaluate to `Bool`),
- `ex::T`: a function or an expression or a tuple of them to be executed
    if conditions are met,
"""
struct DiscreteCond{S<:Action, T<:Action} <: AbstractEvent
    cond::S
    ex::T
end

"""
    Sample{T<:Action} <: AbstractEvent

Sampling actions are executed at sampling time.

# Arguments, fields
- `ex<:Action`: an [`Action`](@ref) to be executed at sample time.
"""
struct Sample{T<:Action} <: AbstractEvent
    ex::T
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
    Prc(id, f, arg...; kw...)

Prepare a function to run as a process (asynchronous task) in a simulation.

# Arguments, fields
- `id`: some unique identification for registration,
- `f::Function`: a function `f(clk, arg...; kw...)`, must take `clk` (a [`Clock`](@ref))
    as its first argument,
- `arg...`: further arguments to `f`
- `kw...`: keyword arguments to `f`

# Fields
- `task::Union{Task,Nothing}`: a task structure,
- `clk::Union{AbstractClock,Nothing}`: clock where the process is registered,
- `state::ClockState`: process state,

!!! note
    A function started as a Prc runs in a loop. It has to give back control
    by e.g. doing a `take!(input)` or by calling [`delay!`](@ref) or [`wait!`](@ref),
    which will `yield` it. Otherwise it will starve everything else!
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
    load::Int
end

"""
```
Clock(Δt::T=0; t0::U=0, unit::FreeUnits=NoUnits) where {T<:Number,U<:Number}
```
Create a new simulation clock.

# Arguments
- `Δt::T=0`: time increment. If no Δt is given, the simulation doesn't tick,
    but jumps from event to event. Δt can be set later with `sample_time!`.
- `t0::U=0`: start time for simulation
- `unit::FreeUnits=NoUnits`: clock time unit. Units can be set explicitely by
    setting e.g. `unit=minute` or implicitly by giving Δt as a time or else setting
    t0 to a time, e.g. `t0=60s`.

# Fields
- `id::Int`: clock ident number, 0: master clock, ≥ 1: parallel clock,
- `state::ClockState`: clock state,
- `time::Float64`: clock time,
- `unit::FreeUnits`: time unit,
- `end_time::Float64`: end time for simulation,
- `Δt::Float64`: sampling time, timestep between ticks,
- `ac::Vector{ClockChannel}`: [`channels`](@ref ClockChannel) to active clocks on parallel threads,
- `sc::Schedule`: the clock [`Schedule`](@ref) (events, cond events and sampling),
- `processes::Dict{Any, Prc}`: registered `Prc`es,
- `tn::Float64`: next timestep,
- `tev::Float64`: next event time,
- `evcount::Int`: event counter,
- `scount::Int`: sample counter

# Examples

```jldoctest
julia> using DiscreteEvents, Unitful

julia> import Unitful: s, minute, hr

julia> c = Clock()                 # create a unitless clock (standard)
Clock 0, thrd 1 (+ 0 ac): state=DiscreteEvents.Undefined(), t=0.0 , Δt=0.0 , prc:0
  scheduled ev:0, cev:0, sampl:0

julia> c1 = Clock(1s, unit=minute)  # create a clock with unit [minute]
Clock 0, thrd 1 (+ 0 ac): state=DiscreteEvents.Undefined(), t=0.0 minute, Δt=0.01667 minute, prc:0
  scheduled ev:0, cev:0, sampl:0

julia> c2 = Clock(1s)               # create a clock with implicit unit [s]
Clock 0, thrd 1 (+ 0 ac): state=DiscreteEvents.Undefined(), t=0.0 s, Δt=1.0 s, prc:0
  scheduled ev:0, cev:0, sampl:0

julia> c3 = Clock(t0=60s)           # another clock with implicit unit [s]
Clock 0, thrd 1 (+ 0 ac): state=DiscreteEvents.Undefined(), t=60.0 s, Δt=0.0 s, prc:0
  scheduled ev:0, cev:0, sampl:0

julia> c4 = Clock(1s, t0=1hr)       # here Δt's unit [s] takes precedence
Clock 0, thrd 1 (+ 0 ac): state=DiscreteEvents.Undefined(), t=3600.0 s, Δt=1.0 s, prc:0
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

    function Clock(Δt::T=0;
                   t0::U=0, unit::FreeUnits=NoUnits) where {T<:Number,U<:Number}
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
    ActiveClock{E <: ClockEvent} <: AbstractClock

A thread specific clock which can be operated via a channel.

# Fields
- `clock::Clock`: the thread specific clock,
- `master::Ref{Clock}`: a pointer to the master clock (on thread 1),
- `cmd::Channel{E}`: the command channel from master,
- `ans::Channel{E}`: the response channel to master.
- `id::Int`: the id in master's ac array,
- `thread::Int`: the thread, the active clock runs on.

!!! note
You should not setup an `ActiveClock` explicitly. Rather this is done
implicitly by [`fork!`](@ref)ing a [`Clock`](@ref) to other available threads
or directly with [`PClock`](@ref).
It then can be accessed via [`pclock`](@ref) as in the following example.

!!! note
Directly accessing the `clock`-field of parallel `ActiveClock`s in simulations is
possible but not recommended since it breaks parallel operation. The right way is
to pass `event!`s to the `ActiveClock`-variable. The communication then happens
over the channel to the `ActiveClock` as it should be.

# Example
```jldoctest; filter = r"^.*[0-9]+ ac.*"
julia> using DiscreteEvents

julia> clk = Clock()
Clock 0, thrd 1 (+ 0 ac): state=DiscreteEvents.Undefined(), t=0.0 , Δt=0.0 , prc:0
  scheduled ev:0, cev:0, sampl:0

julia> fork!(clk)

julia> clk    #  ⬇ here you got 3 parallel active clocks
Clock 0, thrd 1 (+ 3 ac): state=DiscreteEvents.Undefined(), t=0.0 , Δt=0.0 , prc:0
  scheduled ev:0, cev:0, sampl:0


julia> clk = PClock()
Clock 0, thrd 1 (+ 3 ac): state=DiscreteEvents.Undefined(), t=0.0 , Δt=0.01 , prc:0
  scheduled ev:0, cev:0, sampl:0

julia> ac1 = pclock(clk, 1)    # get access to the 1st active clock (on thread 2)
Active clock 1 on thrd 2: state=DiscreteEvents.Idle(), t=0.0 , Δt=0.01 , prc:0
   scheduled ev:0, cev:0, sampl:0
```
"""
mutable struct ActiveClock{E <: ClockEvent} <: AbstractClock
    clock::Clock
    master::Ref{Clock}
    forth::Channel{E}
    back ::Channel{E}
    id::Int
    thread::Int
end

"""
    RTClock{E <: ClockEvent} <: AbstractClock

A real time clock checks every given period for scheduled events and executes them. It has a
time in seconds since its start or last reset and uses system time for updating.

Real time clocks are controlled over channels. Multiple real time clocks can be setup with
arbitrary periods (≥ 1 ms). Real time clocks should not be created directly but rather with
`CreateRTClock`.

# Fields
- `Timer::Timer`:     clock period in seconds, minimum is 0.001 (1 ms)
- `clock::Clock`:     clock work
- `cmd::Channel{T}`:  command channel to asynchronous clock
- `back::Channel{T}`: back channel from async clock
- `id::Int`:          arbitrary id number
- `thread::Int`:      thread the async clock is living in
- `time::Float64`:    clock time since start in seconds
- `t0::Float64`:      system time at clock start in seconds
- `T::Float64`:       clock period in seconds
"""
mutable struct RTClock{E <: ClockEvent} <: AbstractClock
    Timer::Timer
    clock::Clock
    cmd::Channel{E}
    back::Channel{E}
    id::Int
    thread::Int
    time::Float64
    t0::Float64
    T::Float64
end
