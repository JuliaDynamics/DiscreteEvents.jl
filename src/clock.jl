#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#


"""
    setUnit!(clk::Clock, new::FreeUnits)

set a clock to a new time unit in `Unitful`. If necessary convert
current clock times to the new unit.

# Arguments
- `clk::Clock`
- `new::FreeUnits`: new is one of `ms`, `s`, `minute` or `hr` or another Unitful
    `Time` unit.

# Examples
```jldoctest
julia> using Simulate, Unitful

julia> import Unitful: Time, s, minute, hr

julia> c = Clock(t0=60)     # setup a new clock with t0=60
Clock: state=Simulate.Undefined(), time=60.0, unit=, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=0.0

julia> tau(c) # current time is 60.0 NoUnits
60.0

julia> setUnit!(c, s)       # set clock unit to Unitful.s
60.0 s

julia> tau(c) # current time is now 60.0 s
60.0 s

julia> setUnit!(c, minute)  # set clock unit to Unitful.minute
1.0 minute

julia> tau(c)               # current time is now 1.0 minute
1.0 minute

julia> typeof(tau(c))       # tau(c) now returns a time Quantity ...
Quantity{Float64,𝐓,Unitful.FreeUnits{(minute,),𝐓,nothing}}

julia> isa(tau(c), Time)
true

julia> uconvert(s, tau(c))  # ... which can be converted to other time units
60.0 s

julia> tau(c).val           # it has a value of 1.0
1.0

julia> c.time               # internal clock time is set to 1.0 (a Float64)
1.0

julia> c.unit               # internal clock unit is set to Unitful.minute
minute
```
"""
function setUnit!(clk::Clock, new::FreeUnits)
    if isa(1new, Time)
        if clk.unit == new
            println("clock is already set to $new")
        elseif clk.unit == NoUnits
            clk.unit = new
        else
            old = clk.unit
            clk.unit = new
            fac = uconvert(new, 1*old).val
            clk.time *= fac
            clk.end_time *= fac
            clk.tev *= fac
            clk.Δt *= fac
            clk.tn *= fac
        end
    else
        clk.unit = NoUnits
    end
    tau(clk)
end

"""
```
𝐶
Clk
```
`𝐶` (𝐶 = \\itC+[tab]) or `Clk` is the central simulation clock. If you do one
simulation at a time, you can use 𝐶 or Clk for time keeping.

# Examples

```jldoctest
julia> using Simulate

julia> reset!(𝐶)
"clock reset to t₀=0.0, sampling rate Δt=0.0."

julia> 𝐶  # central clock
Clock: state=Simulate.Idle(), time=0.0, unit=, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=0.0

julia> 𝐶 === Clk
true

```
"""
const 𝐶 = Clk = Clock()

"""
```
tau(clk::Clock=𝐶)
τ(clk::Clock=𝐶)
```
Return the current simulation time (τ = \\tau+tab).

# Examples

```jldoctest
julia> using Simulate

julia> reset!(𝐶)
"clock reset to t₀=0.0, sampling rate Δt=0.0."
julia> tau() # gives the central time
0.0
julia> τ() # alias, gives the central time
0.0
```
"""
tau(clk::Clock=𝐶) = clk.unit == NoUnits ? clk.time : clk.time*clk.unit
const τ = tau

"""
```
sync!(clk::Clock, to::Clock=𝐶)
```
Force a synchronization of two clocks. Change all registered times of
`clk` accordingly. Convert or force clk.unit to to.unit.
"""
function sync!(clk::Clock, to::Clock=𝐶)
    if (clk.unit == NoUnits) | (clk.unit == to.unit)
        fac = 1
    elseif to.unit == NoUnits
        println(stderr, "Warning: deleted time unit without conversion")
        fac = 1
    else
        fac = uconvert(to.unit, 1clk.unit).val
    end
    Δt = to.time - clk.time*fac
    clk.time = clk.time*fac + Δt
    clk.unit = to.unit
    clk.tn  = clk.tn*fac + Δt
    clk.tev  = clk.tev*fac + Δt
    clk.end_time = clk.end_time*fac + Δt
    clk.Δt = to.Δt
    evq = PriorityQueue{SimEvent,Float64}()
    for (ev, t) ∈ pairs(clk.sc.events)
        evq[ev] = t*fac + Δt
    end
    clk.sc.events = evq
    clk
