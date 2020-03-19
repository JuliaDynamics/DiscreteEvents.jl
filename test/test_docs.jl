#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#

println("... doctests  ...")

using Documenter

resetClock!(𝐶)
doctest(DiscreteEvents; manual = false)
