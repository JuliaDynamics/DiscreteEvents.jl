# Approaches to modeling and simulation

`Simulate.jl` supports different approaches to modeling and simulation of **discrete event systems (DES)** and to enable combinations thereof. Therefore it provides three major schemes:

- an event-scheduling scheme,
- a process-oriented scheme and
- continuous sampling.

With them different modeling strategies can be applied. We look at how a simple problem can be expressed differently through various modeling approaches:

**Simple problem:**<br>
A server **takes** something from an input, **processes** it for some time and **puts** it out to an output. We have 8 servers in our system, 4 foos and 4 bars, which communicate with each other via two channels.


## Event based modeling

In this view *events* occur in time and trigger further events. Here the three server actions are seen as events and can be described in an event graph:

![event graph](images/event.png)

We define a data structure for the server, provide functions for the three actions, create channels and servers and start:

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

## State based modeling

Here our server has three states: **Idle**, **Busy** and **End** (where *End* does nothing). On an arrival event it resets its internal clock ``x=0`` and determines the service time ``t_s``, moves to *Busy*, *works* on its input and puts it out when service time is over. Then it goes back to *Idle*. A state transition diagram (Mealy model) of the timed automaton would look like:

![timed automaton](images/state.png)

Again we have a data structure for the server (containing a state). We define states and events and implement a `δ` transition function with two methods. Thereby we dispatch on states and events. Since we don't implement all combinations of states and events, we may implement a fallback transition.

```julia
abstract type Q end  # states
struct Idle <: Q end
struct Busy <: Q end
abstract type Σ end  # events
struct Arrive <: Σ end
struct Leave <: Σ end

mutable struct Server
  id::Int64
  name::AbstractString
  input::Channel
  output::Channel
  op     # operation to take
  state::Q
  token  # current token

  Server(id, name, input, output, op) = new(id, name, input, output, op, Idle, nothing)
end

δ(A::Server, ::Idle, ::Arrive) = (A.state=Busy(); event!(𝐶,SimFunction(δ,A,A.state,Leave()),after,rand())
δ(A::Server, ::Busy, ::Leave) = put(A)
δ(A::Server, q::Q, σ::Σ) = println(stderr, "$(A.name) $(A.id) undefined transition $q, $σ")

function take(A::Server)
  if isempty(A.input)
    event!(𝐶, SimFunction(take, A), !isempty(A.input))
  else
    A.token = take!(en.input)
    @printf("%5.2f: %s %d took token %d\n", τ(), A.name, A.id, A.token)
    δ(A,Idle(),Arrive())
  end
end

function put(A::Server)
  put!(A.output, A.op(A.id,A.token))
  A.state=Idle()
  take(A))
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

## Activity based modeling

Our server's *activity* is the processing of the token. A timed Petri net would look like:

![timed petri net](images/activity.png)

The **arrive** transition puts a token in the **Queue**. If both places **Idle** and **Queue** have tokens, the server **takes** them, shifts one to **Busy** and **puts** out two after a timed transition with delay ``v_{put}``. Then it is *Idle* again and the cycle restarts.

The server's activity is described by the blue box. Following the Petri net, we should implement a state variable with states Idle and Busy, but we don't need to if we separate the activities in time. We need a data structure for the server and define a function for the activity:

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
      event!(𝐶, (SimFunction(put!, en.output, token), SimFunction(serve, en)), after, rand())
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

## Process based modeling

Here we combine it all in a simple function of **take!**-**delay!**-**put!**, like in the activity based example, but running in a loop of a process. Processes can wait or delay and are suspended and reactivated by Julia's scheduler according to background events. There is no need to handle events explicitly and no need for a server type since a process keeps its own data:

```julia
reset!(𝐶)

function simple(input::Channel, output::Channel, name, id, op)
    token = take!(input)         # take something, eventually wait for it
    @printf("%5.2f: %s %d took token %d\n", τ(), name, id, token)
    d = delay!(rand())           # wait for a given time
    put!(output, op(token, id))  # put something else out, eventually wait
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
...
...
 8.90: foo 3 took token 5551732
 9.10: bar 2 took token 5551735
 9.71: foo 5 took token 11103470
 9.97: bar 8 took token 11103475
10.09: foo 1 took token 88827800
"run! finished with 22 events, simulation time: 10.0"
```

## Comparison

All four approaches can be expressed in `Simulate.jl`. Process based modeling seems to be the simplest and the most intuitive approach, while the first three are more complicated. But they are also more structured, which comes in handy for more complicated examples. After all parallel processes are often tricky to control and to debug. But you can combine the approaches and take the best from all worlds.

## Combined approach

Physical systems can be modeled as **continuous systems** (nature does not jump), **discrete systems** (nature jumps here!) or **hybrid systems** (nature jumps sometimes).

While continuous systems are the domain of differential equations, discrete and hybrid systems may be modeled easier with `Simulate.jl` by combining the *event-scheduling*, the *process-based* and the *continuous-sampling* schemes.

### A hybrid system

(empty)

## Theories

There are some theories about the different approaches (1) event based, (2) state based, (3) activity based and (4) process based. Choi and Kang [^1] have written an entire book about the first three approaches. Basically they can be converted to each other. Cassandras and Lafortune [^2] call those "the event scheduling scheme" and the 4th approach "the process-oriented simulation scheme" [^3]. There are communities behind the various views and `Simulate.jl` wants to be useful for them all.

[^1]:  [Choi and Kang: *Modeling and Simulation of Discrete-Event Systems*, Wiley, 2013](https://books.google.com/books?id=0QpwAAAAQBAJ)
[^2]:  [Cassandras and Lafortune: *Introduction to Discrete Event Systems*, Springer, 2008, Ch. 10](https://books.google.com/books?id=AxguNHDtO7MC)
[^3]: to be fair, the 4th approach is called by Choi and Kang "parallel simulation".
