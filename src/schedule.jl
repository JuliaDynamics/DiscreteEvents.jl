#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

"""
```
event!([clk], ex, t; <keyword arguments>)
event!([clk], ex, T, t; <keyword arguments>)
```
Schedule an event for a given simulation time.

# Arguments
- `clk<:AbstractClock`: clock, it not supplied, the event is scheduled to 𝐶,
- `ex<:Action`: an expression or function or a tuple of them,
- `T::Timing`: a timing, one of `at`, `after` or `every`,
- `t<:Number`: simulation time, if t < clk.time set t = clk.time,

# Keyword arguments
- `cycle<:Number=0.0`: repeat cycle time for an event,
- `cid::Int=clk.id`: if cid ≠ clk.id, assign the event to the parallel clock
    with id == cid. This overrides `spawn`,
- `spawn::Bool=false`: if true, spawn the event at other available threads,
- `sync::Bool=false`: if true, force a synchronization of all parallel clocks
    before executing the event.

# Examples
```jldoctest
julia> using DiscreteEvents, Unitful

julia> import Unitful: s, minute, hr

julia> myfunc(a, b) = a+b
myfunc (generic function with 1 method)

julia> event!(𝐶, fun(myfunc, 1, 2), 1) # a 1st event to 1

julia> event!(𝐶, fun(myfunc, 2, 3), 1) #  a 2nd event to the same time

julia> event!(𝐶, fun(myfunc, 3, 4), 1s)
Warning: clock has no time unit, ignoring units

julia> setUnit!(𝐶, s)
0.0 s

julia> event!(𝐶, fun(myfunc, 4, 5), 1minute)

julia> event!(fun(myfunc, 5, 6), after, 1hr)

```
"""
function event!(clk::CL, ex::A, t::U; cycle::V=0.0,
                cid::Int=clk.id, spawn::Bool=false, sync::Bool=false) where {CL<:AbstractClock,A<:Action,U<:Number,V<:Number}
    t = _tadjust(clk, t)
    cycle = _tadjust(clk, cycle)
    t = max(t, _tadjust(clk, tau(clk)))

    if cid == clk.id && spawn  # evaluate spawn only if cid == clk.id
        cid = _spawnid(clk)
    end
    _assign(clk, DiscreteEvent(ex, t, cycle), cid)
end
function event!(clk::CL, ex::A, T::Timing, t::U;
                cid::Int=clk.id, spawn::Bool=false, sync::Bool=false) where {CL<:AbstractClock,A<:Action,U<:Number}
    t = _tadjust(clk, t)
    if T == after
        event!(clk, ex, t+clk.time, cid=cid, spawn=spawn, sync=sync)
    elseif T == every
        event!(clk, ex, clk.time, cycle=t, cid=cid, spawn=spawn, sync=sync)
    else
        event!(clk, ex, t, cid=cid, spawn=spawn, sync=sync)
    end
end
event!(ex::A, t::N; kw...) where {A<:Action,N<:Number} = event!(𝐶, ex, t; kw...)
event!(ex::A, T::Timing, t::N; kw...) where {A<:Action,N<:Number} = event!(𝐶, ex, T, t; kw...)


"""
    event!([clk], ex, cond; <keyword arguments>)

Schedule ex as a conditional event, conditions cond get evaluated at each clock tick.

# Arguments
- `clk<:AbstractClock`: if no clock is supplied, the event is scheduled to 𝐶,
- `ex<:Action`: an expression or function or a tuple of them,
- `cond<:Action`: a condition is true if all functions or expressions therein return true,
- `cid::Int=clk.id`: assign the event to the parallel clock cid. This overrides `spawn`,
- `spawn::Bool=false`: if true, spawn the event at other available threads.

# Examples
```jldoctest
julia> using DiscreteEvents

julia> c = Clock()   # create a new clock
Clock 1: state=DiscreteEvents.Undefined(), t=0.0 , Δt=0.01 , prc:0
  scheduled ev:0, cev:0, sampl:0

julia> event!(c, fun((x)->println(tau(x), ": now I'm triggered"), c), fun(>=, fun(tau, c), 5))

julia> run!(c, 10)   # sampling is not exact, so it takes 502 sample steps to fire the event
5.009999999999938: now I'm triggered
"run! finished with 0 clock events, 502 sample steps, simulation time: 10.0"
```
"""
function event!(clk::T, ex::A, cond::C;
                cid::Int=clk.id, spawn=false) where {T<:AbstractClock,A<:Action,C<:Action}
    if _busy(clk) && all(_evaluate(cond))   # all conditions met
        _evaluate(ex)                      # execute immediately
    else
        if cid == clk.id && spawn  # evaluate spawn only if cid == clk.id
            cid = _spawnid(clk)
        end
        _assign(clk, DiscreteCond(cond, ex), cid)
    end
    return nothing
