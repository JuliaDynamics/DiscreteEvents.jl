# Approaches to modeling and simulation

`Simulate.jl` aims to support four major approaches to modeling and simulation of **discrete event systems (DES)**:

1. **event based**: *events* occur in time and trigger actions causing further events …
2. **state based**: entities react to events occurring in time depending on their current *state*. Their actions may cause further events …
3. **activity based**: *activities* occur in time and cause other activities …
4. **process based**: entities are modeled as *processes* waiting for events and then acting according to the event and their current state …

Choi and Kang [1](#ref1) have written an entire book about the first three approaches. Basically  they can be converted to each other. Cassandras and Lafortune [2](#ref2) call them "the event scheduling scheme" and the 4th approach "the process-oriented simulation scheme" [3](#ref3). There are communities and their views behind the various approaches and `Simulate.jl` wants to be useful for them all.

`Simulate.jl` allows arbitrary Julia functions or expressions to be registered as "events" on the clock's time line and thus enables the first three approaches. Under a few conditions Julia functions can run as "processes" simulating entities in a DES.

Then there are **continuous systems**, which are usually modeled by taking an action each time step Δt. We can register expressions or functions to the clock as sampling functions, which then are executed at each clock tick or we can register them as repeating events.  

All approaches fit together: e.g. functions registered as events can communicate with other functions running as processes acting on states and triggering other events or processes to start … Functions operating continuously can modify or evaluate conditions and states or trigger events … Thus we can model and simulate **hybrid systems** combining continuous processes and discrete events. All this gives us an expressive framework for simulation.

## Event based modeling and simulation

A simple server `takes` something from an input, `processes` it for some time and `puts` it out to an output. Here the three actions are seen as events and described in an event graph:

![event graph](images/event.png)

In our example we want to have 8 such entities in our system, 4 foos and 4 bars, which communicate with each other via two channels. Therefore we have to define a data structure for the entity:

```julia
using Simulate, Printf, Random

mutable struct Server
  id::Int64
  name::AbstractString
  input::Channel
  output::Channel
  op     # operation to take
  token  # current token

  Server(id, name, input, output, op) = new(id, name, input, output, op, nothing)
end

function take(en::Server)
    isempty(en.input) || event!(𝐶, SimFunction(take, en), :(!isempty(en.input)))
    en.token = take!(en.input)
    @printf("%5.2f: %s %d took token %d\n", τ(), en.name, en.id, en.token)
    proc(en)
end

proc(en) = event!(𝐶, SimFunction(put, en), after, rand())

function put(en)
    put!(en.output, en.op(en.id, en.token))
    en.token = nothing
    take(en)
end

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8
    take(Server(i, "foo", ch1, ch2, +))
    take(Server(i+1, "bar", ch2, ch1, *))
end

put!(ch1, 1) # put first token into channel 1

run!(𝐶, 10)
```

When running, this gives us as output:

```julia
julia>
conditional events are not yet implemented !!
```

## State based modeling and simulation

Our server has two states: `Waiting` and `Processing`. On condition `!isempty(input)` it moves from waiting to processing, then takes its input, operates on it and puts it out. The graph of the timed automaton looks like:

![timed automaton](images/state.svg)

We can implement it with:

```julia
reset!(𝐶)

```

When running, that gives us as output:

```julia
julia>

```

## Activity based modeling and simulation

Our server's activity is the processing of the token. A timed Petri net would look like:

![timed petri net](images/activity.png)

… where ``v_{put}`` is the delay of the put transition. Therefore the activity is described by the blue box. Following the Petri net, we should implement a state variable with states Idle and Busy, but we don't need to if we separate the activities in time.

```julia
mutable struct Server
  id::Int64
  name::AbstractString
  input::Channel
  output::Channel
  op     # operation to take
  token  # current token

  Server(id, name, input, output, op) = new(id, name, input, output, op, nothing)
end

cond(en) = !isempty(en.input) && en.state == Idle

function serve(en::Server)
    if isempty(en.input)
      event!(𝐶, SimFunction(take, en), !isempty(en.input))
    else
      en.token = take!(en.input)
      @printf("%5.2f: %s %d took token %d\n", τ(), en.name, en.id, en.token)
      event!(𝐶, SimFunction((put!, en.output, token), (serve, en)), after, rand())
    end
end

reset!(𝐶)

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8
    serve(Server(i, "foo", ch1, ch2, +))
    serve(Server(i+1, "bar", ch2, ch1, *))
end

put!(ch1, 1) # put first token into channel 1

run!(𝐶, 10)
```

When running, this gives us as output:

```julia
julia>
conditional events are not yet implemented !!
```

## Process based modeling and simulation

Here we can combine all in a simple process of `take!`-`delay!`-`put!`, which runs in a loop. An implementation looks like:

```julia
reset!(𝐶)

function simple(input::Channel, output::Channel, name, id, op)
    token = take!(input)         # take something from the input
    @printf("%5.2f: %s %d took token %d\n", τ(), name, id, token)
    d = delay!(rand())           # after a delay
    put!(output, op(token, id))  # put it out with some op applied
end

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8    # create and register 8 SimProcesses
    process!(𝐶, SimProcess(i, simple, ch1, ch2, "foo", i, +))
    process!(𝐶, SimProcess(i+1, simple, ch2, ch1, "bar", i+1, *))
end

start!(𝐶) # start all registered processes
put!(ch1, 1) # put first token into channel 1

sleep(0.1) # we give the processes some time to startup

run!(𝐶, 10)
```

and runs like:

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

## Comparison

(empty)

## Combined approach

(empty)

## Hybrid systems

(empty)

## References, Footnotes

- <a name="ref1">[1]</a>:  [Choi and Kang: *Modeling and Simulation of Discrete-Event Systems*, Wiley, 2013](https://books.google.com/books?id=0QpwAAAAQBAJ)
- <a name="ref2">[2]</a>:  [Cassandras and Lafortune: *Introduction to Discrete Event Systems*, Springer, 2008, Ch. 10](https://books.google.com/books?id=AxguNHDtO7MC)
- <a name="ref3">[3]</a>: to be fair, the 4th approach is called by Choi and Kang "parallel simulation".
- <a name="ref4">[4]</a>: since the two separate take and put functions are initiated by setting the state to Idle or Busy, we don't in this case really need the state variable.
