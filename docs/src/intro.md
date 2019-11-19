# Getting started

Get an overview and learn the basics.

## A first example

A server takes something from its input and puts it out modified after some time. We implement that in a function, create input and output channels and some "foo" and "bar" processes interacting on them:  

```julia
using Simulate, Printf
reset!(𝐶) # reset the central clock

# describe the activity of the server
function serve(input::Channel, output::Channel, name, id, op)
    token = take!(input)         # take something from the input
    now!(SF(println, @sprintf("%5.2f: %s %d took token %d", tau(), name, id, token)))
    delay!(rand())               # after a delay
    put!(output, op(token, id))  # put it out with some op applied
end

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8    # create, register and start 8 SimProcesses (alias SP)
    process!(SP(i, serve, ch1, ch2, "foo", i, +))
    process!(SP(i+1, serve, ch2, ch1, "bar", i+1, *))
end

put!(ch1, 1)  # put first token into channel 1

run!(𝐶, 10)   # and run for 10 time units
```

If we source this program, it runs a simulation:

```julia
julia> include("docs/examples/channels4.jl")
 0.00: foo 7 took token 1
 0.25: bar 4 took token 8
 0.29: foo 3 took token 32
 0.55: bar 2 took token 35
 1.21: foo 5 took token 70
 1.33: bar 8 took token 75
...
...
 8.90: foo 3 took token 5551732
 9.10: bar 2 took token 5551735
 9.71: foo 5 took token 11103470
 9.97: bar 8 took token 11103475
10.09: foo 1 took token 88827800
"run! finished with 22 clock events, simulation time: 10.0"
```
#### Types and functions

[`𝐶`](@ref), [`reset!`](@ref), [`now!`](@ref), [`delay!`](@ref), [`process!`](@ref), [`SP`](@ref SimProcess), [`run!`](@ref)


## Four building blocks

`Simulate.jl` provides 4 major building blocks for modeling and simulation of discrete event systems:

1. the [**clock**](@ref the_clock) gives a virtual simulation time,
2. [**events**](@ref event_scheme) are expressions or functions scheduled for execution at given times or conditions,
3. [**processes**](@ref process_scheme) run asynchronously and can delay for a time or wait for conditions,
4. [**continuous sampling**](@ref continuous_sampling) allows continuous operations on the time line.

## [The clock](@id the_clock)

The clock is central to any model and simulation, since it establishes the timeline. It provides not only the time, but contains also the time unit, all scheduled events, conditional events, processes, sampling expressions or functions and the sample rate Δt.

```jldoctest intro
julia> using Simulate

julia> c = Clock()                           ### create a new clock
Clock: state=Simulate.Undefined(), time=0.0, unit=, events: 0, cevents: 0, processes: 0, sampling: 0, sample rate Δt=0.0
julia> tick() = println(tau(c), ": tick!")   ### define a function printing the clock's time
tick (generic function with 1 method)
julia> event!(c, SF(tick), every, 1)         ### schedule a repeat event on the clock
0.0
julia> run!(c, 10)                           ### run the clock for 10 time units
0.0: tick!
1.0: tick!
2.0: tick!
3.0: tick!
4.0: tick!
5.0: tick!
6.0: tick!
7.0: tick!
8.0: tick!
9.0: tick!
10.0: tick!
"run! finished with 11 clock events, 0 sample steps, simulation time: 10.0"
```

Without a reference to a created clock you use simply the **central clock** [`𝐶`](@ref) (\it𝐶+tab), alias [`Clk`](@ref 𝐶):

```jldoctest intro
julia> tick() = println(tau(), ": tick!")         ### the tick function now uses central time tau()
tick (generic function with 1 method)
julia> sample_time!(1)                            ### set the sampling rate on the central clock to 1
1.0
julia> sample!( SF(tick) );                       ### set tick as a sampling function

julia> 𝐶                                          ### 𝐶 now has one sampling entry and the sample rate set
Clock: state=Simulate.Idle(), time=0.0, unit=, events: 0, cevents: 0, processes: 0, sampling: 1, sample rate Δt=1.0
julia> run!(𝐶, 5)                                 ### run 𝐶 for 5 time units
1.0: tick!
2.0: tick!
3.0: tick!
4.0: tick!
5.0: tick!
"run! finished with 0 clock events, 5 sample steps, simulation time: 5.0"
julia> run!(𝐶, 5)                                 ### run it again
6.0: tick!
7.0: tick!
8.0: tick!
9.0: tick!
10.0: tick!
"run! finished with 0 clock events, 5 sample steps, simulation time: 10.0"
julia> reset!(𝐶)                                  ### reset the clock
"clock reset to t₀=0.0, sampling rate Δt=0.0."
```