end
event!( ex::A, cond::C; kw...) where {A<:Action,C<:Action} = event!(𝐶, ex, cond; kw...)

"""
    periodic!([clk], ex, Δt; spawn)

Register a function or expression for periodic execution at the clock`s sample rate.

# Arguments
- `clk<:AbstractClock`: if not supplied, it registers on 𝐶,
- `ex<:Action`: an expression or function or a tuple of them,
- `Δt<:Number=clk.Δt`: set the clock's sampling rate, if no Δt is given, it takes
    the current sampling rate, if that is 0, it calculates one,
- `spawn::Bool=false`: if true, spawn the periodic event to other available threads.
"""
function periodic!(clk::Clock, ex::T, Δt::U=clk.Δt;
                   spawn=false) where {T<:Action,U<:Number}
   # clk.Δt = Δt == 0 ? _scale(clk.end_time - clk.time)/100 : Δt
   if Δt == 0  # pick a sample rate
       clk.Δt = clk.evcount == 0 ? 0.01 : _scale(clk.time/clk.evcount)/100
   end
    _assign(clk, Sample(ex), spawn ? _spawnid(clk) : 0)
end
periodic!(ex::T, Δt::U=𝐶.Δt; kw...) where {T<:Action,U<:Number} = periodic!(𝐶, ex, Δt; kw...)
periodic!(ac::ActiveClock, ex::T, Δt::U=ac.clock.Δt; kw...) where {T<:Action,U<:Number} = periodic!(ac.clock, ex, Δt; kw...)
periodic!(rtc::RTClock, ex::T, Δt::U=rtc.clock.Δt; kw...) where {T<:Action,U<:Number} = periodic!(rtc.clock, ex, Δt; kw...)

# Return a random number out of the thread ids of all available parallel clocks.
# This is used for `spawn`ing tasks or events to them.
function _spawnid(clk::Clock) :: Int
    if isempty(clk.ac)
        return 0
    else
        return rand(rng, (0, (i.id for i in clk.ac)...))
    end
end

# calculate the scale from a given number
function _scale(n::T)::Float64 where {T<:Number}
    if n > 0
        i = 1.0
        while !(10^i ≤ n < 10^(i+1))
            n < 10^i ? i -= 1 : i += 1
        end
        return 10^i
    else
        return 1.0
    end
end

# ---------------------------------------------------------------
# assign and register events and samples to a clock
# ---------------------------------------------------------------
# There are several ways to do it:
# 1. assign it directly to a clock or
# 2. assign it via a channel to another one, if given a different id.
#    In this case the event is sent over the channel to the target clock.
#    - The master clock (id=0) can directly send to an active clock.
#    - An active clock can send directly to master.
#    - An active clock can only send via master to another active clock.
_assign(c::S, ev::T) where {S<:AbstractClock, T<:AbstractEvent} = _register!(c, ev)
function _assign(c::S, ev::T, id::Int) where {S<:AbstractClock, T<:AbstractEvent}
    if id == c.id
        _register!(c, ev)       # 1: register it to yourself
    else
        _register(c, ev, id)    # 2: register it to another clock
    end
end

# function barrier: register an event directly to a clock.
function _register!(c::Clock, ev::DiscreteEvent)
    t = ev.t
    while any(i->i==t, values(c.sc.events)) # in case an event at that time exists
        t = nextfloat(float(t))                  # increment scheduled time
    end
    c.sc.events[ev] = t
    return
end
function _register!(c::Clock, cond::DiscreteCond)
    # (c.Δt == 0) && (c.Δt = _scale(c.end_time - c.time)/100)
    if c.Δt == 0  # pick a sample rate
        c.Δt = c.evcount == 0 ? 0.01 : _scale(c.time/c.evcount)/100
    end
    push!(c.sc.cevents, cond)
    return
end
_register!(c::Clock, sp::Sample) = ( push!(c.sc.samples, sp); nothing )
_register!(ac::ActiveClock, ev::T) where {T<:AbstractEvent} = _register!(ac.clock, ev)
_register!(rtc::RTClock, ev::T) where {T<:AbstractEvent} = _register!(rtc.clock, ev)

# Register an event to another clock via a channel.
# - c::Clock: a master clock can forward events to active clocks,
# - ac::ActiveClock: active clocks can forward events only through master,
#                    he then does the distribution for them,
# - ev<:AbstractEvent: the event to register,
# - id::Int: the id of the clock it should get registered to.
function _register(c::Clock, ev::T, id::Int) where {T<:AbstractEvent}
    if c.id == id
        _register!(c, ev)
    elseif c.id == 1
        i = findfirst(x->x.thread==id, c.ac)
        isnothing(i) ? _register!(c, ev) : put!(c.ac[i].forth, Register(ev))
    else
        _register(c.master[], ev, id)
    end
end
function _register(ac::ActiveClock, ev::T, id::Int) where {T<:AbstractEvent}
    _register(ac.clock, ev, id)
end
