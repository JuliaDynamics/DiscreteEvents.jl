# Introduction

```@meta
CurrentModule = DiscreteEvents
```

Using `DiscreteEvents.jl` you want to schedule and execute Julia functions or expressions on a time line. Therefore you
1. setup a virtual or a realtime clock,
2. schedule functions (or expressions) as events to it,
3. run the clock to trigger the events.

## Preparations

`DiscreteEvents.jl` is a registered package. You install it to your Julia environment with
```julia-repl
] add DiscreteEvents
```
You can then load it with
```@repl intro
using DiscreteEvents
```

## Setup a clock
Setting up a clock is as easy as
```@repl intro
clk = Clock()
```
You created a [`Clock`](@ref) variable `clk` with a master clock 0 at thread 1 with 0 active clocks (ac) and pretty much everything set to 0, without any scheduled events (ev), conditional events (cev) or sampling events (sampl).

## Schedule events
You can now schedule events to your clock. In order to demonstrate how it works we setup a small simulation. We want to simulate the easy life of a pet in the morning. First we define some data structures for pets:
```@example intro
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
```
Then we need an API for Pet since we do not want to access its state directly.
```@example intro
using Printf
state(p) = p.state
speak(p, n) = @printf("%5.2f %s: %s\n", tau(p.clk), p.name, p.speak^n)

function setstate!(p::Pet, q::PetState)
    p.state = q
    @printf("%5.2f %s: %s\n", tau(p.clk), p.name, repr(p.state))
end
```
We describe the behaviour of the pet in time with some state-transition functions:
```@example intro
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
```
We use here two features of `DiscreteEvents`:
- with [`event!`](@ref) we schedule functions to the clock,
- [`fun`](@ref) encapsulates those functions and their arguments in a function closure, so that they can be executed at event time. In this case – in order to have a current state at event time – we encapsulate `state(p)` into another `fun` closure.

## Run the clock

Then we setup a pet, schedule the first event on it and run the clock:
```@example intro
using Random # hide
Random.seed!(123) # hide
snoopy = Pet(clk, "Snoopy", Sleeping(), "huff")
event!(clk, fun(doit!, snoopy, snoopy.state, LeapUp()), after, 5)
```
```julia
julia> run!(clk, 25)
 5.00 Snoopy: Running()
 8.84 Snoopy: huffhuffhuffhuffhuff
 9.78 Snoopy: Scuffing()
11.13 Snoopy: Running()
11.92 Snoopy: huffhuff
12.55 Snoopy: Sleeping()
19.17 Snoopy: Running()
22.10 Snoopy: huffhuffhuffhuffhuff
22.16 Snoopy: Scuffing()
22.69 Snoopy: Running()
22.91 Snoopy: huffhuff
23.24 Snoopy: Sleeping()
"run! finished with 12 clock events, 0 sample steps, simulation time: 25.0"
```

# Processes and implicit events
