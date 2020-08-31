#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

"Supertype for clocks."
abstract type AbstractClock end

"Supertype for events."
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

An action is either  a `Function` or an `Expr` or a `Tuple` of them. 
It can be scheduled in an event for later execution.
"""
const Action = Union{Function, Expr, Tuple{Vararg{Union{Function, Expr}}}}
# const Action = Union{Function, Expr, Tuple}

"""
````
DiscreteEvent{T<:Action, X} <: AbstractEvent
```
A discrete event is an [`Action`](@ref) to be executed at an event time.

# Arguments, fields
- `ex::T`: a function or an expression or a tuple of them,
- `t::Float64`: event time,
- `Δt::X`: repeat interval (Float64, Distribution or Nothing),
- `n::Int`: number of repeats.
"""
struct DiscreteEvent{T<:Action, X} <: AbstractEvent
    ex::T
    t::Float64
    Δt::X
    n::Int
end

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
    PrcException(ev, value)

An exception to be thrown at processes.

# Arguments, fields
- `event`: deliver an event to the interrupted task
- `value`: deliver some other value
"""
struct PrcException{U,V} <: Exception
  event::U
  value::V
end

"""
    Prc(id, f, arg...; kw...)

Prepare a function to run as a process registered to a clock.

# Arguments, fields
- `id`: some unique identification for registration,
- `f::Function`: a function `f(clk, arg...; kw...)`, must take `clk` 
    (a [`Clock`](@ref)) as its first argument,
- `arg...`: further arguments to `f`
- `kw...`: keyword arguments to `f`

# Fields
- `task::Union{Task,Nothing}`: a task structure,
- `clk::Union{AbstractClock,Nothing}`: clock where the process is registered,
- `state::ClockState`: process state,
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

A schedule contains events, conditional events and sampling functions 
to be executed or evaluated on the clock's time line.

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
    ClockChannel{T <: ClockEvent}

Provide a message channel to an active clock or a real time clock.

# Fields
- `ref::Ref{Task}`: a reference to an active clock task, useful for diagnosis,
- `forth::Channel{T}`: a communication channel to an active clock,
- `back::Channel{T}`: response channel from the active clock,
- `thread::Int`: the thread id of the active clock,
- `done::Bool`: flag indicating if the active clock has completed its cycle,
- `load::Int`: internal flag.
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
    Clock{AC} <: AbstractClock

A virtual clock structure, used for global and thread local clocks.

# Fields
- `id::Int`: clock ident number 1: master clock, > 1: parallel clock,
- `ac::AC`: if id == 1: a [`Vector{ClockChannel}`](@ref ClockChannel) else: [`Ref{ActiveClock}`](@ref ActiveClock),
- `state::ClockState`: clock state,
- `time::Float64`: clock time,
- `unit::FreeUnits`: time unit,
- `end_time::Float64`: end time for simulation,
- `Δt::Float64`: sampling time, timestep between ticks,
- `sc::Schedule`: the clock [`Schedule`](@ref) (events, cond events and sampling),
- `processes::Dict{Any, Prc}`: registered `Prc`es,
- `channels::Vector{Channel}`: registered (Actor) channels,
- `tn::Float64`: next timestep,
- `tev::Float64`: next event time,
- `evcount::Int`: event counter,
- `scount::Int`: sample counter
"""
mutable struct Clock{AC} <: AbstractClock
    id::Int
    ac::AC
    state::ClockState
    time::Float64
    unit::FreeUnits
    Δt::Float64
    sc::Schedule
    processes::Dict{Any, Prc}
    channels::Vector{Channel}
    tn::Float64
    tev::Float64
    end_time::Float64
    evcount::Int
    scount::Int
end

"Global clock with vector of active clocks."
const GlobalClock = Clock{Vector{ClockChannel}}

"""
```
Clock(Δt::T=0.01; t0::U=0, unit::FreeUnits=NoUnits) where {T<:Number,U<:Number}
```
Create a new virtual clock.

# Arguments
- `Δt::T=0.01`: time increment for sampling. Δt can be set later with `sample_time!`.
- `t0::U=0`: start time for simulation
- `unit::FreeUnits=NoUnits`: clock time unit. Units can be set explicitely by
    setting e.g. `unit=minute` or implicitly by giving Δt as a time or else setting
    t0 to a time, e.g. `t0=60s`.

The created clock has id==1 (master).
"""
function Clock(Δt::T=0.01;
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
    GlobalClock(1, ClockChannel[], Idle(), 
        t0, unit, Δt, Schedule(), Dict{Any, Prc}(), Channel[], 
        t0 + Δt, t0, t0, 0, 0)
end

"""
    ActiveClock{E <: ClockEvent} <: AbstractClock

An active clock is a wrapper around a local [`Clock`](@ref) on a 
parallel thread. It is operated by a thread local task. The master 
clock on thread 1 communicates with it through messages over its
channels. 

# Fields
- `clock::Clock`: the thread specific local clock,
- `master::Ref{Clock}`: a pointer to the master clock (on thread 1),
- `forth::Channel{E}`: the command channel from master,
- `back::Channel{E}`: the response channel to master,
- `id::Int`: the clocks id/thread number,
- `task::Task`: the active clock`s task.

!!! note "Don't setup an active clock explicitly!"

    It is done implicitly with [`PClock`](@ref) or by [`fork!`](@ref)ing 
    a [`Clock`](@ref) to other available threads.

On a parallel thread tasks can access their local clock with 
[`pclock(clk)`](@ref pclock). Then they can schedule 'thread local' 
events, `delay!` or `wait!` on it.

!!! note "Don't share active clocks between threads!"

    In multithreading we communicate over channels and don't want 
    to share variables between threads. A user can still access 
    active clocks for diagnostic purposes.
"""
mutable struct ActiveClock{E <: ClockEvent} <: AbstractClock
    clock::Clock
    master::Ref{Clock{Vector{ClockChannel}}}
    forth::Channel{E}
    back ::Channel{E}
    id::Int
    task::Task
end

"Local clock with reference to a wrapping active clock."
const LocalClock = Clock{Ref{ActiveClock{ClockEvent}}}

"""
    localClock(c::Clock)

Create a thread local clock with an undefined reference to an
active clock which inherits parameters of the master clock `c`.
"""
function localClock(c::Clock)
    LocalClock(threadid(), 
        Ref{ActiveClock{ClockEvent}}(), Idle(),
        c.time, c.unit, c.Δt, Schedule(), Dict{Any, Prc}(), Channel[],
        c.time + c.Δt, c.time, c.time, 0, 0)
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
    task::Task
end