end

"""
```
reset!(clk::Clock, Δt::Number=0; t0::Number=0, hard::Bool=true, unit=NoUnits)
```
reset a clock

# Arguments
- `clk::Clock`
- `Δt::Number=0`: time increment
- `t0::Float64=0` or `t0::Time`: start time
- `hard::Bool=true`: time is reset, all scheduled events and sampling are
    deleted. If hard=false, then only time is reset, event and
    sampling times are adjusted accordingly.
- `unit=NoUnits`: the Time unit for the clock after reset. If a `Δt::Time` is
    given, its Time unit goes into the clock Time unit. If only t0::Time is given,
    its Time unit goes into the clock time unit.

# Examples

```jldoctest
julia> using Simulate, Unitful

julia> import Unitful: s

julia> c = Clock(1s, t0=60s)
Clock: state=Simulate.Undefined(), time=60.0, unit=s, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=1.0

julia> reset!(c)
"clock reset to t₀=0.0, sampling rate Δt=0.0."

julia> c
Clock: state=Simulate.Idle(), time=0.0, unit=, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=0.0
```
"""
function reset!(clk::Clock, Δt::Number=0;
                t0::Number=0, hard::Bool=true, unit=NoUnits)
    if  isa(1unit, Time)
        Δt = isa(Δt, Time) ? uconvert(unit, Δt).val : Δt
        t0 = isa(t0, Time) ? uconvert(unit, t0).val : t0
    elseif isa(Δt, Time)
        unit = Unitful.unit(1Δt)
        Δt = Δt.val
        t0 = isa(t0, Time) ? uconvert(unit, t0).val : t0
    elseif isa(t0, Time)
        unit = Unitful.unit(t0)
        t0 = t0.val
    else
        nothing
    end
    if hard
        clk.state = Idle()
        clk.time = t0
        clk.unit = unit
        clk.tn = t0
        clk.tev = t0
        clk.end_time = t0
        clk.evcount = 0
        clk.scount = 0
        clk.Δt = Δt
        clk.sc.events = PriorityQueue{SimEvent,Float64}()
        clk.sc.cevents = SimCond[]
        clk.processes = Dict{Any, SimProcess}()
        clk.sc.sexpr = Sample[]
    else
        sync!(clk, Clock(Δt, t0=t0, unit=unit))
    end
    "clock reset to t₀=$(float(t0*unit)), sampling rate Δt=$(float(Δt*unit))."
end


"""
    checktime(clk::Clock, t::Number)::Float64

check `t` given according to clock settings and return a Float64 value
"""
function checktime(clk::Clock, t::Number)::Float64
    if isa(t, Real)
        return t
    else
        if clk.unit == NoUnits
            println(stderr, "Warning: clock has no time unit, ignoring units")
            return t.val
        else
            return uconvert(clk.unit, t).val
        end
    end
end

