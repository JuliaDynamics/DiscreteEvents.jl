# Introduction

```@meta
CurrentModule = DiscreteEvents
```

`DiscreteEvents.jl` allows you to

1. setup virtual or realtime clocks,
2. schedule events (Julia functions or expressions) to them,
3. run clocks to trigger events.

## Preparations

`DiscreteEvents.jl` is a registered package. You install it to your Julia environment with
```julia-repl
] add DiscreteEvents
```
You can install the development version with
```julia-repl
] add https://github.com/pbayer/DiscreteEvents.jl
```
You can then load it with
```@repl intro
using DiscreteEvents
```

## Setup a clock
Setting up a virtual clock is as easy as
```@repl intro
clk = Clock()
```
You created a [`Clock`](@ref) variable `clk` with a master clock 0 at thread 1 with 0 active clocks (ac) and pretty much everything set to 0, without yet any scheduled events (ev), conditional events (cev) or sampling events (sampl).

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
using Random; Random.seed!(123)     # we seed the random number generator for reprodicibility
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

## Processes and implicit events

`DiscreteEvents` provides also another approach: process-based simulation. In this case we implement the pet behaviour in a single function. For such a simple example this comes out simpler and more convenient:
```@example intro
function pet(clk::Clock, p::Pet)
    setstate!(p, Running());  delay!(clk,  5*rand())
    speak(p, 5);              delay!(clk,    rand())  # get hungry
    setstate!(p, Scuffing()); delay!(clk,  2*rand())
    setstate!(p, Running());  delay!(clk,  2*rand())
    speak(p, 2);              delay!(clk,  2*rand())  # get weary
    setstate!(p, Sleeping()); delay!(clk, 10*rand())
end
```
This describes one pet cycle. After each status change the pet function calls [`delay!`](@ref) for a given timeout on the clock. Note that the `pet` function takes the clock as its first argument. This is required for calling `delay!`.

We have to reimplement our `speak` and `setstate!` functions since now we print from an asynchronous process. With [`now!`](@ref) we let the clock do the printing:
```@example intro
speak(p, n) = now!(p.clk, fun(println, @sprintf("%5.2f %s: %s", tau(p.clk), p.name, p.speak^n)))

function setstate!(p::Pet, q::PetState)
    p.state = q
    now!(p.clk, fun(println, @sprintf("%5.2f %s: %s", tau(p.clk), p.name, repr(p.state))))
end
```
In order to make this work we have to register the pet function to the clock.
```@example intro
resetClock!(clk, t0=5)              # reset the clock, we start at 5
Random.seed!(123)                   # reseed the random generator
setstate!(snoopy, Sleeping())       # set snoopy sleeping
process!(clk, Prc(1, pet, snoopy));
```
We use `process!` and `Prc` to register `pet` to the clock and to start it as an asynchronous process (as a task). Then we can run the clock as before:
```julia
julia> run!(clk, 20)
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
"run! finished with 24 clock events, 0 sample steps, simulation time: 25.0"
```
We got the same output – with more implicit events for the `delay!` and `now!` calls).

## Evaluation

There is no point in doing simulations with such simple sequential examples, but if we do the same with more pets operating in parallel, things get messy very quickly and there is no way to do sequential programming for it. For such simulations we need parallel state machines, processes, actors etc. and their coordination on a time line. Our first approaches above scale well for such requirements.
