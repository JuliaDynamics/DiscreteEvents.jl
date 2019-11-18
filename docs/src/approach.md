# Approaches to modeling and simulation

`Simulate.jl` supports different approaches to modeling and simulation of **discrete event systems (DES)**. It provides three major schemes:

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

function take(S::Server)
    if isready(S.input)
        S.token = take!(S.input)
        @printf("%5.2f: %s %d took token %d\n", tau(), S.name, S.id, S.token)
        event!(SF(put, S), after, rand())         # call put after some time
    else
        event!(SF(take, S), SF(isready, S.input)) # call again if input is ready
    end
end

function put(S::Server)
    put!(S.output, S.op(S.id, S.token))
    S.token = nothing
    take(S)
end

reset!(𝐶)
Random.seed!(123)

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

s = shuffle(1:8)
for i in 1:2:8
    take(Server(s[i], "foo", ch1, ch2, +))
    take(Server(s[i+1], "bar", ch2, ch1, *))
end

put!(ch1, 1) # put first token into channel 1

run!(𝐶, 10)
```

When running, this gives us as output:

```julia
julia> include("docs/examples/channels1.jl")
 0.01: foo 4 took token 1
 0.12: bar 6 took token 5
 0.29: foo 1 took token 30
 0.77: bar 8 took token 31
 1.64: foo 2 took token 248
 2.26: bar 3 took token 250
 2.55: foo 7 took token 750
 3.02: bar 5 took token 757
 3.30: foo 4 took token 3785
 3.75: bar 6 took token 3789
 4.34: foo 1 took token 22734
 4.60: bar 8 took token 22735
 5.31: foo 2 took token 181880
 5.61: bar 3 took token 181882
 5.90: foo 7 took token 545646
 6.70: bar 5 took token 545653
 6.91: foo 4 took token 2728265
 7.83: bar 6 took token 2728269
 8.45: foo 1 took token 16369614
 9.26: bar 8 took token 16369615
 9.82: foo 2 took token 130956920
"run! finished with 20 clock events, simulation time: 10.0"
```

## State based modeling

Here our server has three states: **Idle**, **Busy** and **End** (where *End* does nothing). On an arrival event it resets its internal clock ``x=0`` and determines the service time ``t_s``, moves to *Busy*, *works* on its input and puts it out when service time is over. Then it goes back to *Idle*. A state transition diagram (Mealy model) of the timed automaton would look like:

![timed automaton](images/state.png)

Again we have a data structure for the server (containing a state). We define states and events and implement a `δ` transition function with two methods. Thereby we dispatch on states and events. Since we don't implement all combinations of states and events, we may implement a fallback transition.

```julia
using Simulate, Printf, Random

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

    Server(id, name, input, output, op) = new(id, name, input, output, op, Idle(), nothing)
end

arrive(A) = event!(SF(δ, A, A.state, Arrive()), SF(isready, A.input))

function δ(A::Server, ::Idle, ::Arrive)
    A.token = take!(A.input)
    @printf("%5.2f: %s %d took token %d\n", tau(), A.name, A.id, A.token)
    A.state=Busy()
    event!(SF(δ, A, A.state, Leave()), after, rand())
end

function δ(A::Server, ::Busy, ::Leave)
    put!(A.output, A.op(A.id,A.token))
    A.state=Idle()
    arrive(A)
end

δ(A::Server, q::Q, σ::Σ) =               # fallback transition
        println(stderr, "$(A.name) $(A.id) undefined transition $q, $σ")

reset!(𝐶)
Random.seed!(123)

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

s = shuffle(1:8)
for i in 1:2:8
    arrive(Server(s[i], "foo", ch1, ch2, +))
    arrive(Server(s[i+1], "bar", ch2, ch1, *))
end

put!(ch1, 1) # put first token into channel 1

run!(𝐶, 10)
```

When running, this gives us as output:

```julia
julia> include("docs/examples/channels2.jl")
 0.01: foo 4 took token 1
 0.12: bar 6 took token 5
 0.29: foo 1 took token 30
 0.77: bar 8 took token 31
 1.64: foo 2 took token 248
 2.26: bar 3 took token 250
 2.55: foo 7 took token 750
 3.02: bar 5 took token 757
 3.30: foo 4 took token 3785
 3.75: bar 6 took token 3789
 4.34: foo 1 took token 22734
 4.60: bar 8 took token 22735
 5.31: foo 2 took token 181880
 5.61: bar 3 took token 181882
 5.90: foo 7 took token 545646
 6.70: bar 5 took token 545653
 6.91: foo 4 took token 2728265
 7.83: bar 6 took token 2728269
 8.45: foo 1 took token 16369614
 9.26: bar 8 took token 16369615
 9.82: foo 2 took token 130956920