"""
```
event!([clk::Clock], ex::Union{SimExpr, Tuple, Vector}, t::Number;
       scope::Module=Main, cycle::Number=0.0)::Float64
```
Schedule an event for a given simulation time.

# Arguments
- `clk::Clock`: it not supplied, the event is scheduled to 𝐶,
- `ex::Union{SimExpr, Tuple, Vector}`: an expression or SimFunction or an array or tuple of them,
- `t::Real` or `t::Time`: simulation time, if t < clk.time set t = clk.time,
- `scope::Module=Main`: scope for expressions to be evaluated in,
- `cycle::Float64=0.0`: repeat cycle time for an event.

# returns
Scheduled internal simulation time (unitless) for that event.
May return a time `> t` from repeated applications of `nextfloat(t)`
if there are events scheduled for `t`.

# Examples
```jldoctest
julia> using Simulate, Unitful

julia> import Unitful: s, minute, hr

julia> myfunc(a, b) = a+b
myfunc (generic function with 1 method)

julia> event!(𝐶, SimFunction(myfunc, 1, 2), 1) # a 1st event to 1
1.0
julia> event!(𝐶, SimFunction(myfunc, 2, 3), 1) #  a 2nd event to the same time
1.0000000000000002

julia> event!(𝐶, SimFunction(myfunc, 3, 4), 1s)
Warning: clock has no time unit, ignoring units
1.0000000000000004

julia> setUnit!(𝐶, s)
0.0 s

julia> event!(𝐶, SimFunction(myfunc, 4, 5), 1minute)
60.0
```
"""
function event!(clk::Clock, ex::Union{SimExpr, Tuple, Vector}, t::Number;
                scope::Module=Main, cycle::Number=0.0)::Float64
    t = checktime(clk, t)
    (t < clk.time) && (t = clk.time)
    cycle = checktime(clk, cycle)
    while any(i->i==t, values(clk.sc.events)) # in case an event at that time exists
        t = nextfloat(float(t))                  # increment scheduled time
    end
    ev = SimEvent(sconvert(ex), scope, t, cycle)
    clk.sc.events[ev] = t
    return t
end
event!( ex::Union{SimExpr, Tuple, Vector}, t::Number; scope::Module=Main, cycle::Number=0.0) =
            event!(𝐶, ex, t, scope=scope, cycle=cycle)

"""
```
event!([clk::Clock], ex::Union{SimExpr, Tuple, Vector}, T::Timing, t::Number;
       scope::Module=Main)::Float64
```
Schedule a timed event, that is an event with a timing.

# Arguments
- `clk::Clock`: if not supplied, the event is scheduled to 𝐶,
- `ex::{SimExpr, Tuple, Vector}`: an expression or SimFunction or an array or tuple of them,
- `T::Timing`: a timing, `at`, `after` or `every` (`before` behaves like `at`),
- `t::Float64` or `t::Time`: simulation time,
- `scope::Module=Main`: scope for the expressions to be evaluated

# returns
Scheduled internal simulation time (unitless) for that event.

# Examples
```jldoctest
julia> using Simulate, Unitful

julia> import Unitful: s, minute, hr

julia> setUnit!(𝐶, s)
0.0 s

julia> myfunc(a, b) = a+b
myfunc (generic function with 1 method)

julia> event!(SimFunction(myfunc, 5, 6), after, 1hr)
3600.0
```
"""
function event!(clk::Clock, ex::Union{SimExpr, Tuple, Vector}, T::Timing, t::Number;
                scope::Module=Main)
    @assert T in (at, after, every) "bad Timing $T for event!"
    t = checktime(clk, t)
    if T == after
        event!(clk, sconvert(ex), t + clk.time, scope=scope)
    elseif T == every
        event!(clk, sconvert(ex), clk.time, scope=scope, cycle=t)
    else
        event!(clk, sconvert(ex), t, scope=scope)
    end
end
event!( ex::Union{SimExpr, Tuple, Vector}, T::Timing, t::Number; scope::Module=Main) =
            event!(𝐶, ex, T, t; scope=scope)

"""
    scale(n::Number)::Float64

calculate the scale from a given number
"""
function scale(n::Number)::Float64
    if n > 0
        i = 1.0
        while !(10^i ≤ n < 10^(i+1))
            n < 10^i ? i -= 1 : i += 1
        end
        return 10^i
    else
        return 1
    end
end


