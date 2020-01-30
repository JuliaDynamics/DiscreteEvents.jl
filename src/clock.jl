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
```
Return the current simulation time.

# Examples

```jldoctest
julia> using Simulate

julia> reset!(𝐶)
"clock reset to t₀=0.0, sampling rate Δt=0.0."
julia> tau() # gives the central time
0.0
```
"""
tau(clk::Clock=𝐶) = clk.unit == NoUnits ? clk.time : clk.time*clk.unit

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
    evq = PriorityQueue{DiscreteEvent,Float64}()
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
        clk.sc.events = PriorityQueue{DiscreteEvent,Float64}()
        clk.sc.cevents = DiscreteCond[]
        clk.processes = Dict{Any, Prc}()
        clk.sc.samples = Sample[]
    else
        sync!(clk, Clock(Δt, t0=t0, unit=unit))
    end
    "clock reset to t₀=$(float(t0*unit)), sampling rate Δt=$(float(Δt*unit))."
end

"""
    tadjust(clk::Clock, t::Unitful.Time) :: Float64

Adjust/convert `t` given according to clock settings and return a Float64 value.
"""
function tadjust(clk::Clock, t::Unitful.Time) :: Float64
    if clk.unit == NoUnits
        println(stderr, "Warning: clock has no time unit, ignoring units")
        return t.val
    else
        return uconvert(clk.unit, t).val
    end
end

"""
```
event!([clk::Clock], ex::Action, t::Number;
       scope::Module=Main, cycle::Number=0.0, spawn=false)::Float64
event!([clk::Clock], ex::Action, T::Timing, t::Number; kw...)
```
Schedule an event for a given simulation time.

# Arguments
- `clk::Clock`: it not supplied, the event is scheduled to 𝐶,
- `ex::Action`: an expression or Fun or a tuple of them,
- `T::Timing`: a timing, one of `at`, `after` or `every`,
- `t::Real` or `t::Time`: simulation time, if t < clk.time set t = clk.time,

# Keyword arguments
- `scope::Module=Main`: scope for expressions to be evaluated in,
- `cycle::Float64=0.0`: repeat cycle time for an event,
- `spawn=false`: it true spawn the event at other available threads.

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

julia> event!(𝐶, Fun(myfunc, 1, 2), 1) # a 1st event to 1
1.0
julia> event!(𝐶, Fun(myfunc, 2, 3), 1) #  a 2nd event to the same time
1.0000000000000002

julia> event!(𝐶, Fun(myfunc, 3, 4), 1s)
Warning: clock has no time unit, ignoring units
1.0000000000000004

julia> setUnit!(𝐶, s)
0.0 s

julia> event!(𝐶, Fun(myfunc, 4, 5), 1minute)
60.0

julia> event!(Fun(myfunc, 5, 6), after, 1hr)
3600.0
```
"""
function event!(clk::Clock, ex::Action, t::Number;
                scope::Module=Main, cycle::Number=0.0, spawn=false)::Float64
    (t isa Unitful.Time) && (t = tadjust(clk, t))
    (cycle isa Unitful.Time) && (cycle = tadjust(clk, cycle))
    (t < clk.time) && (t = clk.time)

    assign(clk, DiscreteEvent(ex, scope, t, cycle), spawn ? spawnid(clk) : 0)
end
event!(ex::Action, t::Number; kw...) = event!(𝐶, ex, t; kw...)
function event!(clk::Clock, ex::Action, T::Timing, t::Number;
                scope::Module=Main, spawn=false) :: Float64
    (t isa Unitful.Time) && (t = tadjust(clk, t))
    if T == after
        event!(clk, ex, t+clk.time, scope=scope, spawn=spawn)
    elseif T == every
        event!(clk, ex, clk.time, scope=scope, cycle=t, spawn=spawn)
    else
        event!(clk, ex, t, scope=scope, spawn=spawn)
    end
end
event!(ex::Action, T::Timing, t::Number; kw...) = event!(𝐶, ex, T, t; kw...)


"""
```
event!([clk::Clock], ex::Action, cond::Action; scope::Module=Main)::Float64
```
Schedule a conditional event.

It is executed immediately if the conditions are met, else the condition is
checked at each clock tick Δt. A conditional event is triggered only once. After
that it is removed from the clock. If no sampling rate Δt is setup, a default
sampling rate is setup depending on the scale of the remaining simulation time
``Δt = scale(t_r)/100`` or ``0.01`` if ``t_r = 0``.

# Arguments
- `clk::Clock`: if no clock is supplied, the event is scheduled to 𝐶,
- `ex::Union{SimExpr, Tuple{SimExpr}}`: an expression or Fun or a tuple of them,
- `cond::Union{SimExpr, Tuple{SimExpr}}`: a condition is an expression or Fun
    or a tuple of them. It is true only if all expressions or Funs
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
function event!(clk::Clock, ex::Action, cond::Action; scope::Module=Main, spawn=false)
    if clk.state == Busy() && all(evExec(cond))   # all conditions met
        evExec(ex)                                # execute immediately
    else
        assign(clk, DiscreteCond(cond, ex, scope), spawn ? spawnid(clk) : 0)
    end
    return tau(clk)
end
event!( ex::Action, cond::Action; kw...) = event!(𝐶, ex, cond; kw...)

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
    clk.Δt = Δt isa Unitful.Time ? tadjust(clk, Δt) : Δt
    clk.tn = clk.time + clk.Δt
end
sample_time!(Δt::Number) = sample_time!(𝐶, Δt)

"""
```
sample!([clk::Clock], ex::Union{Expr, Fun}, Δt::Number=clk.Δt;
        scope::Module=Main, spawn=false)
```
enqueue an expression for sampling.
# Arguments
- `clk::Clock`: if not supplied, it samples on 𝐶,
- `ex::Union{Expr, Fun}`: an expression or function,
- `Δt::Number=clk.Δt`: set the clock's sampling rate, if no Δt is given, it takes
    the current sampling rate, if that is 0, it calculates one,
- `scope::Module=Main`: optional, an evaluation scope for a given expression.
"""
function sample!(clk::Clock, ex::Union{Expr, Fun}, Δt::Number=clk.Δt;
                 scope::Module=Main, spawn=false)
    clk.Δt = Δt == 0 ? scale(clk.end_time - clk.time)/100 : Δt
    assign(clk, Sample(ex, scope), spawn ? spawnid(clk) : 0)
end
sample!(ex::Union{Expr, Fun}, Δt::Number=𝐶.Δt; kw...) = sample!(𝐶, ex, Δt; kw...)

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
    step!(clk::Clock, q::ClockState, σ::ClockEvent)

catch all step!-function.
"""
function step!(clk::Clock, q::ClockState, σ::ClockEvent)
    println(stderr, "Warning: undefined transition ",
            "$(typeof(clk)), ::$(typeof(q)), ::$(typeof(σ)))\n",
            "maybe, you should reset! the clock!")
end

"""
    run!(clk::Clock, duration::Number)

Run a simulation for a given duration. Call scheduled events and evaluate
sampling expressions at each tick in that timeframe.
"""
function run!(clk::Clock, duration::Number)
    duration = duration isa Unitful.Time ? tadjust(clk, duration) : duration
    step!(clk, clk.state, Run(duration))
end


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
