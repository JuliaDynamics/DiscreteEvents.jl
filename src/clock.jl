#
# clock and event routines
#


"""
    setUnit!(sim::Clock, new::FreeUnits)

set a clock to a new time unit in `Unitful`. If necessary convert
current clock times to the new unit.

# Arguments
- `sim::Clock`
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
function setUnit!(sim::Clock, new::FreeUnits)
    if isa(1new, Time)
        if sim.unit == new
            println("clock is already set to $new")
        elseif sim.unit == NoUnits
            sim.unit = new
        else
            old = sim.unit
            sim.unit = new
            fac = uconvert(new, 1*old).val
            sim.time *= fac
            sim.end_time *= fac
            sim.tev *= fac
            sim.Δt *= fac
            sim.tsa *= fac
        end
    else
        sim.unit = NoUnits
    end
    tau(sim)
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
tau(sim::Clock=𝐶)
τ(sim::Clock=𝐶)
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
tau(sim::Clock=𝐶) = sim.unit == NoUnits ? sim.time : sim.time*sim.unit
const τ = tau

"""
```
sync!(sim::Clock, to::Clock=𝐶)
```
Force a synchronization of two clocks. Change all registered times of
`sim` accordingly. Convert or force sim.unit to to.unit.
"""
function sync!(sim::Clock, to::Clock=𝐶)
    if (sim.unit == NoUnits) | (sim.unit == to.unit)
        fac = 1
    elseif to.unit == NoUnits
        println(stderr, "Warning: deleted time unit without conversion")
        fac = 1
    else
        fac = uconvert(to.unit, 1sim.unit).val
    end
    Δt = to.time - sim.time*fac
    sim.time = sim.time*fac + Δt
    sim.unit = to.unit
    sim.tsa  = sim.tsa*fac + Δt
    sim.tev  = sim.tev*fac + Δt
    sim.end_time = sim.end_time*fac + Δt
    sim.Δt = to.Δt
    evq = PriorityQueue{SimEvent,Float64}()
    for (ev, t) ∈ pairs(sim.events)
        evq[ev] = t*fac + Δt
    end
    sim.events = evq
    sim
end

"""
```
reset!(sim::Clock, Δt::Number=0; t0::Number=0, hard::Bool=true, unit=NoUnits)
```
reset a clock