"""
```
event!([clk::Clock], ex::Union{SimExpr, Tuple, Vector},
       cond::Union{SimExpr, Tuple, Vector}; scope::Module=Main):
```
Schedule a conditional event.

It is executed immediately if the conditions are met, else the condition is
checked at each clock tick Δt. A conditional event is triggered only once. After
that it is removed from the clock. If no sampling rate Δt is setup, a default
sampling rate is setup depending on the scale of the remaining simulation time
``Δt = scale(t_r)/100`` or ``0.01`` if ``t_r = 0``.

# Arguments
- `clk::Clock`: if no clock is supplied, the event is scheduled to 𝐶,
- `ex::Union{SimExpr, Tuple{SimExpr}, Vector{SimExpr}}`: an expression or SimFunction or an array or tuple of them,
- `cond::Union{SimExpr, Tuple{SimExpr}, Vector{SimExpr}}`: a condition is an expression or SimFunction
    or an array or tuple of them. It is true only if all expressions or SimFunctions
    therein return true,
- `scope::Module=Main`: scope for the expressions to be evaluated

# returns
current simulation time `tau(clk)`.

# Examples
```jldoctest
julia> using Simulate

julia> c = Clock()   # create a new clock
Clock: state=Simulate.Undefined(), time=0.0, unit=, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=0.0

julia> event!(c, SF((x)->println(tau(x), ": now I'm triggered"), c), (@tau c :>= 5))
0.0

julia> c             # a conditional event turns sampling on
Clock: state=Simulate.Undefined(), time=0.0, unit=, events: 0, cevents: 1, processes: 0, sampling: 0, sample rate Δt=0.01

julia> run!(c, 10)   # sampling is not exact, so it takes 501 sample steps to fire the event
5.009999999999938: now I'm triggered
"run! finished with 0 clock events, 501 sample steps, simulation time: 10.0"
```

After the event is triggered, sampling is again switched off.

"""
function event!(clk::Clock, ex::Union{SimExpr, Tuple, Vector},
                cond::Union{SimExpr, Tuple, Vector}; scope::Module=Main)
    if clk.state == Busy() && all(evExec(sconvert(cond)))   # all conditions met
        evExec(sconvert(ex))                                # execute immediately
    else
        (clk.Δt == 0) && (clk.Δt = scale(clk.end_time - clk.time)/100)
        push!(clk.sc.cevents, SimCond(sconvert(cond), sconvert(ex), scope))
    end
    return tau(clk)
end
event!( ex::Union{SimExpr, Tuple, Vector}, cond::Union{SimExpr, Tuple, Vector};
        scope::Module=Main) = event!(𝐶, ex, cond, scope=scope)

"""
```
sample_time!([clk::Clock], Δt::Number)
```
set the clock's sample rate starting from now (`tau(clk)`).

# Arguments
- `clk::Clock`: if not supplied, set the sample rate on 𝐶,
- `Δt::Number`: sample rate, time interval for sampling
"""
function sample_time!(clk::Clock, Δt::Number)
    clk.Δt = checktime(clk, Δt)
    clk.tn = clk.time + clk.Δt
end
sample_time!(Δt::Number) = sample_time!(𝐶, Δt)

"""
```
sample!([clk::Clock], ex::Union{Expr, SimFunction}, Δt::Number=clk.Δt; scope::Module=Main)
```
enqueue an expression for sampling.
# Arguments
- `clk::Clock`: if not supplied, it samples on 𝐶,
- `ex::Union{Expr, SimFunction}`: an expression or function,
- `Δt::Number=clk.Δt`: set the clock's sampling rate, if no Δt is given, it takes
    the current sampling rate, if that is 0, it calculates one,
- `scope::Module=Main`: optional, an evaluation scope for a given expression.
"""
function sample!(clk::Clock, ex::Union{Expr, SimFunction}, Δt::Number=clk.Δt;
                 scope::Module=Main)
    clk.Δt = Δt == 0 ? scale(clk.end_time - clk.time)/100 : Δt
    push!(clk.sc.sexpr, Sample(ex, scope))
    return true
end
sample!(ex::Union{Expr, SimFunction}, Δt::Number=𝐶.Δt; scope::Module=Main) =
    sample!(𝐶, ex, Δt, scope=scope)

"""
    step!(clk::Clock, ::Undefined, ::Init)

initialize a clock.
"""
function step!(clk::Clock, ::Undefined, ::Init)
    clk.state = Idle()
end

"""
    step!(clk::Clock, ::Undefined, σ::Union{Step,Run})

if uninitialized, initialize and then Step or Run.
"""
function step!(clk::Clock, ::Undefined, σ::Union{Step,Run})
    step!(clk, clk.state, Init(0))
    step!(clk, clk.state, σ)
