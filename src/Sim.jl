module Sim

using Random, DataStructures, DataFrames

include("Components.jl")
include("Clock.jl")
include("Logger.jl")

export  Logger, Record, switch!, setup!, init!, record!, clear!,  # Logger.jl
        Clock, now, event!, run!, stop!, resume!, step!,
        Timing, at, after, every

Random.seed!(123)

"default transition for clock and logger"
function step!(A::SEngine, q::SState, σ::SEvent)
    println(stderr, "Warning: undefined transition ",
            "$(typeof(A)), ::$(typeof(q)), ::$(typeof(σ)))")
end

end # module
