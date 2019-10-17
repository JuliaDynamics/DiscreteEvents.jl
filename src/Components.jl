# Define components for simulation and logging machines
# -------------------------------------------------------
# I choose Sim.jl to be self sufficient and not to depend
# on StateMachines.jl.
#

abstract type SEngine end
abstract type SState end
abstract type SEvent end

struct Undefined <: SState end
struct Idle <: SState end
struct Empty <: SState end
struct Busy <: SState end
struct Halted <: SState end

struct Init <: SEvent
    info::Any
end
struct Setup <: SEvent
    vars::Array{Symbol,1}
end
struct Switch <: SEvent
    to
end
struct Log <: SEvent end
struct Step <: SEvent end
struct Run <: SEvent
    duration::Float64
end
struct Start <: SEvent end
struct Stop <: SEvent end
struct Resume <: SEvent end
struct Clear <: SEvent end


"default transition for clock and logger"
function step!(A::SEngine, q::SState, σ::SEvent)
    println(stderr, "Warning: undefined transition ",
            "$(typeof(A)), ::$(typeof(q)), ::$(typeof(σ)))")
end