end

"""
    setTimes(clk::Clock)

set clock times for next event or sampling action. The internal clock times
`clk.tev` and `clk.tn` must always be set to be at least `clk.time`.
"""
function setTimes(clk::Clock)
    if length(clk.sc.events) ≥ 1
        clk.tev = nextevtime(clk)
        clk.tn = clk.Δt > 0 ? clk.time + clk.Δt : clk.time
    else
        clk.tn = clk.Δt > 0 ? clk.time + clk.Δt : clk.time
        clk.tev = clk.tn
    end
end

"""
    step!(c::Clock, ::Union{Idle,Busy,Halted}, ::Step)

step forward to next tick or scheduled event.

At a tick evaluate 1) all sampling functions or expressions, 2) all conditional
events, then 3) if an event is encountered, trigger the event.

The internal clock times `c.tev` and `c.tn` are always at least `c.time`.
"""
step!(c::Clock, ::Union{Idle,Halted}, ::Step) = do_step!(c)

"""
    do_run(c::Clock, Δt::Float64)

Run a clock for a time Δt.
"""
function do_run!(c::Clock, Δt::Float64)
    c.end_time = c.time + Δt
    c.evcount = 0
    c.scount = 0
    setTimes(c)
    while any(i->(c.time < i ≤ c.end_time), (c.tn, c.tev))
        do_step!(c)
        if c.state == Halted()
            return c.end_time
        end
    end
    c.time = c.end_time
end

"""
    step!(clk::Clock, ::Idle, σ::Run)

Run a simulation for a given duration.

The duration is given with `Run(duration)`. Call scheduled events and evaluate
sampling expressions at each tick in that timeframe.
"""
function step!(clk::Clock, ::Idle, σ::Run)
    tend = do_run!(clk, σ.duration)
    if clk.state == Halted()
        return
    end
    # catch remaining events scheduled for the end_time
    while (length(clk.sc.events) ≥ 1) && (nextevtime(clk) ≤ tend + Base.eps(tend)*10)
        step!(clk, clk.state, Step())
        tend = nextfloat(tend)
    end
    clk.time = clk.end_time

    "run! finished with $(clk.evcount) clock events, $(clk.scount) sample steps, simulation time: $(clk.time)"
end

"""
    step!(clk::Clock, ::Busy, ::Stop)

Stop the clock.
"""
function step!(clk::Clock, ::Busy, ::Stop)
    clk.state = Halted()
    "Halted after $(clk.evcount) events, simulation time: $(clk.time)"
end

"""
    step!(clk::Clock, ::Halted, ::Resume)

Resume a halted clock.
"""
function step!(clk::Clock, ::Halted, ::Resume)
    clk.state = Idle()
    step!(clk, clk.state, Run(clk.end_time - clk.time))
end

"""
    step!(clk::Clock, q::SState, σ::SEvent)

catch all step!-function.
"""
function step!(clk::Clock, q::SState, σ::SEvent)
    println(stderr, "Warning: undefined transition ",
            "$(typeof(clk)), ::$(typeof(q)), ::$(typeof(σ)))\n",
            "maybe, you should reset! the clock!")
end

"""
    run!(clk::Clock, duration::Number)

Run a simulation for a given duration. Call scheduled events and evaluate
sampling expressions at each tick in that timeframe.
"""
run!(clk::Clock, duration::Number) =
                        step!(clk, clk.state, Run(checktime(clk, duration)))


"""
    incr!(clk::Clock)

Take one simulation step, execute the next tick or event.
"""
incr!(clk::Clock) = step!(clk, clk.state, Step())

"""
    stop!(clk::Clock)

Stop a running simulation.
"""
stop!(clk::Clock) = step!(clk, clk.state, Stop())

"""
    resume!(clk::Clock)

Resume a halted simulation.
"""
resume!(clk::Clock) = step!(clk, clk.state, Resume())

"""
    init!(clk::Clock)

initialize a clock.
"""
init!(clk::Clock) = step!(clk, clk.state, Init(""))
