#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

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
