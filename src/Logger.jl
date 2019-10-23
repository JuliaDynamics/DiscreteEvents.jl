#
# a simple event logger
#

"""
    Logger()

Setup and return a logging variable.
"""
mutable struct Logger <: SEngine
    sim::Union{Clock,Number}
    state::SState
    last::NamedTuple
    ltype::Int64
    lvars::Array{Symbol,1}
    df::DataFrame

    Logger() = new(0, Undefined(), NamedTuple(), 0, Symbol[], DataFrame())
end

"""
    step!(A::Logger, ::Undefined, σ::Init)

Initialize a logger.
"""
function step!(A::Logger, ::Undefined, σ::Init)
    A.sim = σ.info
    A.state = Empty()
end

"""
    step!(A::Logger, ::Empty, σ::Setup)

Setup a logger with logging variables. They are given by `Setup(vars)`.
"""
function step!(A::Logger, ::Empty, σ::Setup)
    A.lvars = σ.vars
    A.df.time = Float64[]
    for v ∈ A.lvars
        A.df[!, v] = typeof(Core.eval(Main, v))[]
    end
    A.state = Idle()
end

"""
    step!(A::Logger, ::Idle, ::Clear)

Clear the last record and the data table of a logger.
"""
function step!(A::Logger, ::Idle, ::Clear)
    A.last = NamedTuple();
    deleterows!(A.df, 1:size(A.df,1))
end

"""
    step!(A::Logger, ::Idle, σ::Log)

Logging event.
"""
function step!(A::Logger, ::Idle, σ::Log)
    time = now(A.sim)
    val = vcat([time], Array{Any}([Core.eval(Main,i) for i in A.lvars]))
    A.last = NamedTuple{Tuple(vcat([:time],A.lvars))}(val)
    if A.ltype == 1
        println(A.last)
    elseif A.ltype == 2
        push!(A.df, [i for i in A.last])
    end
end

"""
    step!(A::Logger, ::Idle, σ::Switch)

Switch the operating mode of a logger by `Switch(to)`.

`to = 0`: no output, `to = 1`: print, `to = 2: store in log table"
"""
function step!(A::Logger, ::Idle, σ::Switch)
    if σ.to ∈ 0:2
        A.ltype = σ.to
    end
end

"""
    switch!(L::Logger, to::Number=0)

Switch the operating mode of a logger.

`to = 0`: no output, `to = 1`: print, `to = 2: store in log table"
"""
switch!(L::Logger, to::Number=0) = step!(L, L.state, Switch(to))

"""
    init!(L::Logger, sim::Clock)

Initialize a Logger.
"""
init!(L::Logger, sim::Clock) = step!(L, L.state, Init(sim))

"""
    setup!(L::Logger, vars::Array{Symbol})

Setup a logger with logging variables.

# Arguments
- `L::Logger`
- `vars::Array{Symbol}`: An array of symbols, e.g. of global variables
"""
setup!(L::Logger, vars::Array{Symbol}) = step!(L, L.state, Setup(vars))

"""
    record!(L::Logger)

record the logging variables with the current operating mode.
"""
record!(L::Logger) = step!(L, L.state, Log())

"""
    clear!(L::Logger)

clear the loggers last record and data table.
"""
clear!(L::Logger) = step!(L, L.state, Clear())
