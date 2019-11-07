# Define components for simulation and logging machines
# -------------------------------------------------------
# I choose Sim.jl to be self sufficient and not to depend
# on StateMachines.jl.
#

"supertype for state machines in `Sim.jl`"
abstract type SEngine end

"supertype for states"
abstract type SState end

"supertype for events"
abstract type SEvent end

"a state machine is undefined (after creation)"
struct Undefined <: SState end

"a state machine is idle"
struct Idle <: SState end

"a state machine is empty"
struct Empty <: SState end

"a state machine is busy"
struct Busy <: SState end

"a state machine is halted"
struct Halted <: SState end

"`Init(info)`: Init event with some info."
struct Init <: SEvent
    info::Any
end

"`Setup(vars::Array{Symbol,1}, scope::Module)`: setup a logger with some info."
struct Setup <: SEvent
    vars::Array{Symbol,1}
    scope::Module
end

"`Switch(to)`: switch to some other mode"
struct Switch <: SEvent
    to
end

"`Log()`: record command for logging"
struct Log <: SEvent end

"`Step()`: command"
struct Step <: SEvent end

"`Run()`: command"
struct Run <: SEvent
    duration::Float64
end

"`Start()`: command"
struct Start <: SEvent end

"`Stop()`: command"
struct Stop <: SEvent end

"`Resume()`: command"
struct Resume <: SEvent end

"`Clear()`: command"
struct Clear <: SEvent end


"""
    step!(A::SEngine, q::SState, σ::SEvent)

Default transition for clock and logger.

This is called if no otherwise defined transition occurs.

# Arguments
- `A::SEngine`: state machine for which a transition is called
- `q::SState`:  state of the state machine
- `σ::SEvent`:  event, triggering the transition
"""
function step!(A::SEngine, q::SState, σ::SEvent)
    println(stderr, "Warning: undefined transition ",
            "$(typeof(A)), ::$(typeof(q)), ::$(typeof(σ)))")
end
