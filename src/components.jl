#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

# --- Clock states ----------
struct Undefined <: ClockState end
struct Idle <: ClockState end
struct Empty <: ClockState end
struct Busy <: ClockState end
struct Halted <: ClockState end

# --- Clock events -----------
struct Clear <: ClockEvent end
struct Diag <: ClockEvent end   # ask for the stacktrace of an async clock
struct Done <: ClockEvent       # notication of a worker clock to master
    t::UInt
end
struct Error <: ClockEvent
    exc::Exception
end
struct Finish <: ClockEvent     # ask a worker clock to finish
    tend::Float64
end
struct Forward{T <: Union{DiscreteEvent,DiscreteCond,Sample}} <: ClockEvent
    ev::T
    id::Int
end
struct Init <: ClockEvent
    info::Any
end
struct Query <: ClockEvent end
struct Register{T <: Union{DiscreteEvent,DiscreteCond,Sample}} <: ClockEvent
    x::T
end
struct Reset <: ClockEvent
    type::Bool
end
struct Response <: ClockEvent
    x::Any
end
struct Resume <: ClockEvent end
struct Run <: ClockEvent
    duration::Float64
    sync::Bool
end
struct Start <: ClockEvent end
struct Startup <: ClockEvent
    m::Ref{GlobalClock}
end
struct Step <: ClockEvent end
struct Stop <: ClockEvent end
struct Sync <: ClockEvent end

# --- default transition for clocks
function step!(A::AbstractClock, q::ClockState, σ::ClockEvent)
    println(stderr, "Warning: undefined transition ",
            "$(typeof(A)), ::$(typeof(q)), ::$(typeof(σ)))")
end
