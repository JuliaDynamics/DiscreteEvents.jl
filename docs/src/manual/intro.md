# Getting started

Get an overview and learn the basics.

`Simulate.jl` provides 1) a *clock* with a virtual simulation time and 2) the ability to schedule Julia functions and expressions as *events* on the clock's timeline or 3) run them as *processes* synchronizing with the clock. The clock can 4) invoke *sampling* functions or expressions continuously at a given rate.

!!! note
    `Simulate.jl` doesn't have a special concept for shared resources since this
    can be expressed in native Julia via tokens in a `Channel`.

## A first example

A simple server takes something (a resource) from its input and puts it out modified after some time. We implement the server's activity in a function, create input and output channels and some "foo" and "bar" processes interacting on them:  

```julia
using Simulate, Printf, Random

function simple(c::Clock, input::Channel, output::Channel, name, id, op)
    token = take!(input)         # take something from the input
    now!(c, fun(println, @sprintf("%5.2f: %s %d took token %d", tau(c), name, id, token)))
    d = delay!(c, rand())        # after a delay
    put!(output, op(token, id))  # put it out with some op applied
end

clk = Clock()      # create a clock
Random.seed!(123)  # seed the random number generator

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8    # create and register 8 processes
    process!(clk, Prc(i, simple, ch1, ch2, "foo", i, +))
    process!(clk, Prc(i+1, simple, ch2, ch1, "bar", i+1, *))
end

put!(ch1, 1)    # put first token into channel 1
yield()         # let the first task take it
run!(clk, 10)   # and run for 10 time units
```
We then run it:
```julia
julia> include("docs/examples/channels.jl")
 0.00: foo 1 took token 1
 0.77: bar 2 took token 2
 1.71: foo 3 took token 4
 2.38: bar 4 took token 7
 2.78: foo 5 took token 28
 ...
 ...
 7.91: bar 2 took token 631017
 8.36: foo 3 took token 1262034
 8.94: bar 4 took token 1262037
 9.20: foo 5 took token 5048148
 9.91: bar 6 took token 5048153
"run! finished with 43 clock events, 0 sample steps, simulation time: 10.0"
```
#### Types and functions

[`𝐶`](@ref), [`reset!`](@ref), [`now!`](@ref), [`delay!`](@ref), [`process!`](@ref), [`Prc`](@ref), [`run!`](@ref)


## Four building blocks

`Simulate.jl` provides 4 major building blocks for modeling and simulation of discrete event systems:

