import Tables

struct LogTable
    data::Dict{Symbol,AbstractVector}
end

LogTable() = LogTable(Dict{Symbol,AbstractVector}())

data(df::LogTable) = getfield(df, :data)

Base.size(df::LogTable) = (size(df, 1), size(df, 2))
function Base.size(df::LogTable, i::Int)
    if i == 1
        length(data(df)[first(keys(data(df)))])
    elseif i == 2
        length(keys(data(df)))
    else
        0
    end
end

# LogTable satisfies the Tables.columns interface
Base.getproperty(df::LogTable, s::Symbol) = getindex(data(df), s)
Base.propertynames(df::LogTable) = collect(keys(data(df)))
Base.setproperty!(df::LogTable, s::Symbol, x::AbstractVector) = setindex!(data(df), x, s)
Tables.columns(df::LogTable) = df

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
    scope::Module
    df::LogTable

    Logger() = new(0, Undefined(), NamedTuple(), 0, Symbol[], Main, LogTable())
end

# Allows Logger to be directly treated as a table
Tables.columns(l::Logger) = l.df
Tables.istable(::Type{Logger}) = true
Tables.columnaccess(::Type{Logger}) = true
# TODO: defining Tables.schema can enable performance gains for consumers of table

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

Setup a logger with logging variables. They are given by `Setup(vars, scope)`.
"""
function step!(A::Logger, ::Empty, σ::Setup)
    A.lvars = σ.vars
    A.scope = σ.scope
    A.df.time = Float64[]
    for v ∈ A.lvars
        setproperty!(A.df, v, typeof(Core.eval(A.scope, v))[])
    end
    A.state = Idle()
end

"""
    step!(A::Logger, ::Idle, ::Clear)

Clear the last record and the data table of a logger.
"""
function step!(A::Logger, ::Idle, ::Clear)
    A.last = NamedTuple();
    for v in values(data(A.df))
        empty!(v)
    end
end

"""
    step!(A::Logger, ::Idle, σ::Log)

Logging event.
"""
function step!(A::Logger, ::Idle, σ::Log)
    time = τ(A.sim)
    val = vcat([time], Array{Any}([Core.eval(A.scope,i) for i in A.lvars]))
    A.last = NamedTuple{Tuple(vcat([:time],A.lvars))}(val)
    if A.ltype == 1
        println(A.last)
    elseif A.ltype == 2
        for (k, v) in pairs(A.last)
            push!(data(A.df)[k], v)
        end
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
init!(L::Logger, sim::Clock=Τ) = step!(L, L.state, Init(sim))

"""
    setup!(L::Logger, vars::Array{Symbol})

Setup a logger with logging variables.

# Arguments
- `L::Logger`
- `vars::Array{Symbol}`: An array of symbols, e.g. of global variables
- `scope::Module = Main`: Scope in which to evaluate the variables
"""
setup!(L::Logger, vars::Array{Symbol}; scope::Module = Main) =
        step!(L, L.state, Setup(vars, scope))

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