"run! finished with 20 clock events, simulation time: 10.0"
```

## Activity based modeling

Our server's *activity* is the processing of the token. A timed Petri net would look like:

![timed petri net](images/activity.png)

The **arrive** transition puts a token in the **Queue**. If both places **Idle** and **Queue** have tokens, the server **takes** them, shifts one to **Busy** and **puts** out two after a timed transition with delay ``v_{put}``. Then it is *Idle* again and the cycle restarts.

The server's activity is described by the blue box. Following the Petri net, we should implement a state variable with states Idle and Busy, but we don't need to if we separate the activities in time. We need a data structure for the server and define a function for the activity:

```julia
using Simulate, Printf, Random

mutable struct Server
  id::Int64
  name::AbstractString
  input::Channel
  output::Channel
  op     # operation
  token  # current token

  Server(id, name, input, output, op) = new(id, name, input, output, op, nothing)
end

arrive(S::Server) = event!(SF(serve, S), SF(isready, S.input))

function serve(S::Server)
    S.token = take!(S.input)
    @printf("%5.2f: %s %d took token %d\n", tau(), S.name, S.id, S.token)
    event!((SF(put!, S.output, S.op(S.id, S.token)), SF(arrive, S)), after, rand())
end

reset!(𝐶)
Random.seed!(123)

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

s = shuffle(1:8)
for i in 1:2:8
    arrive(Server(s[i], "foo", ch1, ch2, +))
    arrive(Server(s[i+1], "bar", ch2, ch1, *))
end

put!(ch1, 1) # put first token into channel 1

run!(𝐶, 10)
```

When running, this gives us as output:

```julia
julia> include("docs/examples/channels3.jl")
 0.01: foo 4 took token 1
 0.12: bar 6 took token 5
 0.29: foo 1 took token 30
 0.77: bar 8 took token 31
 1.64: foo 2 took token 248
 2.26: bar 3 took token 250
 2.55: foo 7 took token 750
 3.02: bar 5 took token 757
 3.30: foo 4 took token 3785
 3.75: bar 6 took token 3789
 4.34: foo 1 took token 22734
 4.60: bar 8 took token 22735
 5.31: foo 2 took token 181880
 5.61: bar 3 took token 181882
 5.90: foo 7 took token 545646
 6.70: bar 5 took token 545653
 6.91: foo 4 took token 2728265
 7.83: bar 6 took token 2728269
 8.45: foo 1 took token 16369614
 9.26: bar 8 took token 16369615
 9.82: foo 2 took token 130956920
"run! finished with 20 clock events, simulation time: 10.0"
```

## Process based modeling

Here we combine it all in a simple function of **take!**-**delay!**-**put!** like in the activity based example, but running in a loop of a process. Processes can wait or delay and are suspended and reactivated by Julia's scheduler according to background events. There is no need to handle events explicitly and no need for a server type since a process keeps its own data. But processes must look to their timing and therefore they must enclose the IO-operation in a `now!` call:

```julia
reset!(𝐶)

function simple(input::Channel, output::Channel, name, id, op)
    token = take!(input)         # take something, eventually wait for it
    now!(SF(println, @sprintf("%5.2f: %s %d took token %d", tau(), name, id, token)))
    d = delay!(rand())           # wait for a given time
    put!(output, op(token, id))  # put something else out, eventually wait
end

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8    # create and register 8 SimProcesses
    process!(𝐶, SimProcess(i, simple, ch1, ch2, "foo", i, +))
    process!(𝐶, SimProcess(i+1, simple, ch2, ch1, "bar", i+1, *))
end

put!(ch1, 1) # put first token into channel 1

run!(𝐶, 10)
```

and runs like:

```julia
julia> include("docs/examples/channels4.jl")
 0.00: foo 7 took token 1
 0.77: bar 4 took token 8
 1.71: foo 3 took token 32
 2.38: bar 2 took token 35
 2.78: foo 5 took token 70
 3.09: bar 8 took token 75
 3.75: foo 1 took token 600
 4.34: bar 6 took token 601
 4.39: foo 7 took token 3606
 4.66: bar 4 took token 3613
 4.77: foo 3 took token 14452
 4.93: bar 2 took token 14455
 5.41: foo 5 took token 28910
 6.27: bar 8 took token 28915
 6.89: foo 1 took token 231320
 7.18: bar 6 took token 231321
 7.64: foo 7 took token 1387926
 7.91: bar 4 took token 1387933
 8.36: foo 3 took token 5551732
 8.94: bar 2 took token 5551735
 9.20: foo 5 took token 11103470
 9.91: bar 8 took token 11103475
"run! finished with 21 clock events, simulation time: 10.0"
```


## Comparison

The output of the last example is different from the first three approaches because we did not need to shuffle and the shuffling of the processes is done by the scheduler. So if the output depends very much on the sequence of events and you need to have reproducible results, explicitly controlling for the events like in the first three examples is preferable. If you are more interested in statistical evaluation - which is often the case -, the 4th approach is also appropriate.

All four approaches can be expressed in `Simulate.jl`. Process based modeling seems to be the simplest and the most intuitive approach, while the first three are more complicated. But they are also more structured and controllable , which comes in handy for more complicated examples. After all, parallel processes are often tricky to control and to debug. But you can combine the approaches and take the best from all worlds.

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
