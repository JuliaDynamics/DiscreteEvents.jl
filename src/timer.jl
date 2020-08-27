#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

# -------------------------------------------------------------------
# methods for RTClocks
# -------------------------------------------------------------------
tau(rtc::RTClock) = rtc.time

"""
    resetClock!(rtc::RTClock)

Reset a real time clock. Set its time to zero and delete all scheduled and
sampling events.
"""
resetClock!(rtc::RTClock) = put!(rtc.cmd, Reset(false))

# -------------------------------------------------------------------
# RTClock state machine operations
# -------------------------------------------------------------------

# reset an rt clock
function step!(RTC::RTClock, ::Union{Idle, Busy}, ::Reset) 
    RTC.t0 = time_ns()*1e-9
    RTC.clock.evcount = 0
    RTC.clock.scount = 0
end

# register an event to the rt clock
step!(RTC::RTClock, ::Union{Idle, Busy}, σ::Register) = _register!(RTC.clock, σ.x)

# fallback transition
step!(RTC::RTClock, q::ClockState, σ::ClockEvent) = error("transition q=$q, σ=$σ not implemented")

# -------------------------------------------------------------------
# event loop for an RTClock.
# -------------------------------------------------------------------
function _RTClock(rtc::RTClock)
    sf = Array{Base.StackTraces.StackFrame,1}[]
    exc = nothing
    rtc.clock.state = Idle()
    rtc.task = current_task()

    while true
        if isready(rtc.cmd)
            σ = take!(rtc.cmd)
            if σ isa Stop
                break
            elseif σ isa Diag
                put!(rtc.back, Response((exc, sf)))
            elseif handle_exceptions()
                try
                    step!(rtc, rtc.clock.state, σ)
                catch exc
                    sf = stacktrace(catch_backtrace())
                    @warn "clock $(rtc.id), thread $(rtc.thread) exception: $exc"
                end
            else
                step!(rtc, rtc.clock.state, σ)
            end
        end
        rtc.time = time_ns()*1e-9 - rtc.t0
        while !isempty(rtc.clock.sc.samples) && rtc.clock.tn ≤ rtc.time
            _tick!(rtc.clock)
            rtc.clock.tn += rtc.clock.Δt
        end
        while !isempty(rtc.clock.sc.events) && _nextevtime(rtc.clock) ≤ rtc.time
            _event!(rtc.clock)
        end
        wait(rtc.Timer)
    end
    close(rtc.Timer)
end

# ---------------------------------------------------------
# starting and destroying real time clocks
# ---------------------------------------------------------
"""
    createRTClock(T::Float64, id::Int, thrd::Int=nthreads(); ch_size::Int=256)

Create, start and return a real time Clock.

The clock takes the current system time and starts to count in seconds with
the given period `T`. Events or sampling functions can then be scheduled to it.

# Arguments
- `T::Float64`:           period (clock resolution) in seconds, T ≥ 0.001
- `id::Int`:              clock identification number other than 0:(nthreads()-1)
- `thrd::Int=nthreads()`: thread, the clock task should run in
- `ch_size::Int=256`:     clock communication channel size
"""
function createRTClock(T::Float64, id::Int, thrd::Int=nthreads(); ch_size::Int=256)
    T ≥ 0.001 || throw(ArgumentError("RTClock cannot have a period of $T < 0.001 seconds"))
    id ∉ 0:(nthreads()-1) || throw(ArgumentError("RTClock id $id forbidden!"))
    rtc = RTClock(
            Timer(T, interval=T), Clock(),
            Channel{ClockEvent}(ch_size), Channel{ClockEvent}(ch_size),
            id, thrd, 0.0, time_ns()*1e-9, T, current_task())
    rtc.clock.id = id
    onthread(thrd, wait=false) do
        _RTClock(rtc)
    end
    return rtc
end

"""
    stopRTClock(rtc::RTClock)

Stop a real time clock.
"""
stopRTClock(rtc::RTClock) = put!(rtc.cmd, Stop())
