#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

"""
```
event!([clk::CL], ex::Action, t::Number; scope::Module=Main, cycle::Number=0.0,
        cid::Int=clk.id, spawn=false, sync::Bool=false) where {CL<:AbstractClock}
event!([clk::CL], ex::Action, T::Timing, t::Number; scope::Module=Main,
        cid::Int=clk.id, spawn=false, sync::Bool=false) where {CL<:AbstractClock}
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
- `cid::Int=clk.id`: if cid ≠ clk.id, assign the event to the parallel clock
    with id == cid. This overrides `spawn`,
- `spawn::Bool=false`: if true, spawn the event at other available threads,
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
function event!(clk::CL, ex::Action, t::Number; scope::Module=Main, cycle::Number=0.0,
                cid::Int=clk.id, spawn::Bool=false, sync::Bool=false) where {CL<:AbstractClock}
    t = tadjust(clk, t)
    cycle = tadjust(clk, cycle)
    t = max(t, clk.time)

    if cid == clk.id && spawn  # evaluate spawn only if cid == clk.id
        cid = spawnid(clk)
    end
    assign(clk, DiscreteEvent(ex, scope, t, cycle), cid)
end
function event!(clk::CL, ex::Action, T::Timing, t::Number; scope::Module=Main,
                cid::Int=clk.id, spawn::Bool=false, sync::Bool=false) where {CL<:AbstractClock}
    t = tadjust(clk, t)
    if T == after
        event!(clk, ex, t+clk.time, scope=scope, cid=cid, spawn=spawn, sync=sync)
    elseif T == every
        event!(clk, ex, clk.time, scope=scope, cycle=t, cid=cid, spawn=spawn, sync=sync)
    else
        event!(clk, ex, t, scope=scope, cid=cid, spawn=spawn, sync=sync)
    end
end
event!(ex::Action, t::Number; kw...) = event!(𝐶, ex, t; kw...)
event!(ex::Action, T::Timing, t::Number; kw...) = event!(𝐶, ex, T, t; kw...)


"""
```
event!([clk::T], ex::Action, cond::Action; scope::Module=Main,
        cid::Int=clk.id, spawn=false) where {T<:AbstractClock}
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
- `cid::Int=clk.id`: if cid ≠ clk.id, assign the event to the parallel clock
    with id == cid. This overrides `spawn`,
- `spawn::Bool=false`: if true, spawn the event at other available threads.

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
function event!(clk::T, ex::Action, cond::Action; scope::Module=Main,
                cid::Int=clk.id, spawn=false) where {T<:AbstractClock}
    if busy(clk) && all(evExec(cond))   # all conditions met
        evExec(ex)                      # execute immediately
    else
        if cid == clk.id && spawn  # evaluate spawn only if cid == clk.id
            cid = spawnid(clk)
        end
        assign(clk, DiscreteCond(cond, ex, scope), cid)
    end
    return nothing
end
event!( ex::Action, cond::Action; kw...) = event!(𝐶, ex, cond; kw...)

"""
```
periodic!([clk::Clock], ex::T, Δt::Number=clk.Δt;
        scope::Module=Main, spawn=false) where {T<:Action}
periodic!(ac::ActiveClock, ex::T, Δt::Number=ac.clock.Δt; kw...) where {T<:Action}
```
Register a function or expression for periodic execution at the clock`s sample rate.

# Arguments
- `clk::Clock`, `ac::ActiveClock`: if not supplied, it samples on 𝐶,
- `ex<:Action`: an expression or function or a tuple of them,
- `Δt::Number=clk.Δt`: set the clock's sampling rate, if no Δt is given, it takes
    the current sampling rate, if that is 0, it calculates one,
- `scope::Module=Main`: optional, an evaluation scope for a given expression.
"""
function periodic!(clk::Clock, ex::T, Δt::Number=clk.Δt;
                 scope::Module=Main, spawn=false) where {T<:Action}
    clk.Δt = Δt == 0 ? scale(clk.end_time - clk.time)/100 : Δt
    assign(clk, Sample(ex, scope), spawn ? spawnid(clk) : 0)
end
periodic!(ex::T, Δt::Number=𝐶.Δt; kw...) where {T<:Action} = periodic!(𝐶, ex, Δt; kw...)
periodic!(ac::ActiveClock, ex::T, Δt::Number=ac.clock.Δt; kw...) where {T<:Action} = periodic!(ac.clock, ex, Δt; kw...)

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
        return 0
    else
        return rand(rng, (0, (i.id for i in clk.ac)...))
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

# ---------------------------------------------------------------
# assign and register events and samples to a clock
# ---------------------------------------------------------------

"""
    assign(c::S, ev::T, id::Int=c.id) where {S<:AbstractClock, T<:AbstractEvent}

Assign an event to a clock.

There are several ways to do it:
1. assign it directly to a clock or an active clock or
2. assign it via a clock via a clock to another one, if given a different id.
    In this case the event is sent over the channel to the target clock.
    - The master clock (id=0) can directly send to an active clock.
    - An active clock can send directly to master.
    - An active clock can only send via master to another active clock.
"""
function assign(c::S, ev::T, id::Int=c.id) where {S<:AbstractClock, T<:AbstractEvent}
    if id == c.id
        register!(c, ev)       # 1: register it yourself
    else
        register(c, ev, id)    # 2: register it to another clock
    end
end

"""
```
register!(c::Clock, ev::DiscreteEvent)
register!(c::Clock, cond::DiscreteCond)
register!(c::Clock, sp::Sample)
register!(ac::ActiveClock, ev::T) where {T<:AbstractEvent}
```
Register a concrete event directly to a clock.
"""
function register!(c::Clock, ev::DiscreteEvent)
    t = ev.t
    while any(i->i==t, values(c.sc.events)) # in case an event at that time exists
        t = nextfloat(float(t))                  # increment scheduled time
    end
    c.sc.events[ev] = t
    return
end
function register!(c::Clock, cond::DiscreteCond)
    (c.Δt == 0) && (c.Δt = scale(c.end_time - c.time)/100)
    push!(c.sc.cevents, cond)
    return
end
register!(c::Clock, sp::Sample) = ( push!(c.sc.samples, sp); nothing )
register!(ac::ActiveClock, ev::T) where {T<:AbstractEvent} = register!(ac.clock, ev)

"""
```
register(c::Clock, ev::T, id::Int) where {T<:AbstractEvent}
register(ac::ActiveClock, ev::T, id::Int) where {T<:AbstractEvent}
```
Register an event to another clock via a channel.

# Arguments
- `c::Clock`: a master clock can forward events to active clocks,
- `ac::ActiveClock`: active clocks can forward events only through master, he then
    does the distribution for them,
- `ev::AbstractEvent`: the event to register,
- `id::Int`: the id of the clock it should get registered to.
"""
function register(c::Clock, ev::T, id::Int) where {T<:AbstractEvent}
    if id > 0 && threadid() == 1       # only master can forward events
        if id ≤ length(c.ac)
            @inbounds put!(c.ac[id].forth, Register(ev))
            return
        end
    end
    register!(c, ev)                   # otherwise take it yourself
end
function register(ac::ActiveClock, ev::T, id::Int) where {T<:AbstractEvent}
    if ac.id == id                     # if id is your id
        register!(ac.clock, ev)        # take it yourself
    elseif ac.clock.state == Busy()    # if master handles its channels
        put!(ac.back, Forward(ev, id)) # put it over the channel
        return
    else
        register(ac.master[], ev, id)  # otherwise call him directly
    end
end
