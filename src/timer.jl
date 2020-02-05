#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

"""
    RTC::Vector{ClockChannel}

Real time clocks are registered to RTC and can be accessed and operated
through it.
"""
const RTC = Vector{ClockChannel}()