If Δt = 0, the clock doesn't tick with a fixed interval, but jumps from event to event.

!!! note
    Clocks work with a `Float64` time and with `Unitful.NoUnits` but you can set them to work with `Unitful.Time` units like `ms, s, minute, hr`. In this case [`tau`]((@ref)) returns a time, e.g. `1 s`. You can also provide time values to clocks or in scheduling events. They then are converted to the defined unit as long as the clock is set to a time unit.

    - [`setUnit!(sim::Clock, unit::FreeUnits)`](@ref setUnit!): set a clock unit.
    - `tau(sim::Clock).val`: return unitless number for current time.

    At the moment I find it unconvenient to work with units if you trace simulation times in a table or you do plots. It seems easier not to use them as long you don't need automatic time conversion in your simulation projects.

#### Types and functions

[`Clock`](@ref), [`𝐶`](@ref), [`tau`](@ref), [`sample_time!`](@ref), [`sample!`](@ref), [`run!`](@ref), [`reset!`](@ref), [`incr!`](@ref), [`sync!`](@ref), [`stop!`](@ref stop!(::Clock)), [`resume!`](@ref),  

## [Events](@id event_scheme)

Julia **functions** or **expressions** are scheduled as events on the clock's time line. In order to not be invoked immediately,

- expressions must be [quoted](https://docs.julialang.org/en/v1/manual/metaprogramming/#Quoting-1) with `:()` and
- functions must be enclosed inside a [`SimFunction`](@ref), alias [`SF`](@ref SimFunction)

Quoted expressions and SimFunctions can be given to events mixed in a tuple or array. The following example session uses **timed events**:

```jldoctest intro
julia> ev1 = :(println(tau(), ": I'm a quoted expression"))
:(println(tau(), ": I'm a quoted expression"))
julia> ev2 = SF(() -> println(tau(), ": I'm a SimFunction"))
SimFunction(getfield( Symbol("##1#2"))(), (), Base.Iterators.Pairs{Union{},Union{},Tuple{},NamedTuple{(),Tuple{}}}())
julia> event!(ev1, at, 2)                      ### schedule an event at 2
2.0
julia> event!(ev1, after, 8)                   ### schedule an event after 8
8.0
julia> event!(ev2, every, 5)                   ### schedule an event every 5
0.0
julia> run!(𝐶, 10)                             ### run
0.0: I'm a SimFunction
2.0: I'm a quoted expression
5.0: I'm a SimFunction
8.0: I'm a quoted expression
10.0: I'm a SimFunction
"run! finished with 5 clock events, 0 sample steps, simulation time: 10.0"
julia> event!((ev1, ev2), after, 2)            ### schedule both ev1 and ev2 as event
12.0
julia> run!(𝐶, 5)                              ### run
12.0: I'm a quoted expression
12.0: I'm a SimFunction
15.0: I'm a SimFunction
"run! finished with 2 clock events, 0 sample steps, simulation time: 15.0"
```

**Conditional events** execute under given conditions. Conditions can be formulated by using the [`@tau`](@ref tau(::Any, ::Symbol, ::Union{Number, QuoteNode})) macro questioning the simulation time, the [`@val`](@ref) macro questioning a variable or any other logical expression or function or combinations of them.

```jldoctest intro
julia> reset!(𝐶)                                ### reset the clock
"clock reset to t₀=0.0, sampling rate Δt=0.0."
julia> y = 0                                    ### create a variable
0
julia> sample!( SF(() -> global y = tau()/2) ); ### a sampling function

julia> 𝐶                                        ### the sample rate Δt=0.01 was set implicitly
Clock: state=Simulate.Idle(), time=0.0, unit=, events: 0, cevents: 0, processes: 0, sampling: 1, sample rate Δt=0.01
julia> event!( SF(()->println(tau(),": now y ≥ π") ), (@val :y :≥ π) ) ### a conditional event
0.0
julia> run!(𝐶, 10)                              ### run
6.28999999999991: now y ≥ π
"run! finished with 0 clock events, 1000 sample steps, simulation time: 10.0"
julia> 2π                                       ### exact value
6.283185307179586
julia> reset!(𝐶)
"clock reset to t₀=0.0, sampling rate Δt=0.0."
julia> sample!( SF(()-> global y=sin(@tau)) );  ### create a sine function

julia> event!(SF(()->println(tau(),": now y ≥ 1/2")), ((@val :y :≥ 1/2),(@tau :≥ 5))) ### two conditions
0.0
julia> run!(𝐶, 10)
6.809999999999899: now y ≥ 1/2
"run! finished with 0 clock events, 1000 sample steps, simulation time: 10.0"
julia> asin(0.5) + 2π                           ### exact value
6.806784082777885
```

It can be seen: (1) the sample rate has some uncertainty in detecting events and (2) conditional events are triggered only once.

#### Types and functions
[`tau`](@ref), [`SimFunction`](@ref), [`SF`](@ref SimFunction), [`event!`](@ref), [`run!`](@ref), [`reset!`](@ref), [`sample!`](@ref), [`@val`](@ref), [`@tau`](@ref)

## [Processes](@id process_scheme)

Functions can be started as asynchronous **processes** or [coroutines](https://docs.julialang.org/en/v1/manual/control-flow/#man-tasks-1), which aside from doing something useful can coordinate with the clock and other events by delaying for some time or waiting for conditions, taking inputs from events or other processes, triggering events or starting other processes …

Processes are a powerful modeling device, but you need to take care that

1. they **give back control** to the clock and other processes by calling delays or conditional waits or requesting resources (and thus implicitly waiting for them to become available) and
2. they **keep synchronized** with the clock by locking the clock until critical operations are finished.

#### Create and start a process

The function gets enclosed in a [`SimProcess`](@ref), alias [`SP`](@ref SimProcess) with its own id assigned.  `process!` registers it to the clock and starts it as a process in a loop. You can define how many loops the function should take, but the default is `Inf`. You can create as many instances of a function as processes as you like.

```jldoctest intro
```

#### Delay, wait, take and put

In order to synchronize with the clock, a process can get the simulation time [`tau`](@ref), call for a [`delay!`](@ref), which suspends it, creates an event on the clock's timeline and wakes up the process after the given time `t`. A conditional [`wait!`]() goes also to the clock and gets treated in the same way: when the conditions become true, the clock gives back control to the process.

Processes can also interact directly e.g. via Julia's [channels](https://docs.julialang.org/en/v1/manual/parallel-computing/#Channels-1) with [`take!`](https://docs.julialang.org/en/v1/base/parallel/#Base.take!-Tuple{Channel}) and [`put!`](https://docs.julialang.org/en/v1/base/parallel/#Base.put!-Tuple{Channel,Any}). This also may suspend them until there is something to take or until they can put something in a channel. In simulations they must take care that they keep synchronized with the clock.

```jldoctest intro
```

#### Lock and unlock the clock

When a process does IO-operations like printing, reading or writing from or to files, it gives control back to the Julia scheduler. Then, before the operation gets completed, the clock may proceed further. In order to avoid that, processes should encapsulate  critical operations in a [`now!`](@ref) call. This will lock the clock for the operation to complete and then unlock it again.

```jldoctest intro
```
#### Types and functions
[`SimProcess`](@ref), [`SP`](@ref SimProcess), [`process!`](@ref), [`delay!`](@ref), [`wait!`](@ref), [`now!`](@ref), [`SF`](@ref SimFunction), [`run!`](@ref), [`𝐶`](@ref), [`reset!`](@ref),

## [Continuous sampling](@id continuous_sampling)

If we provide the clock with a time interval `Δt`, it ticks with a fixed sample rate. At each tick it will call registered functions or expressions:

- `sample_time!(sim::Clock, Δt::Number)`: set the clock's sampling time starting from now (`tau(sim)`).
- `sample!(sim::Clock, ex::Union{Expr,SimFunction})`: enqueue a function or expression for sampling.

Sampling functions or expressions are called at clock ticks in the sequence they were registered. They are called before any events scheduled for the same time.

#### Types and functions
[``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref),

## Running a simulation

Now, after we have setup a clock, scheduled events or setup sampling, we can step or run through a simulation, stop or resume it.

- `run!(sim::Clock, duration::Number)`: run a simulation for a given duration. Call all ticks and scheduled events in that timeframe.
- `incr!(sim::Clock)`: take one simulation step, call the next tick or event.
- `stop!(sim::Clock)`: stop a simulation
- `resume!(sim::Clock)`: resume a halted simulation.

Now we can evaluate the results.

#### Types and functions
[``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref),

## Logging

Logging enables us to trace variables over simulation time and such analyze their behaviour.

- `L = Logger()`: create a new logger, providing the newest record `L.last`, a logging table `L.df` and a switch `L.ltype` between logging types.
- `init!(L::Logger, sim::Clock=𝐶)`:
- `setup!(L::Logger, vars::Array{Symbol})`: setup `L`, providing it with an array of logging variables `[:a, :b, :c ...]`
- `switch!(L::Logger, to::Number=0)`: switch between `0`: only keep the last record, `1`: print, `2`: write records to the table
- `record!(L::Logger)`: record the logging variables with current simulation time.

#### Types and functions
[``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref), [``](@ref),
