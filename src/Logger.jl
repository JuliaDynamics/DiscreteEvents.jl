#
# a simple event logger
#

struct Record
    time::Float64
    A::AbstractString
    name::AbstractString
    q::AbstractString
    σ::AbstractString
    info::AbstractString
end

mutable struct Logger <: SEngine
    sim::Union{Clock,Number}
    state::SState
    last::Union{Record,Number}
    ltype::UInt64
    df::DataFrame

    Logger() = new(0, Undefined(), 0, 0,
                   DataFrame(   time=Float64[],
                                A=AbstractString[],
                                name=AbstractString[],
                                q=AbstractString[],
                                σ=AbstractString[],
                                info=AbstractString[],
                            )
                  )
end

function step!(A::Logger, ::Undefined, σ::Init)
    A.sim = σ.info
    A.state = Idle()
end

"Logging event"
function step!(A::Logger, ::Idle, σ::Log)
    r = A.last = Record(now(A.sim), repr(typeof(σ.A)), repr(σ.A.name),
                        repr(typeof(σ.A.state)), repr(typeof(σ.σ)), repr(σ.info))
    if A.ltype == 1
        println(r.time,del,r.A,del,r.aname,del,r.q,del,r.σ,del,info)
    elseif A.ltype == 2
        push!(A.df, (r.time, r.A, r.name, r.q, r.σ, r.info))
    end
end

"Switch type of logging 0: none, 1: print, 2: store in log table"
function step!(A::Logger, ::Idle, σ::Switch)
    if σ.to ∈ 0:2
        A.ltype = σ.to
    end
end

"Switch type of logging 0: none, 1: print, 2: store in log table."
switch!(L::Logger, to::UInt64=0) = step!(L, L.state, Switch(to))
