# Define components for simulation and logging machines
# -------------------------------------------------------
# I choose Sim.jl to be self sufficient and not to depend
# on StateMachines.jl. Therefore some of its definitions
# are repeated here but the types are named differently
#

abstract type SEngine end
abstract type SState end
abstract type SEvent end

struct Undefined <: SState end
struct Idle <: SState end
struct Busy <: SState end
struct Halted <: SState end


"event `Init(info)` with some initialization info"
struct Init <: SEvent
    info::Any
end

"event `Switch(to)` for task switching"
struct Switch <: SEvent
    to
end

"event `Log(A::Any,σ::SEvent,info)` for logging "
struct Log <: SEvent
    A::Any
    σ::SEvent
    info::Any
end

"event for user interaction"
struct Step <: SEvent end

"event `Run(duration)` for user interaction"
struct Run <: SEvent
    duration::Float64
end

"event for user interaction"
struct Start <: SEvent end

"event for user interaction"
struct Stop <: SEvent end

"event for user interaction"
struct Resume <: SEvent end
