### Table tennis

In table tennis we have some physical constraints, standard moves and rules, but uncertainty in execution due to lack of accuray and attentiveness of the players and so on.

We can model the players as state machines and do a simulation on it.

First we need to call the needed modules:

```julia
using Sim, Printf
import Sim.init!
```

Then we need some definitions for states, events and players:

```julia
abstract type PState end
struct Idle <: PState end
struct Wait <: PState end
struct Unalert <: PState end

abstract type PEvent end
struct Start <: PEvent end
struct Serve <: PEvent end
struct Return <: PEvent end
struct Miss <: PEvent end

mutable struct Player
    name::AbstractString
    opp::Union{Number,Player}
    state::PState
    accuracy::Float64
    attentiveness::Float64
    score::Int64

    Player(name, acc, att) = new(name, 0, Idle(), acc, att, 0)
end
```

We have to define the physical facts and a function to randomize them:

```julia
const dist = 3 # distance for ball to fly [m]
const vs   = 10 # serve velocity [m/s]
const vr   = 20 # return velocity [m/s]

rd(s::Float64) = randn()*s + 1
```

Some functions describe the setup of players, serve and return. Here we use the following features of `Sim.jl`:

- italic `𝐶` (`\itC`+Tab) or `Clk` is the central clock,
- `τ()` or `tau()` gives the central time,
- `event!` schedules an expression (or a function) for execution `after` some time on `𝐶`s timeline.

```julia
function init!(p::Player, opp::Player)
    p.opp = opp
    if rand() ≤ p.attentiveness
        p.state = Wait()
    else
        p.state = Unalert()
    end
end

function serve(p::Player)
    ts = 3 + dist*rd(0.15)/(vs*rd(0.25))
    if (rand() ≤ p.accuracy) && (p.state == Wait())
        event!(𝐶, :(step!($(p.opp), Serve())), after, ts)
        @printf("%.2f: %s serves %s\n", τ()+ts, p.name, p.opp.name)
    else
        event!(𝐶, :(step!($(p.opp), Miss())), after, ts)
        @printf("%.2f: %s serves and misses %s\n", τ()+ts, p.name, p.opp.name)
    end
    if rand() ≥ p.attentiveness
        p.state = Unalert()
    end
end

function ret(p::Player)
    tr = dist*rd(0.15)/(vr*rd(0.25))
    if rand() ≤ p.accuracy
        event!(𝐶, :(step!($(p.opp), Return())), after, tr)
        @printf("%.2f: %s returns %s\n", τ()+tr, p.name, p.opp.name)
    else
        event!(𝐶, :(step!($(p.opp), Miss())), after, tr)
        @printf("%.2f: %s returns and misses %s\n", τ()+tr, p.name, p.opp.name)
    end
    if rand() ≥ p.attentiveness
        p.state = Unalert()
    end
end
```

**Note:** In this case of scheduling an expression we need to interpolate `p.opp` with `$(p.opp)` to ensure that our `step!`-function gets the right player. Instead of scheduling expressions we normally would have scheduled our functions with `SimFunction(step!, p.opp, Serve())`, which eliminates the need for interpolation.

The behavior of a player is described by the following `step!`-δ transition functions with δ(p, qᵦ, σ) → qᵧ leading to some actions and a new state.

```julia
"default transition for players"
step!(p::Player, q::PState, σ::PEvent) =
        println("undefined transition for $(p.name), $q, $σ")

"player p gets a start command"
step!(p::Player, ::Union{Wait, Unalert}, ::Start) = serve(p)

"player p is waiting and gets served or returned"
step!(p::Player, ::Wait, ::Union{Serve, Return}) = ret(p)

"player p is unalert and gets served or returned"
function step!(p::Player, ::Unalert, ::Union{Serve, Return})
    @printf("%.2f: %s looses ball\n", τ(), p.name)
    p.opp.score += 1
    p.state = Wait()
    serve(p)
end

"player p is waiting or unalert and gets missed"
function step!(p::Player, ::Union{Wait, Unalert}, ::Miss)
    p.score += 1
    p.state = Wait()
    serve(p)
end

"simplified `step!` call"
step!(p::Player, σ::PEvent) = step!(p, p.state, σ)
```

Next we define and setup the players and give Ping the `Start()` command.

```julia
ping = Player("Ping", 0.90, 0.90)
pong = Player("Pong", 0.90, 0.90)
init!(ping, pong)
init!(pong, ping)
step!(ping, Start())
```

Finally we setup a simulation and analysis of the results:

```julia
run!(𝐶, 30)
println("Ping scored $(ping.score)")
println("Pong scored $(pong.score)")
```

If we source this code, the simulation runs:

```julia
julia> include("docs/examples/tabletennis.jl")
3.35: Ping serves Pong
3.47: Pong returns and misses Ping
6.82: Ping serves Pong
6.96: Pong returns Ping
7.15: Ping returns Pong
7.28: Pong returns Ping
7.54: Ping returns Pong
7.80: Pong returns Ping
7.80: Ping looses ball
11.27: Ping serves Pong
11.45: Pong returns Ping
11.59: Ping returns Pong
11.92: Pong returns Ping
12.08: Ping returns Pong
12.08: Pong looses ball
15.59: Pong serves Ping
15.59: Ping looses ball
18.75: Ping serves Pong
18.91: Pong returns Ping
18.91: Ping looses ball
22.15: Ping serves Pong
22.30: Pong returns Ping
22.30: Ping looses ball
25.62: Ping serves Pong
25.83: Pong returns Ping
26.19: Ping returns and misses Pong
29.50: Pong serves and misses Ping
32.75: Ping serves Pong
Finished: 22 events, simulation time: 30.0
Ping scored 3
Pong scored 5
```

Finally we should reset the clock for following simulations:

```julia
julia> reset!(𝐶)
clock reset to t₀=0, sampling rate Δt=0.
```
