#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

"""
```
event!([clk::AbstractClock], ex::Action, t::Number;
       scope::Module=Main, cycle::Number=0.0, spawn=false)::Float64
event!([clk::AbstractClock], ex::Action, T::Timing, t::Number; kw...)
```
Schedule an event for a given simulation time.

# Arguments
- `clk::AbstractClock`: it not supplied, the event is scheduled to 𝐶,
- `ex::Action`: an expression or Fun or a tuple of them,
- `T::Timing`: a timing, one of `at`, `after` or `every`,
- `t::Real` or `t::Time`: simulation time, if t < clk.time set t = clk.time,

# Keyword arguments
- `scope::Module=Main`: scope for expressions to be evaluated in,
- `cycle::Float64=0.0`: repeat cycle time for an event,
- `spawn::Bool=false`: if true, spawn the event at other available threads,
- `cid::Int=clk.id`: if cid ≠ clk.id, assign the event to the parallel clock
    with id == cid. This overrides `spawn`,
- `sync::Bool=false`: if true, force a synchronization of all parallel clocks
    before executing the event.

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
function event!(clk::AbstractClock, ex::Action, t::Number;
                scope::Module=Main, cycle::Number=0.0,
                spawn::Bool=false, cid::Int=clk.id, sync::Bool=false) :: Float64
    (t isa Unitful.Time) && (t = tadjust(clk, t))
    (cycle isa Unitful.Time) && (cycle = tadjust(clk, cycle))
    (t < clk.time) && (t = clk.time)

    assign(clk, DiscreteEvent(ex, scope, t, cycle), spawn ? spawnid(clk) : 0)
end
function event!(clk::AbstractClock, ex::Action, T::Timing, t::Number;
                scope::Module=Main,
                spawn::Bool=false, cid::Int=0, sync::Bool=false) :: Float64
    (t isa Unitful.Time) && (t = tadjust(clk, t))
    if T == after
        event!(clk, ex, t+clk.time, scope=scope, spawn=spawn)
    elseif T == every
        event!(clk, ex, clk.time, scope=scope, cycle=t, spawn=spawn)
    else
        event!(clk, ex, t, scope=scope, spawn=spawn)
    end
end
event!(ex::Action, t::Number; kw...) = event!(𝐶, ex, t; kw...)
event!(ex::Action, T::Timing, t::Number; kw...) = event!(𝐶, ex, T, t; kw...)


"""
```
event!([clk::AbstractClock], ex::Action, cond::Action; scope::Module=Main)::Float64
```
Schedule a conditional event.

It is executed immediately if the conditions are met, else the condition is
checked at each clock tick Δt. A conditional event is triggered only once. After
that it is removed from the clock. If no sampling rate Δt is setup, a default
sampling rate is setup depending on the scale of the remaining simulation time
``Δt = scale(t_r)/100`` or ``0.01`` if ``t_r = 0``.

# Arguments
- `clk::AbstractClock`: if no clock is supplied, the event is scheduled to 𝐶,
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
Clock thread 1 (+ 0 ac): state=Simulate.Undefined(), t=0.0 , Δt=0.0 , prc:0
  scheduled ev:0, cev:0, sampl:0

julia> event!(c, Fun((x)->println(tau(x), ": now I'm triggered"), c), Fun(>=, Fun(tau, c), 5))
0.0

# julia> c              # a conditional event turns sampling on  ⬇
Clock thread 1 (+ 0 ac): state=Simulate.Undefined(), t=0.0 , Δt=0.01 , prc:0
  scheduled ev:0, cev:1, sampl:0

julia> run!(c, 10)   # sampling is not exact, so it takes 501 sample steps to fire the event
5.009999999999938: now I'm triggered
"run! finished with 0 clock events, 501 sample steps, simulation time: 10.0"

julia> c   # after the event sampling is again switched off ⬇
Clock thread 1 (+ 0 ac): state=Simulate.Idle(), t=10.0 , Δt=0.0 , prc:0
  scheduled ev:0, cev:0, sampl:0
```
"""
function event!(clk::AbstractClock, ex::Action, cond::Action; scope::Module=Main, spawn=false)
    if busy(clk) && all(evExec(cond))   # all conditions met
        evExec(ex)                      # execute immediately
    else
        assign(clk, DiscreteCond(cond, ex, scope), spawn ? spawnid(clk) : 0)
    end
    return tau(clk)
end
event!( ex::Action, cond::Action; kw...) = event!(𝐶, ex, cond; kw...)


"""
    spawnid(clk::Clock) :: Int

Return a random number out of the thread ids of all available parallel clocks.
This is used for `spawn`ing tasks or events to them.

!!! note
    This function may be used for workload balancing between threads
    in the future.
"""
function spawnid(clk::Clock) :: Int
    if isempty(clk.ac)
        return 1
    else
        return rand(rng, (1, (i.id for i in clk.ac)...))
    end
end

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

#
# There are 5 paths for assigning a schedule to a clock
# 1: Clock to itself
# 2: ActiveClock to itself
# 3: Clock to ActiveClock
# 4: ActiveClock to Clock
# 5: ActiveClock to another ActiveClock (this is 4 -> 3)
#

function assign(clk::Clock, ev::DiscreteEvent, id::Int=0)
    if id == 0     # path 1
        t = ev.t
        while any(i->i==t, values(clk.sc.events)) # in case an event at that time exists
            t = nextfloat(float(t))                  # increment scheduled time
        end
        return clk.sc.events[ev] = t
    else                 # path 3
        put!(clk.ac[id].forth, Register(ev))
        return ev.t
    end
end
function assign(ac::ActiveClock, ev::DiscreteEvent, id::Int=ac.id)
    if id == ac.id     # path 2
        return assign(ac.clock, ev, 0)
    else                 # path 4
        put!(ac.back, Forward(ev, id))
    end
end

function assign(clk::Clock, cond::DiscreteCond, id::Int=0)
    if id == 0
        (clk.Δt == 0) && (clk.Δt = scale(clk.end_time - clk.time)/100)
        push!(clk.sc.cevents, cond)
    else
        put!(clk.ac[id].forth, Register(cond))
    end
end
function assign(ac::ActiveClock, cond::DiscreteCond, id::Int=ac.id)
    if id == ac.id
        assign(ac.clock, cond, 0)
    else
        put!(ac.back, Forward(cond, id))
    end
end

function assign(clk::Clock, sp::Sample, id::Int=0)
    if id == 0
        push!(clk.sc.samples, sp)
    else
        put!(clk.ac[id].forth, Register(sp))
    end
end
function assign(ac::ActiveClock, sp::Sample, id::Int=ac.id)
    if id == ac.id
        assign(ac.clock, sp, 0)
    else
        put!(ac.back, Forward(sp, id))
    end
end
