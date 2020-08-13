#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#
# -------------------------------------------
#
# This is the first introductory pet example.
# We simulate the easy life of a pet in the morning with a process-based simulation.
#

using DiscreteEvents, Printf, Random

# again we need some data structures
abstract type PetState end
struct Sleeping  <: PetState end
struct Scuffing  <: PetState end
struct Running   <: PetState end

mutable struct Pet
    clk::Clock
    name::String
    state::PetState
    speak::String
end

# the pet API is now different, see documentation
speak(p, n) = now!(p.clk, fun(println, @sprintf("%5.2f %s: %s", tau(p.clk), p.name, p.speak^n)))

function setstate!(p::Pet, q::PetState)
    p.state = q
    now!(p.clk, fun(println, @sprintf("%5.2f %s: %s", tau(p.clk), p.name, repr(p.state))))
end

# the pet function describes the sequence of states a pet lives through
function pet(clk::Clock, p::Pet)
    setstate!(p, Running());  delay!(clk,  5*rand())
    speak(p, 5);              delay!(clk,    rand())  # get hungry
    setstate!(p, Scuffing()); delay!(clk,  2*rand())
    setstate!(p, Running());  delay!(clk,  2*rand())
    speak(p, 2);              delay!(clk,  2*rand())  # get weary
    setstate!(p, Sleeping()); delay!(clk, 10*rand())
end

# we set it all up and run the simulation
clk = Clock(t0=5)
Random.seed!(123)
snoopy = Pet(clk, "Snoopy", Sleeping(), "huff")
process!(clk, Prc(1, pet, snoopy));
run!(clk, 20)
