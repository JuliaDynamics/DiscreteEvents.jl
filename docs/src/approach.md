# Approaches to modeling and simulation

`Simulate.jl` aims to support four major approaches to modeling and simulation of **discrete event systems (DES)**:

1. **event based**: *events* occur in time and trigger actions causing further events …
2. **activity based**: *activities* occur in time and cause other activities …
3. **state based**: entities react to events occurring in time depending on their current *state*. Their actions may cause further events …
4. **process based**: entities are modeled as *processes* waiting for events and then acting according to the event and their current state …

Choi and Kang [1] have written an entire book about the first three approaches . Cassandras and Lafortune [2] call the first three approaches "the event scheduling scheme" and the 4th one "the process-oriented simulation scheme". Whoever is right, there are communities and their views behind those approaches and `Simulate.jl` wants to be useful for them all.

`Simulate.jl` allows arbitrary Julia functions or expressions to be registered as "events" on the clock's time line and thus enables the first three approaches. That is because Julia functions can express events, activities or step-functions of a state machine. Under a few conditions Julia functions can run as "processes" simulating entities in a DES.

Then there are **continuous systems**, which are usually modeled by taking an action each time step Δt. We can register expressions or functions to the clock as sampling functions, which then are executed at each clock tick or we can register them as repeating events.  

All approaches fit together: e.g. functions registered as events can communicate with other functions running as processes acting on states and triggering other events or processes to start … Functions operating continuously can modify or evaluate conditions and states or trigger events … Thus we can model and simulate **hybrid systems**. All this gives us an expressive framework for simulation.

- [1] Choi and Kang: *Modeling and Simulation of Discrete-Event Systems*, Wiley, 2013
- [2] Cassandras and Lafortune: *Introduction to Discrete Event Systems*, Springer, 2008, Ch. 10

## Event based modeling and simulation

(empty)

## Activity based modeling and simulation

(empty, look at the table tennis example)

## State based modeling and simulation

(empty)

## Process based modeling and simulation

With the `/dev` version you can do something like this:

### Example

```julia
using Simulate, Printf
reset!(𝐶)

function foo(in::Channel, out::Channel, id)
    token = take!(in)
    @printf("%5.2f: foo %d took token %d\n", τ(), id, token)
    d = delay!(rand())
    put!(out, token+id)
end

function bar(in::Channel, out::Channel, id)
    token = take!(in)
    @printf("%5.2f: bar %d took token %d\n", τ(), id, token)
    d = delay!(rand())
    put!(out, token*id)
end

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8    # create and register 8 SimProcesses
    process!(𝐶, SimProcess(i, foo, ch1, ch2, i))     # 4 foos
    process!(𝐶, SimProcess(i+1, bar, ch2, ch1, i+1)) # 4 bars
end

start!(𝐶) # start all registered processes
put!(ch1, 1) # put first token into channel 1

sleep(0.1) # we give the processes some time to startup

run!(𝐶, 10)
```

If we source this program, it runs a simulation:

```julia
julia> include("docs/examples/channels.jl")
 0.00: foo 7 took token 1
 0.25: bar 4 took token 8
 0.29: foo 3 took token 32
 0.55: bar 2 took token 35
 1.21: foo 5 took token 70
 1.33: bar 8 took token 75
 1.47: foo 1 took token 600
 1.57: bar 6 took token 601
 2.07: foo 7 took token 3606
 3.00: bar 4 took token 3613
 3.68: foo 3 took token 14452
 4.33: bar 2 took token 14455
 5.22: foo 5 took token 28910
 6.10: bar 8 took token 28915
 6.50: foo 1 took token 231320
 6.57: bar 6 took token 231321
 7.13: foo 7 took token 1387926
 8.05: bar 4 took token 1387933
 8.90: foo 3 took token 5551732
 9.10: bar 2 took token 5551735
 9.71: foo 5 took token 11103470
 9.97: bar 8 took token 11103475
10.09: foo 1 took token 88827800
"run! finished with 22 events, simulation time: 10.0"
```