1. the logical [**clock**](@ref the_clock) gives the simulation time,
2. [**events**](@ref event_scheme) are Julia expressions or functions executing at given simulation times or under given conditions,
3. [**processes**](@ref process_scheme) are functions running as [tasks](https://docs.julialang.org/en/v1/manual/control-flow/#man-tasks-1) and synchronizing with the clock by delaying for a time or waiting for conditions,
4. [**continuous sampling**](@ref continuous_sampling) is done by invoking given expressions or functions at a given rate on the time line.

## [The clock](@id the_clock)

The clock is central to any model and simulation, since it establishes the timeline. It does not only provide the time, but contains also the time unit, all scheduled events, conditional events, processes, sampling expressions or functions and the sample rate Δt. Each simulation can have its own clock.

```julia
julia> c = Clock()                           # create a new clock
Clock thread 1 (+ 0 ac): state=Simulate.Undefined(), t=0.0 , Δt=0.0 , prc:0
  scheduled ev:0, cev:0, sampl:0

julia> tick() = println(tau(c), ": tick!")   # define a function printing the clock's time
tick (generic function with 1 method)

julia> event!(c, fun(tick), every, 1)         # schedule a repeat event on the clock
0.0

julia> run!(c, 10)                           # run the clock for 10 time units
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

If you work with only one simulation at a time, you normally use the *central clock* [`𝐶`](@ref) (`\\it𝐶`+`tab`):

!!! note
    You definitely need different clock variables if you run multiple simulations on parallel threads. In such cases each simulation should have its own clock. Please look at the [dicegame](../examples/dicegame/dicegame.md) example for that.

```julia
julia> tick() = println(tau(), ": tick!")         # the tick function now uses central time tau()
tick (generic function with 1 method)

julia> sample_time!(1)                            # set the sampling rate on the central clock to 1
1.0

julia> periodic!( fun(tick) );                       # set tick as a sampling function

julia> 𝐶                                          # 𝐶 now has one sampling entry and the sample rate set
Clock thread 1 (+ 0 ac): state=Simulate.Idle(), t=0.0 , Δt=1.0 , prc:0
  scheduled ev:0, cev:0, sampl:1

julia> run!(𝐶, 5)                                 # run 𝐶 for 5 time units
1.0: tick!
2.0: tick!
3.0: tick!
4.0: tick!
5.0: tick!
"run! finished with 0 clock events, 5 sample steps, simulation time: 5.0"

julia> run!(𝐶, 5)                                 # run it again
6.0: tick!
7.0: tick!
8.0: tick!
9.0: tick!
10.0: tick!
"run! finished with 0 clock events, 5 sample steps, simulation time: 10.0"

julia> reset!(𝐶)                                  # reset the clock
"clock reset to t₀=0.0, sampling rate Δt=0.0."
```

If Δt = 0, the clock doesn't tick with a fixed interval, but jumps from event to event.

!!! note
    Clocks work with a `Float64` time and with `Unitful.NoUnits` but you can set them to work with `Unitful.Time` units like `ms, s, minute, hr`. In this case [`tau`](@ref) returns a time, e.g. `1 s`. You can also provide time values to clocks or in scheduling events. They then are converted to the defined unit as long as the clock is set to a time unit.

    - [`setUnit!(sim::Clock, unit::FreeUnits)`](@ref setUnit!): set a clock unit.
    - `tau(sim::Clock).val`: return a unitless number for current time.

    At the moment I don't find it practical to work with units if for example I collect simulation events or variables with their time in a table or do plots. It seems easier not to use them as long you don't need automatic time conversion in your simulation projects.

#### Types and functions

[`Clock`](@ref), [`𝐶`](@ref), [`tau`](@ref), [`sample_time!`](@ref), [`periodic!`](@ref), [`run!`](@ref), [`reset!`](@ref), [`incr!`](@ref), [`sync!`](@ref), [`stop!`](@ref stop!(::Clock)), [`resume!`](@ref),  

## [Events](@id event_scheme)

Julia *functions* or *expressions* are scheduled as events on the clock's time line. In order to not be invoked immediately,

- event functions must be stored in a [`fun`](@ref) and
- event expressions must be [quoted](https://docs.julialang.org/en/v1/manual/metaprogramming/#Quoting-1) with `:()`.

Event functions in a `fun` can get 1) values, variables or 2) symbols,
expressions or even other `fun`s as arguments. The 2nd case arguments are
evaluated not till event time before they are passed to the event funtion.

Several functions and expressions can be scheduled as events combined in a
tuple.

!!! warning
    Evaluating expressions or symbols at global scope is much slower than using
    functions and gives a one time warning. See [Performance](../performance/performance.md).
    This functionality may be removed entirely in a future version. (Please write
    an [issue](https://github.com/pbayer/Simulate.jl/issues) if you want to keep it.)

### Timed events

Timed events with [`event!`](@ref) schedule functions and expressions to execute at a given time:

```julia
ev1 = :(println(tau(), ": I'm a quoted expression"))
ev2 = fun(() -> println(tau(), ": I'm a fun"))
ev3 = fun(println, fun(tau), ": now a is ", :a)  # various arguments to a fun

a = 1
event!(ev1, at, 2)                             # schedule events at 2, 3, 4, 6, 8
event!(ev3, at, 3)
event!(:(a += 5), at, 4)
event!(ev3, at, 6)
event!(ev1, after, 8)                          # schedule an event after 8
event!(ev2, every, 5)                          # schedule an event every 5
```
```julia
julia> run!(𝐶, 10)                             # run
0.0: I'm a fun
2.0: I'm a quoted expression
3.0: now a is 1
5.0: I'm a fun
6.0: now a is 6
8.0: I'm a quoted expression
10.0: I'm a fun
"run! finished with 8 clock events, 0 sample steps, simulation time: 10.0"

julia> event!((ev1, ev2), after, 2)            # schedule both ev1 and ev2 as one event
12.0

julia> run!(𝐶, 5)                              # run
12.0: I'm a quoted expression
12.0: I'm a fun
15.0: I'm a fun
"run! finished with 2 clock events, 0 sample steps, simulation time: 15.0"
```

### Conditional events

*Conditional events*  with ([`event!`](@ref) execute under given conditions. Conditions can be formulated as logical expression or function or combinations of them.

```julia
reset!(𝐶)                                       # reset the clock
y = 0                                           # create a variable y
periodic!( fun(() -> global y = tau()/2) );        # a sampling function
event!( fun(()->println(tau(),": now y ≥ π") ), (@val :y :≥ π) ) # a conditional event
```
```julia
julia> run!(𝐶, 10)                              # run
6.28999999999991: now y ≥ π
"run! finished with 0 clock events, 1000 sample steps, simulation time: 10.0"

julia> 2π                                       # exact value
6.283185307179586
```
```julia
reset!(𝐶)
periodic!( fun(()-> global y=sin(@tau)) );         # sample a sine function on y
event!(fun(()->println(tau(),": now y ≥ 1/2")), ((@val :y :≥ 1/2),(@tau :≥ 5))) # two conditions
```
```julia
julia> run!(𝐶, 10)
6.809999999999899: now y ≥ 1/2
"run! finished with 0 clock events, 1000 sample steps, simulation time: 10.0"

julia> asin(0.5) + 2π                           # exact value
6.806784082777885
```

It can be seen: (1) the sample rate has some uncertainty in detecting events and (2) conditional events are triggered only once. If there is no sample rate set, a conditional event sets one up and deletes it again after it becomes true.

#### Types and functions
[`tau`](@ref), [`fun`](@ref), [`event!`](@ref), [`run!`](@ref), [`reset!`](@ref), [`periodic!`](@ref)

## [Processes](@id process_scheme)

Functions can be started as asynchronous [tasks or coroutines](https://docs.julialang.org/en/v1/manual/control-flow/#man-tasks-1), which can coordinate with the clock and events by delaying for some time or waiting for conditions, taking inputs from events or other tasks, triggering events or starting other tasks …

From a modeling or simulation standpoint we call such tasks *processes*, because they can represent some ongoing activity in nature. Tasks seen as processes are a powerful modeling device, but you need to take care that

1. they *give back control* to the clock and other such processes by calling delays or conditional waits or requesting resources (and thus implicitly waiting for them to become available) and
2. they *transfer critical operations to the clock* in order to not get out of sync with simulation time.

### Create and start a process

[`Prc`](@ref) prepares a function for running as a process and assignes it an id.  Then `process!` registers it to the clock and starts it as a process in a loop. You can define how many loops the function should persist, but the default is `Inf`. You can create as many instances of a function as processes as you like.

```julia
function doit(n)                                # create a function doit
    i = 1
    while i ≤ n
        delay!(rand()*2)                        # delay for some time
        now!(fun(println, @sprintf("%5.2f: finished %d", tau(), i)))  # print
        i += 1
    end
end

Random.seed!(1234);        
reset!(𝐶)                                       # reset the central clock
process!(Prc(1, doit, 5), 1)                     # create, register and start doit(5) as a process, id=1, runs only once
```
```julia
julia> run!(𝐶, 5)                               # run for 5 time units
 1.18: finished 1
 2.72: finished 2
 3.85: finished 3
 4.77: finished 4
"run! finished with 8 clock events, 0 sample steps, simulation time: 5.0"

julia> run!(𝐶, 2)                               # it is not yet finished, run 2 more
 6.36: finished 5
"run! finished with 2 clock events, 0 sample steps, simulation time: 7.0"


julia> run!(𝐶, 3)                               # doit(5) is done with 5, nothing happens anymore
"run! finished with 0 clock events, 0 sample steps, simulation time: 10.0"
```

### Delay, wait, take and put

In order to synchronize with the clock, a process can
- get the simulation time [`tau()`](@ref tau),
- [`delay!`](@ref), which suspends it until after the given time `t` or
- [`wait!`](@ref) for a condition. This creates a conditional [`event!`](@ref) which reactivates the process when the conditions become true.

Processes can also interact directly e.g. via [channels](https://docs.julialang.org/en/v1/manual/parallel-computing/#Channels-1) with [`take!`](https://docs.julialang.org/en/v1/base/parallel/#Base.take!-Tuple{Channel}) and [`put!`](https://docs.julialang.org/en/v1/base/parallel/#Base.put!-Tuple{Channel,Any}). This also may suspend them until there is something to take from a channel or until they are allowed to put something into it.

```julia
function watchdog(name)
    delay!(until, 6 + rand())                    # delay until
    now!(fun(println, @sprintf("%5.2f %s: yawn!, bark!, yawn!", tau(), name)))
    wait!(((@val :hunger :≥ 7),(@tau :≥ 6.5)))   # conditional wait
    while 5 ≤ hunger ≤ 10
        now!(fun(println, @sprintf("%5.2f %s: %s", tau(), name, repeat("wow ", Int(trunc(hunger))))))
        delay!(rand()/2)                         # simple delay
        if scuff
            now!(fun(println, @sprintf("%5.2f %s: smack smack smack", tau(), name)))
            global hunger = 2
            global scuff = false
        end
    end
    delay!(rand())                               # simple delay
    now!(fun(println, @sprintf("%5.2f %s: snore ... snore ... snore", tau(), name)))
end

hunger = 0
scuff = false
reset!(𝐶)
Random.seed!(1122)

periodic!(fun(()-> global hunger += rand()), 0.5)   # a sampling function: increasing hunger
event!(fun(()-> global scuff = true ), 7+rand())  # an event: scuff after 7 am
process!(Prc(1, watchdog, "Snoopy"), 1)           # create, register and run Snoopy
```
```julia
julia> run!(𝐶, 10)
 6.24 Snoopy: yawn!, bark!, yawn!
 6.50 Snoopy: wow wow wow wow wow wow wow wow
 6.98 Snoopy: wow wow wow wow wow wow wow wow wow
 7.37 Snoopy: smack smack smack
 7.38 Snoopy: snore ... snore ... snore
"run! finished with 10 clock events, 20 sample steps, simulation time: 10.0"
```

!!! warning
    you **must not** use or invoke operations like [`delay!`](@ref), [`wait!`](@ref), `take!` or `put!` outside of tasks and inside the Main process, because they will suspend it.

### IO-operations

Tasks must transfer critical IO operations to the clock with a [`now!`](@ref) call. When tasks invoke IO-operations like printing, reading or writing from or to files, directly, they give control back to the Julia scheduler. While the IO-operation continues the clock may advance with time and the task has got out of sync with simulation time. Processes therefore should enclose their IO-operations in a [`now!`](@ref) call. This will transfer them for execution to the clock, which must finish them before proceeding any further.

```julia
function bad()                                   # bad: IO-operation DIY
    delay!(rand()*2)
    @printf("%5.2f: hi, here I am\n", tau())
end
Random.seed!(1234);
reset!(𝐶)                                        # reset the clock
process!(Prc(1, bad), 5)                          # setup a process with 5 cycles
```
```julia
julia> run!(𝐶, 10)                               # it runs only once !!!
 1.18: hi, here I am
"run! finished with 1 clock events, 0 sample steps, simulation time: 10.0"
```
```julia
function better()                                # better: let the clock doit for you
    delay!(rand()*2)
    now!(fun(println, @sprintf("%5.2f: hi, I am fine", tau())))
end
Random.seed!(1234);
reset!(𝐶)                                        # reset the clock
process!(Prc(1, better), 5)                       # setup a process with 5 cycles
```
```julia
julia> run!(𝐶, 10)                               # it runs all 5 cycles
 1.18: hi, I am fine
 2.72: hi, I am fine
 3.85: hi, I am fine
 4.77: hi, I am fine
 6.36: hi, I am fine
"run! finished with 10 clock events, 0 sample steps, simulation time: 10.0"
```
#### Types and functions
[`Prc`](@ref), [`process!`](@ref), [`delay!`](@ref), [`wait!`](@ref), [`now!`](@ref), [`fun`](@ref fun), [`run!`](@ref), [`𝐶`](@ref), [`reset!`](@ref), [`periodic!`](@ref), [`event!`](@ref)

## [Continuous sampling](@id continuous_sampling)

Continuous sampling allows to bring continuous processes or real world data into a simulation or can be used for visualization or logging and collecting statistics.

If you provide the clock with a time interval `Δt`, it ticks with a fixed sample rate. At each tick it will call registered functions or expressions:

- [`sample_time!(Δt)`](@ref sample_time!): set the clock's sample rate starting from now.
- [`periodic!(expr)`](@ref periodic!): register a function or expression for sampling. If no sample rate is set, set it implicitly.

Sampling functions or expressions are called at clock ticks in the sequence they were registered. They are called before any events scheduled for the same time.

!!! note
    Conditions set by conditional [`event!`](@ref) or by [`wait!`](@ref) are also evaluated with the sampling rate. But the conditional event disappears after the conditions are met and the sample rate is then canceled if no sampling functions are registered.

If no sample rate is set, the clock jumps from event to event.

## Running a simulation

After you have setup the clock, scheduled events, setup sampling or started processes – as you have seen – you can step or run through a simulation, stop or resume it.

- [`run!(clk::Clock, duration::Number)`](@ref run!): run a simulation for a given duration. Call all scheduled events and sampling actions in that timeframe.
- [`incr!(clk::Clock)`](@ref incr!): take one simulation step, call the next tick or event.
- [`stop!(clk::Clock)`](@ref stop!(::Clock)): stop a simulation
- [`resume!(clk::Clock)`](@ref resume!): resume a halted simulation.
