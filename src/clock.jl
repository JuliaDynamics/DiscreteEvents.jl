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
    if threadid() == 1
        foreach(ac->put!(ac.forth, Reset(hard)), clk.ac)
        foreach(ac->take!(ac.back), clk.ac)
        "clock reset to t₀=$(float(t0*unit)), sampling rate Δt=$(float(Δt*unit))."
    end
end

# Adjust/convert `t` given according to clock settings and return a Float64
function _tadjust(clk::Clock, t::Unitful.Time) :: Float64
    if clk.unit == NoUnits
        println(stderr, "Warning: clock has no time unit, ignoring units")
        return t.val
    else
        return uconvert(clk.unit, t).val
    end
end
_tadjust(clk::Clock, t::Number) = t
_tadjust(ac::ActiveClock, t::Number) = _tadjust(ac.clock, t)

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
    clk.Δt = Δt isa Unitful.Time ? _tadjust(clk, Δt) : Δt
    clk.tn = clk.time + clk.Δt
end
sample_time!(Δt::Number) = sample_time!(𝐶, Δt)

# Is a Clock busy?
_busy(clk::Clock) = clk.state == Busy()


# set clock times for next event or sampling action. The internal clock times
# `clk.tev` and `clk.tn` must always be set to be at least `clk.time`.
function _setTimes(clk::Clock)
    if !isempty(clk.sc.events)
        clk.tev = _nextevtime(clk)
        clk.tn = clk.Δt > 0 ? clk.time + clk.Δt : clk.time
    else
        clk.tn = clk.Δt > 0 ? clk.time + clk.Δt : clk.time
        clk.tev = clk.tn
    end
end

# ----------------------------------------------------
# step! transition functions for Clocks
# ----------------------------------------------------

step!(clk::Clock, ::Undefined, ::Init) = ( clk.state = Idle() )

# if uninitialized, initialize and then Step or Run.
function step!(clk::Clock, ::Undefined, σ::Union{Step,Run})
    step!(clk, clk.state, Init(0))
    step!(clk, clk.state, σ)
end

step!(c::Clock, ::Union{Idle,Halted}, ::Step) = _step!(c)

# Run a clock for a time Δt.
function _run!(c::Clock, Δt::Float64)
    c.end_time = c.time + Δt
    _setTimes(c)
    while any(i->(c.time < i ≤ c.end_time), (c.tn, c.tev))
        _step!(c)
        if c.state == Halted()
            return c.end_time
        end
    end
    c.time = c.end_time
end

# Finish a run at time tend, catch remaining events scheduled for tend.
function _finish!(c::Clock, tend::Float64)
    while (length(c.sc.events) ≥ 1) && (_nextevtime(c) ≤ tend + Base.eps(tend)*10)
        step!(c, c.state, Step())
        tend = nextfloat(tend)
    end
    c.time = c.end_time
end

# ----------------------------------------
# Run a simulation for a given duration.
#
# The duration is given with `Run(duration)`. Call scheduled events and evaluate
# sampling expressions at each tick in that timeframe.
# ----------------------------------------
function step!(clk::Clock, ::Idle, σ::Run)

    function handle_response(ix::Int)
        while true
            token = take!(clk.ac[ix].back)
            if token isa Done
                break
            elseif token isa Forward
                assign(clk, token.ev, token.id)
            elseif token isa Error
                throw(token.exp)
            else
                error("invalid response ac $ix: $token")
            end
        end
        clk.ac[ix].load += token.t
    end

    clk.evcount = 0
    clk.scount = 0
    foreach(ac->put!(ac.forth, Start()), clk.ac)
    if length(clk.ac) == 0
        tend = _run!(clk, σ.duration)
    else
        tend = clk.time + σ.duration
        while clk.time < tend
            Δt = min(clk.Δt, abs(tmax-clk.time))
            foreach(ac->put!(ac.forth, Run(Δt)), clk.ac)
            _run!(clk, Δt)
            foreach(handle_response, eachindex(clk.ac))
        end
    end
    if clk.state == Halted()
        return
    end
    clk.time = clk.end_time
    _finish!(clk, tend)
    foreach(ac->put!(ac.forth, Finish(tend)), clk.ac)
    for ac in clk.ac
        c1, c2 = take!(ac.back).x
        clk.evcount += c1
        clk.scount  += c2
    end

    "run! finished with $(clk.evcount) clock events, $(clk.scount) sample steps, simulation time: $(clk.time)"
end

# Stop the clock.
function step!(clk::Clock, ::Busy, ::Stop)
    clk.state = Halted()
    "Halted after $(clk.evcount) events, simulation time: $(clk.time)"
end

# Resume a halted clock.
function step!(clk::Clock, ::Halted, ::Resume)
    clk.state = Idle()
    step!(clk, clk.state, Run(clk.end_time - clk.time))
end

# catch all step!-function.
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
    duration = duration isa Unitful.Time ? _tadjust(clk, duration) : duration
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
