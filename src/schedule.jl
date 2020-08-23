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
event!([clk], ex, t, cy; <keyword arguments>)
event!([clk], ex, T, t; <keyword arguments>)
```
Schedule an event for a given time. 

If `t` is a `Distribution`, time is evaluated as `rand(t)`.  If `cy` 
is a `Distribution`, time is evaluated for each repetition as 
`rand(cy)`. If the evaluated time ≤ clk.time, the event is scheduled 
at `clk.time`.

# Arguments
- `clk<:AbstractClock`: clock, it not supplied, the event is scheduled to 𝐶,
- `ex<:Action`: an expression or function or a tuple of them,
- `T::Timing`: a timing, one of `at`, `after` or `every`,
- `t`: event time, `Number` or `Distribution`,
- `cy`: repeat cycle, `Number` or `Distribution`.

# Keyword arguments
- `cid::Int=clk.id`: if cid ≠ clk.id, assign the event to the parallel clock
    with id == cid. This overrides `spawn`,
- `spawn::Bool=false`: if true, spawn the event at other available threads,

# Examples
```jldoctest
julia> using DiscreteEvents, Distributions, Random

julia> Random.seed!(123);

julia> c = Clock()
Clock 1: state=:idle, t=0.0, Δt=0.01, prc:0
  scheduled ev:0, cev:0, sampl:0

julia> f(x) = x[1] += 1
f (generic function with 1 method)

julia> a = [0]
1-element Array{Int64,1}:
 0

julia> event!(c, fun(f, a), 1)                     # 1st event at 1

julia> event!(c, fun(f, a), at, 2)                 # 2nd event at 2

julia> event!(c, fun(f, a), after, 3)              # 3rd event after 3

julia> event!(c, fun(f, a), every, Exponential(3)) # Poisson process with λ=1/3

julia> run!(c, 50)
"run! finished with 26 clock events, 0 sample steps, simulation time: 50.0"

julia> a
1-element Array{Int64,1}:
 26
```
"""
function event!(clk::CL, ex::A, t::U; # 1st case, t isa Number
                cid::Int=clk.id, spawn::Bool=false) where {CL<:AbstractClock,A<:Action,U<:Number}
    t = _tadjust(clk, t)
    t = max(t, _tadjust(clk, tau(clk)))
    _assign(clk, DiscreteEvent(ex, t, nothing), _cid(clk,cid,spawn))
end

# 2nd case, x isa Distribution
function event!(clk::CL, ex::A, x::X;
    cid::Int=clk.id, spawn::Bool=false) where {CL<:AbstractClock,A<:Action,X<:Distribution}
    t = max(rand(x), _tadjust(clk, tau(clk)))
    _assign(clk, DiscreteEvent(ex, t, nothing), _cid(clk,cid,spawn))
end

# 3rd case, t and cy are Numbers
function event!(clk::CL, ex::A, t::U, cy::V;
    cid::Int=clk.id, spawn::Bool=false) where {CL<:AbstractClock,A<:Action,U<:Number,V<:Number}
    t = _tadjust(clk, t)
    cy = _tadjust(clk, cy)
    t = max(t, _tadjust(clk, tau(clk)))
    _assign(clk, DiscreteEvent(ex, t, cy), _cid(clk,cid,spawn))
end

# 4th case, t isa Number, cy isa Distribution
function event!(clk::CL, ex::A, t::U, cy::V;
    cid::Int=clk.id, spawn::Bool=false) where {CL<:AbstractClock,A<:Action,U<:Number,V<:Distribution}
    t = _tadjust(clk, t)
    t = max(t, _tadjust(clk, tau(clk)))
    _assign(clk, DiscreteEvent(ex, t, cy), _cid(clk,cid,spawn))
end

# 5th case, t and cy are both Distributions
function event!(clk::CL, ex::A, t::U, cy::V;
    cid::Int=clk.id, spawn::Bool=false) where {CL<:AbstractClock,A<:Action,U<:Distribution,V<:Distribution}
    t = max(rand(t), _tadjust(clk, tau(clk)))
    _assign(clk, DiscreteEvent(ex, t, cy), _cid(clk,cid,spawn))
end

# 6th case, Timing and Number
function event!(clk::CL, ex::A, T::Timing, t::U; kw...) where {CL<:AbstractClock,A<:Action,U<:Number}
    t = _tadjust(clk, t)
    if T == after
        event!(clk, ex, clk.time+t; kw...)
    elseif T == every
        event!(clk, ex, t, t; kw...)
    else
        event!(clk, ex, t; kw...)
    end
end

# 7th case, Timing and Distribution
function event!(clk::CL, ex::A, T::Timing, x::X; kw...) where {CL<:AbstractClock,A<:Action,X<:Distribution}
    if T == after
        event!(clk, ex, clk.time+rand(x); kw...)
    elseif T == every
        event!(clk, ex, rand(x), x; kw...)
    else
        event!(clk, ex, rand(x); kw...)
    end
end
# 7 cases to default clock
event!(ex::A, t::N; kw...) where {A<:Action,N<:Number} = event!(𝐶, ex, t; kw...)
event!(ex::A, x::X; kw...) where {A<:Action,X<:Distribution} = event!(𝐶, ex, x; kw...)
event!(ex::A, t::N, cy::U; kw...) where {A<:Action,N<:Number,U<:Number} = event!(𝐶, ex, t, cy; kw...)
event!(ex::A, t::N, cy::U; kw...) where {A<:Action,N<:Number,U<:Distribution} = event!(𝐶, ex, t, cy; kw...)
event!(ex::A, t::N, cy::U; kw...) where {A<:Action,N<:Distribution,U<:Distribution} = event!(𝐶, ex, t, cy; kw...)
event!(ex::A, T::Timing, t::N; kw...) where {A<:Action,N<:Number} = event!(𝐶, ex, T, t; kw...)
event!(ex::A, T::Timing, X::Distribution; kw...) where A<:Action = event!(𝐶, ex, T, X; kw...)

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
Clock 1: state=:idle, t=0.0, Δt=0.01, prc:0
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


# Return a random number out of the thread ids of all available parallel clocks
_spawnid(c::Clock) = isempty(c.ac) ? 1 : rand(rng, 1:(length(c.ac)+1))

# return a valid clock id 
_cid(c::Clock, cid::Int, spawn::Bool) = ifelse(cid == c.id && spawn, _spawnid(c), cid)

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
#             a local clock needs to access the wrapping active clock,
# - ac::ActiveClock: active clocks can forward events only through master,
#                    he then does the distribution for them,
# - ev<:AbstractEvent: the event to register,
# - id::Int: the id of the clock it should get registered to.
function _register(c::Clock, ev::T, id::Int) where {T<:AbstractEvent}
    if c.id == id
        _register!(c, ev)
    elseif c.id == 1
        i = findfirst(x->x.thread==id, c.ac)
        i === nothing ? _register!(c, ev) : put!(c.ac[i].forth, Register(ev))
    else
        _register(c.ac[], ev, id)  # let the active clock do it
    end
end
function _register(ac::ActiveClock, ev::T, id::Int) where {T<:AbstractEvent}
    if ac.id == id
        _register!(ac.clock, ev)
    else
        if ac.master[].state == Busy()      # uses shared variable ↯↯↯
             put!(ac.back, Forward(ev, id)) # shouldn't happen often
        else                                # but still can go wrong !!!
            _register(ac.master[], ev, id)  # needs responsive master
        end                                 # to be solved !!!
    end
end