# Arguments
- `sim::Clock`
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
function reset!(sim::Clock, Δt::Number=0;
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
        sim.state = Idle()
        sim.time = t0
        sim.unit = unit
        sim.tsa = t0
        sim.tev = t0
        sim.end_time = t0
        sim.evcount = 0
        sim.scount = 0
        sim.Δt = Δt
        sim.events = PriorityQueue{SimEvent,Float64}()
        sim.cevents = SimCond[]
        sim.processes = Dict{Any, SimProcess}()
        sim.sexpr = Sample[]
    else
        sync!(sim, Clock(Δt, t0=t0, unit=unit))
    end
    "clock reset to t₀=$(float(t0*unit)), sampling rate Δt=$(float(Δt*unit))."
end

"""
    nextevent(sim::Clock)

Return the next scheduled event.
"""
nextevent(sim::Clock) = peek(sim.events)[1]

"""
    nextevtime(sim::Clock)

Return the internal time (unitless) of next scheduled event.
"""
nextevtime(sim::Clock) = peek(sim.events)[2]

"""
    simExec(ex::Union{SimExpr, Array{SimExpr,1}}, m::Module=Main)

Evaluate an event's expressions or SimFunctions. If symbols, expressions or
other Simfunctions are stored as arguments inside a SF, evaluate those first
before passing them to `SF.efun`.

# Return

the evaluated value or a tuple of evaluated values.
"""
function simExec(ex::Union{SimExpr, Array{SimExpr,1}}, m::Module=Main)

    function sexec(x::SimExpr)

        function evaluate(y, m::Module)
            if y isa Union{Symbol,Expr}
                try
                    return Core.eval(m, y)
                catch
                    return y
                end
            elseif y isa SimFunction
                return sexec(y)
            else
                return y
            end
        end

        if x isa SimFunction
            if x.efun == event!  # should arguments be maintained?
                arg = x.arg; kw = x.kw
            else                 # otherwise evaluate them
                x.arg === nothing || (arg = Tuple([evaluate(i, x.emod) for i in x.arg]))
                x.kw === nothing  || (kw = (; zip(keys(x.kw), [evaluate(i, x.emod) for i in values(x.kw)] )...))
            end
            if x.kw === nothing
                return x.arg === nothing ? x.efun() : x.efun(arg...)
            else
                return x.arg === nothing ? x.efun(; kw...) : x.efun(arg...; kw...)
            end
        else
            return Core.eval(m, x)
        end
    end

    return ex isa SimExpr ? sexec(ex) : Tuple([sexec(x) for x in ex])
end

"""
    checktime(sim::Clock, t::Number)::Float64

check `t` given according to clock settings and return a Float64 value
"""
function checktime(sim::Clock, t::Number)::Float64
    if isa(t, Real)
        return t
    else
        if sim.unit == NoUnits
            println(stderr, "Warning: clock has no time unit, ignoring units")
            return t.val
        else
            return uconvert(sim.unit, t).val
        end
    end
end

"""
```
event!([sim::Clock], ex::Union{SimExpr, Array, Tuple}, t::Number;
       scope::Module=Main, cycle::Number=0.0)::Float64
```
Schedule an event for a given simulation time.

# Arguments
- `sim::Clock`: it not supplied, the event is scheduled to 𝐶,
- `ex::{SimExpr, Array, Tuple}`: an expression or SimFunction or an array or tuple of them,
- `t::Real` or `t::Time`: simulation time, if t < sim.time set t = sim.time,
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
function event!(sim::Clock, ex::Union{SimExpr, Array, Tuple}, t::Number;
                scope::Module=Main, cycle::Number=0.0)::Float64
    t = checktime(sim, t)
    (t < sim.time) && (t = sim.time)
    cycle = checktime(sim, cycle)
    while any(i->i==t, values(sim.events)) # in case an event at that time exists
        t = nextfloat(float(t))                  # increment scheduled time
    end
    ev = SimEvent(sconvert(ex), scope, t, cycle)
    sim.events[ev] = t
    return t
end
event!( ex::Union{SimExpr, Array, Tuple}, t::Number; scope::Module=Main, cycle::Number=0.0) =
            event!(𝐶, ex, t, scope=scope, cycle=cycle)

"""
```
event!([sim::Clock], ex::Union{SimExpr, Array, Tuple}, T::Timing, t::Number;
       scope::Module=Main)::Float64
```
Schedule a timed event, that is an event with a timing.

# Arguments
- `sim::Clock`: if not supplied, the event is scheduled to 𝐶,
- `ex::{SimExpr, Array, Tuple}`: an expression or SimFunction or an array or tuple of them,
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
function event!(sim::Clock, ex::Union{SimExpr, Array, Tuple}, T::Timing, t::Number;
                scope::Module=Main)
    @assert T in (at, after, every) "bad Timing $T for event!"
    t = checktime(sim, t)
    if T == after
        event!(sim, sconvert(ex), t + sim.time, scope=scope)
    elseif T == every
        event!(sim, sconvert(ex), sim.time, scope=scope, cycle=t)
    else
        event!(sim, sconvert(ex), t, scope=scope)
    end
end
event!( ex::Union{SimExpr, Array, Tuple}, T::Timing, t::Number; scope::Module=Main) =
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
event!([sim::Clock], ex::Union{SimExpr, Array, Tuple},
       cond::Union{SimExpr, Array, Tuple}; scope::Module=Main):
```
Schedule a conditional event.

It is executed immediately if the conditions are met, else the condition is
checked at each clock tick Δt. A conditional event is triggered only once. After
that it is removed from the clock. If no sampling rate Δt is setup, a default
sampling rate is setup depending on the scale of the remaining simulation time
``Δt = scale(t_r)/100`` or ``0.01`` if ``t_r = 0``.

# Arguments
- `sim::Clock`: if no clock is supplied, the event is scheduled to 𝐶,
- `ex::{SimExpr, Array, Tuple}`: an expression or SimFunction or an array or tuple of them,
- `cond::{SimExpr, Array, Tuple}`: a condition is an expression or SimFunction
    or an array or tuple of them. It is true only if all expressions or SimFunctions
    therein return true,
- `scope::Module=Main`: scope for the expressions to be evaluated

# returns
current simulation time `tau(sim)`.

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
function event!(sim::Clock, ex::Union{SimExpr, Array, Tuple},
                cond::Union{SimExpr, Array, Tuple}; scope::Module=Main)
    if sim.state == Busy() && all(simExec(sconvert(cond)))   # all conditions met
        simExec(sconvert(ex))                                # execute immediately
    else
        (sim.Δt == 0) && (sim.Δt = scale(sim.end_time - sim.time)/100)
        push!(sim.cevents, SimCond(sconvert(cond), sconvert(ex), scope))
    end
    return tau(sim)
end
event!( ex::Union{SimExpr, Array, Tuple}, cond::Union{SimExpr, Array, Tuple};
        scope::Module=Main) = event!(𝐶, ex, cond, scope=scope)

"""
```
sample_time!([sim::Clock], Δt::Number)
```
set the clock's sample rate starting from now (`tau(sim)`).

# Arguments
- `sim::Clock`: if not supplied, set the sample rate on 𝐶,
- `Δt::Number`: sample rate, time interval for sampling
"""
function sample_time!(sim::Clock, Δt::Number)
    sim.Δt = checktime(sim, Δt)
    sim.tsa = sim.time + sim.Δt
end
sample_time!(Δt::Number) = sample_time!(𝐶, Δt)

"""
```
sample!([sim::Clock], ex::Union{Expr, SimFunction}, Δt::Number=sim.Δt; scope::Module=Main)
```
enqueue an expression for sampling.
# Arguments
- `sim::Clock`: if not supplied, it samples on 𝐶,
- `ex::Union{Expr, SimFunction}`: an expression or function,
- `Δt::Number=sim.Δt`: set the clock's sampling rate, if no Δt is given, it takes
    the current sampling rate, if that is 0, it calculates one,
- `scope::Module=Main`: optional, an evaluation scope for a given expression.
"""
function sample!(sim::Clock, ex::Union{Expr, SimFunction}, Δt::Number=sim.Δt;
                 scope::Module=Main)
    sim.Δt = Δt == 0 ? scale(sim.end_time - sim.time)/100 : Δt
    push!(sim.sexpr, Sample(ex, scope))
end
sample!(ex::Union{Expr, SimFunction}, Δt::Number=𝐶.Δt; scope::Module=Main) =
    sample!(𝐶, ex, Δt, scope=scope)

"""
    step!(sim::Clock, ::Undefined, ::Init)

initialize a clock.
"""
function step!(sim::Clock, ::Undefined, ::Init)
    sim.state = Idle()
end

"""
    step!(sim::Clock, ::Undefined, σ::Union{Step,Run})

if uninitialized, initialize and then Step or Run.
"""
function step!(sim::Clock, ::Undefined, σ::Union{Step,Run})
    step!(sim, sim.state, Init(0))
    step!(sim, sim.state, σ)
end

"""
    setTimes(sim::Clock)

set clock times for next event or sampling action. The internal clock times
`sim.tev` and `sim.tsa` must always be set to be at least `sim.time`.
"""
function setTimes(sim::Clock)
    if length(sim.events) ≥ 1
        sim.tev = nextevtime(sim)
        sim.tsa = sim.Δt > 0 ? sim.time + sim.Δt : sim.time
    else
        sim.tsa = sim.Δt > 0 ? sim.time + sim.Δt : sim.time
        sim.tev = sim.tsa
    end
end

"""
    step!(sim::Clock, ::Union{Idle,Busy,Halted}, ::Step)

step forward to next tick or scheduled event.

At a tick evaluate 1) all sampling functions or expressions, 2) all conditional
events, then 3) if an event is encountered, trigger the event.

The internal clock times `sim.tev` and `sim.tsa` is always at least `sim.time`.
"""
function step!(sim::Clock, ::Union{Idle,Halted}, ::Step)

    function exec_next_event()
        sim.time = sim.tev
        ev = dequeue!(sim.events)
        simExec(ev.ex, ev.scope)
        sim.evcount += 1
        if ev.Δt > 0.0  # schedule repeat event
            event!(sim, ev.ex, sim.time + ev.Δt, scope=ev.scope, cycle=ev.Δt)
        end
        sim.tev = length(sim.events) ≥ 1 ? nextevtime(sim) : sim.time
    end

    function exec_next_tick()
        sim.time = sim.tsa
        for s ∈ sim.sexpr
            simExec(s.ex, s.scope)
        end
        cond = [all(simExec(c.cond)) for c in sim.cevents]
        while any(cond)
            vc = Array(1:length(cond))
            ix = vc[cond][1]      # get the first index of a satisfied condition
            ex = sim.cevents[ix].ex
            subs = trues(length(cond))
            subs[ix] = false
            sim.cevents = sim.cevents[subs]
            simExec(ex)           # execute it
            if isempty(sim.cevents)
                isempty(sim.sexpr) && (sim.Δt = 0.0)  # delete sample rate
                break
            end
            cond = [all(simExec(c.cond)) for c in sim.cevents]
        end
        sim.scount +=1
    end

    sim.state = Busy()
    if (sim.tev ≤ sim.time) && (length(sim.events) ≥ 1)
        sim.tev = nextevtime(sim)
    end

    if (length(sim.events) ≥ 1) | (sim.Δt > 0.0)
        if length(sim.events) ≥ 1
            if (sim.Δt > 0.0)
                if sim.tsa <= sim.tev
                    exec_next_tick()
                    if sim.tsa == sim.tev
                        exec_next_event()
                    end
                    sim.tsa += sim.Δt
                else
                    exec_next_event()
                end
            else
                exec_next_event()
                sim.tsa = sim.time
            end
        else
            exec_next_tick()
            sim.tsa += sim.Δt
            sim.tev = sim.time
        end
    else
        println(stderr, "step!: nothing to evaluate")
    end
    length(sim.processes) == 0 || yield() # let processes run
    (sim.state == Busy()) && (sim.state = Idle())
end

"""
    step!(sim::Clock, ::Idle, σ::Run)

Run a simulation for a given duration.

The duration is given with `Run(duration)`. Call scheduled events and evaluate
sampling expressions at each tick in that timeframe.
"""
function step!(sim::Clock, ::Idle, σ::Run)
    length(sim.processes) > 0 && sleep(0.05)  # let processes startup
    sim.end_time = sim.time + σ.duration
    sim.evcount = 0
    sim.scount = 0
    setTimes(sim)
    while any(i->(sim.time < i ≤ sim.end_time), (sim.tsa, sim.tev))
        step!(sim, sim.state, Step())
        if sim.state == Halted()
            return
        end
    end
    tend = sim.end_time

    # catch remaining events
    while (length(sim.events) ≥ 1) && (nextevtime(sim) ≤ tend + Base.eps(tend)*10)
        step!(sim, sim.state, Step())
        tend = nextfloat(tend)
    end

    sim.time = sim.end_time
    sleep(0.01) # let processes finish
    "run! finished with $(sim.evcount) clock events, $(sim.scount) sample steps, simulation time: $(sim.time)"
end

"""
    step!(sim::Clock, ::Busy, ::Stop)

Stop the clock.
"""
function step!(sim::Clock, ::Busy, ::Stop)
    sim.state = Halted()
    "Halted after $(sim.evcount) events, simulation time: $(sim.time)"
end

"""
    step!(sim::Clock, ::Halted, ::Resume)

Resume a halted clock.
"""
function step!(sim::Clock, ::Halted, ::Resume)
    sim.state = Idle()
    step!(sim, sim.state, Run(sim.end_time - sim.time))
end

"""
    step!(sim::Clock, q::SState, σ::SEvent)

catch all step!-function.
"""
function step!(sim::Clock, q::SState, σ::SEvent)
    println(stderr, "Warning: undefined transition ",
            "$(typeof(sim)), ::$(typeof(q)), ::$(typeof(σ)))\n",
            "maybe, you should reset! the clock!")
end

"""
    run!(sim::Clock, duration::Number)

Run a simulation for a given duration. Call scheduled events and evaluate
sampling expressions at each tick in that timeframe.
"""
run!(sim::Clock, duration::Number) =
                        step!(sim, sim.state, Run(checktime(sim, duration)))


"""
    incr!(sim::Clock)

Take one simulation step, execute the next tick or event.
"""
incr!(sim::Clock) = step!(sim, sim.state, Step())

"""
    stop!(sim::Clock)

Stop a running simulation.
"""
stop!(sim::Clock) = step!(sim, sim.state, Stop())

"""
    resume!(sim::Clock)

Resume a halted simulation.
"""
resume!(sim::Clock) = step!(sim, sim.state, Resume())

"""
    init!(sim::Clock)

initialize a clock.
"""
init!(sim::Clock) = step!(sim, sim.state, Init(""))
