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
# We simulate the easy life of a pet in the morning with an event-based simulation.
#

using DiscreteEvents, Printf, Random

# First we define some data structures for pets:
abstract type PetState end
struct Sleeping  <: PetState end
struct Scuffing  <: PetState end
struct Running   <: PetState end

abstract type PetEvent end
struct GetWeary  <: PetEvent end
struct GetHungry <: PetEvent end
struct Scuff     <: PetEvent end
struct LeapUp    <: PetEvent end
struct Sleep     <: PetEvent end

mutable struct Pet
    clk::Clock
    name::String
    state::PetState
    speak::String
end

# Then we need an API for Pet since we do not want to access its state directly.
state(p) = p.state
speak(p, n) = @printf("%5.2f %s: %s\n", tau(p.clk), p.name, p.speak^n)

function setstate!(p::Pet, q::PetState)
    p.state = q
    @printf("%5.2f %s: %s\n", tau(p.clk), p.name, repr(p.state))
end

# We describe the behaviour of the pet in time with some state-transition functions:
function doit!(p::Pet, ::Sleeping, ::LeapUp)   # leap up after sleeping
    setstate!(p, Running())
    event!(p.clk, fun(doit!, p, fun(state, p), GetHungry()), after, 5*rand())
end

function doit!(p::Pet, ::Scuffing, ::LeapUp)   # leap up while scuffing
    setstate!(p, Running())
    event!(p.clk, fun(doit!, p, fun(state, p), GetWeary()), after, 2*rand())
end

function doit!(p::Pet, ::Running, ::GetHungry) # get hungry while running
    speak(p, 5)
    event!(p.clk, fun(doit!, p, fun(state, p), Scuff()), after, rand())
end

function doit!(p::Pet, ::Running, ::GetWeary)  # get weary while running
    speak(p, 2)
    event!(p.clk, fun(doit!, p, fun(state, p), Sleep()), after, 2*rand())
end

function doit!(p::Pet, ::Running, ::Scuff)     # scuff after running
    setstate!(p, Scuffing())
    event!(p.clk, fun(doit!, p, fun(state, p), LeapUp()), after, 2*rand())
end

function doit!(p::Pet, ::Running, ::Sleep)     # sleep after running
    setstate!(p, Sleeping())
    event!(p.clk, fun(doit!, p, fun(state, p), LeapUp()), after, 10*rand())
end

# Then we setup a clock and a pet, schedule the first event on it and run the clock:
Random.seed!(123)     # we seed the random number generator for reprodicibility
clk = Clock()
snoopy = Pet(clk, "Snoopy", Sleeping(), "huff")
event!(clk, fun(doit!, snoopy, snoopy.state, LeapUp()), after, 5)
run!(clk, 25)
