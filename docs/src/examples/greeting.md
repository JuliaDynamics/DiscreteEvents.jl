### Two guys meet

If two guys meet, there is some standard verbiage, but some uncertainty in how long they need to greet and respond. We can simulate this as an introductory example.

We call the needed modules and define some types and data:

```julia
using Sim, Printf

struct Guy
    name
end

abstract type Encounter end
struct Meet <: Encounter
    someone
end
struct Greet <: Encounter
    num
    from
end
struct Response <: Encounter
    num
    from
end

comm = ("Nice to meet you!", "How are you?", "Have a nice day!", "bye bye")
```

We implement the behavior of the "guys" as `step!`-δ-functions of a state machine. For that we use some features of `Sim.jl`:

- `Τ` or `Tau` is the central clock,
- `SimFunction` prepares a Julia function for later execution,
- `event!` schedules it for execution `after` some time,
- `τ()` gives the central time (`T.time`).


```julia
say(name, n) =  @printf("%5.2f s, %s: %s\n", τ(), name, comm[n])

function step!(me::Guy, σ::Meet)
    event!(Τ, SimFunction(step!, σ.someone, Greet(1, me)), after, 2*rand())
    say(me.name, 1)
end

function step!(me::Guy, σ::Greet)
    if σ.num < 3
        event!(Τ, SimFunction(step!, σ.from, Response(σ.num, me)), after, 2*rand())
        say(me.name, σ.num)
    else
        say(me.name, 4)
    end
end

function step!(me::Guy, σ::Response)
    event!(Τ, SimFunction(step!, σ.from, Greet(σ.num+1, me)), after, 2*rand())
    say(me.name, σ.num+1)
end
```

Then we define some "guys" and a starting event and tell the clock `Τ` to `run` for twenty "seconds":

```julia
foo = Guy("Foo")
bar = Guy("Bar")

event!(Τ, SimFunction(step!, foo, Meet(bar)), at, 10*rand())
run!(Τ, 20)
```

If we source this code, it will run a simulation:

```julia
julia> include("docs/examples/greeting.jl")
 7.30 s, Foo: Nice to meet you!
 8.00 s, Bar: Nice to meet you!
 9.15 s, Foo: How are you?
10.31 s, Bar: How are you?
11.55 s, Foo: Have a nice day!
12.79 s, Bar: bye bye
Finished: 6 events, simulation time: 20.0
```

Then we `reset` the clock `Τ` for further simulations.

```julia
julia> reset!(Τ)
clock reset to t₀=0, sampling rate Δt=0.
```
