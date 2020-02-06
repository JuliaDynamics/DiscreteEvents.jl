#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

"""
    𝐶

`𝐶` (𝐶 = `\\itC`+`tab`) is the default simulation clock. If you do one
simulation at a time, you can use it for time keeping.

# Examples

```jldoctest
julia> using Simulate

julia> reset!(𝐶)
"clock reset to t₀=0.0, sampling rate Δt=0.0."

julia> 𝐶  # default clock
Clock thread 1 (+ 0 ac): state=Simulate.Idle(), t=0.0 , Δt=0.0 , prc:0
  scheduled ev:0, cev:0, sampl:0
```
"""
const 𝐶 = Clock()

# ----------------------------------------------------
# setting and getting clock parameters
# ----------------------------------------------------

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
Clock thread 1 (+ 0 ac): state=Simulate.Undefined(), t=60.0 , Δt=0.0 , prc:0
  scheduled ev:0, cev:0, sampl:0

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
Clock thread 1 (+ 0 ac): state=Simulate.Undefined(), t=60.0 s, Δt=1.0 s, prc:0
  scheduled ev:0, cev:0, sampl:0

julia> reset!(c)
"clock reset to t₀=0.0, sampling rate Δt=0.0."

julia> c
Clock thread 1 (+ 0 ac): state=Simulate.Idle(), t=0.0 , Δt=0.0 , prc:0
  scheduled ev:0, cev:0, sampl:0
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
periodic!([clk::Clock], ex::Union{Expr, Fun}, Δt::Number=clk.Δt;
        scope::Module=Main, spawn=false)
```
Register a function or expression for periodic execution at the clock`s sample rate.

# Arguments
- `clk::Clock`: if not supplied, it samples on 𝐶,
- `ex::Union{Expr, Fun}`: an expression or function,
- `Δt::Number=clk.Δt`: set the clock's sampling rate, if no Δt is given, it takes
    the current sampling rate, if that is 0, it calculates one,
- `scope::Module=Main`: optional, an evaluation scope for a given expression.
"""
function periodic!(clk::Clock, ex::Union{Expr, Fun}, Δt::Number=clk.Δt;
                 scope::Module=Main, spawn=false)
    clk.Δt = Δt == 0 ? scale(clk.end_time - clk.time)/100 : Δt
    assign(clk, Sample(ex, scope), spawn ? spawnid(clk) : 0)
end
periodic!(ex::Union{Expr, Fun}, Δt::Number=𝐶.Δt; kw...) = periodic!(𝐶, ex, Δt; kw...)

"Is a Clock busy?"
busy(clk::Clock) = clk.state == Busy()


# ----------------------------------------------------
# step! transition functions for Clocks
# ----------------------------------------------------

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
    if !isempty(clk.sc.events)
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

# --------------------------------------------------------
# Clock user interface functions
# --------------------------------------------------------

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
