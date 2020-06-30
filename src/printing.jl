#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

# - `_show_default[1] = false`: switch pretty printing on,
# - `_show_default[1] = true`: pretty printing off, Julia default on.
const _show_default = [false]

function c_info(c::Clock)
    s1 = "state=$(c.state), "
    s2 = "t=$(round(c.time, sigdigits=4)) $(c.unit), "
    s3 = "Δt=$(round(c.Δt, sigdigits=4)) $(c.unit)"
    return s1*s2*s3
end

function c_info(rtc::RTClock)
    s1 = "state=$(rtc.clock.state), "
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
    if c.id in 1:(nthreads()-1)
        return pretty_print(pclock(c, c.id))
    else
        info = c.id == 0 ? "$(c.id), thrd 1 (+ $(length(c.ac)) ac)" : "$(c.id)"
        s1 = "Clock $info: "
        s2 = c_info(c)
        s3 = ", prc:$(length(c.processes))"
        return s1*s2*s3*"\n  scheduled "*sc_info(c)*"\n"
    end
end

function pretty_print(ac::ActiveClock)
    s1 = "Active clock $(ac.id) on thread $(ac.thread): "
    s2 = c_info(ac.clock)
    s3 = ", prc:$(length(ac.clock.processes))"
    return s1*s2*s3*"\n   scheduled "*sc_info(ac.clock)*"\n"
end

function pretty_print(rtc::RTClock)
    s1 = "Real time clock $(rtc.id) on thread $(rtc.thread): "
    s2 = c_info(rtc)
    s3 = ", prc:$(length(rtc.clock.processes))"
    return s1*s2*s3*"\n   scheduled "*sc_info(rtc.clock)*"\n"
end

function Base.show(io::IO, c::AbstractClock)
    if _show_default[end]
        return Base.show_default(IOContext(io, :compact => false), c)
    else
        return print(io, pretty_print(c))
    end
end
