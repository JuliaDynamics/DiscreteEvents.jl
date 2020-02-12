#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

"a state machine is undefined (after creation)"
struct Undefined <: ClockState end

"a state machine is idle"
struct Idle <: ClockState end

"a state machine is empty"
struct Empty <: ClockState end

"a state machine is busy"
struct Busy <: ClockState end

"a state machine is halted"
struct Halted <: ClockState end

"`Init(info)`: Init event with some info."
struct Init <: ClockEvent
    info::Any
end

"`Setup(vars::Array{Symbol,1}, scope::Module)`: setup a logger with some info."
struct Setup <: ClockEvent
    vars::Array{Symbol,1}
    scope::Module
end

"`Step()`: command"
struct Step <: ClockEvent end

"`Run()`: command"
struct Run <: ClockEvent
    duration::Float64
end

"`Register()`: command from master to an active clock."
struct Register{T <: Union{DiscreteEvent,DiscreteCond,Sample}} <: ClockEvent
    x::T
end

"`Forward()`: forward an event or sample from an active clock to master"
struct Forward{T <: Union{DiscreteEvent,DiscreteCond,Sample}} <: ClockEvent
    x::T
    id::Int
end

"`Sync()`: event for syncing of parallel clocks"
struct Sync <: ClockEvent end

"`Start()`: event used for transferring start data to an active clock"
struct Start <: ClockEvent
    x::Any
end

"`Stop()`: command"
struct Stop <: ClockEvent end

"`Resume()`: command"
struct Resume <: ClockEvent end

"`Clear()`: command"
struct Clear <: ClockEvent end

"`Query()`: command, causes an active clock to send its clock data."
struct Query <: ClockEvent end

"`Diag()`: command, causes an active clock to send the last stacktrace."
struct Diag <: ClockEvent end

"`Reset()`: command"
struct Reset <: ClockEvent
    type::Bool
end

"`Response()`: response from an active clock"
struct Response <: ClockEvent
    x::Any
end

"`Done()`: event from an active clock containing the elapsed time in ns"
struct Done <: ClockEvent
    t::UInt
end

"""
    step!(A::AbstractClock, q::ClockState, σ::ClockEvent)

Default transition for clocks, called for undefined transitions.

# Arguments
- `A::AbstractClock`: state machine for which a transition is called
- `q::ClockState`:  state of the state machine
- `σ::ClockEvent`:  event, triggering the transition
"""
function step!(A::AbstractClock, q::ClockState, σ::ClockEvent)
    println(stderr, "Warning: undefined transition ",
            "$(typeof(A)), ::$(typeof(q)), ::$(typeof(σ)))")
end
