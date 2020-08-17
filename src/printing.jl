#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

const state = Dict(
    Undefined() => :undefined,
    Idle() => :idle,
    Busy() => :busy,
    Halted() => :halted
    )

function c_id(c::Clock)
    if (c.id == 1) && isa(c.ac, Vector{ClockChannel}) && !isempty(c.ac)
        return "Clock 1 (+$(length(c.ac))): "
    else
        return "Clock $(c.id): "
    end
end

function c_info(c::Clock)
    s1 = "state=$(repr(state[c.state])), "
    s2 = "t=$(round(c.time, sigdigits=4))$(c.unit), "
    s3 = "Δt=$(round(c.Δt, sigdigits=4))$(c.unit)"
    return s1*s2*s3
end

function c_info(rtc::RTClock)
    s1 = "state=$(repr(state[rtc.clock.state])), "
    s2 = "t=$(round(rtc.time, sigdigits=4)) s, "
    s3 = "T=$(round(rtc.T, sigdigits=4)) s"
    return s1*s2*s3
end

function sc_info(c::Clock)
    sc1 = "ev:$(length(c.sc.events)), "
    sc2 = "cev:$(length(c.sc.cevents)), "
    sc3 = "sampl:$(length(c.sc.samples))"
    return sc1*sc2*sc3
end

function pretty_print(c::Clock)
    s1 = c_id(c)
    s2 = c_info(c)
    s3 = ", prc:$(length(c.processes))"
    return s1*s2*s3*"\n  scheduled "*sc_info(c)*"\n"
end

function pretty_print(ac::ActiveClock)
    s1 = "Active clock $(ac.id): "
    s2 = c_info(ac.clock)
    s3 = ", prc:$(length(ac.clock.processes))"
    return s1*s2*s3*"\n   scheduled "*sc_info(ac.clock)*"\n"
end

function pretty_print(rtc::RTClock)
    s1 = "RTClock $(rtc.id) on thread $(rtc.thread): "
    s2 = c_info(rtc)
    s3 = ", prc:$(length(rtc.clock.processes))"
    return s1*s2*s3*"\n   scheduled "*sc_info(rtc.clock)*"\n"
end

Base.show(io::IO, c::CLK) where {CLK<:AbstractClock} = print(io, pretty_print(c))

"""
    prettyClock(on::Bool)

Switch pritty printing for clocks on and off.
"""
function prettyClock(on::Bool)
    m = which(show, (IO, AbstractClock))
    if on &&  m.module == Base
        eval(:(Base.show(io::IO, c::CLK) where {CLK<:AbstractClock} = print(io, pretty_print(c))))
    elseif !on && m.module == DiscreteEvents
        Base.delete_method(m)
    else
        nothing
    end
end
