# Table tennis

In table tennis we have some physical constraints, standard moves and rules, but uncertainty in execution due to lack of accuray and attentiveness of the players and so on.

First we need to call the needed modules:

```julia
using Simulate, Printf
import Simulate.init!
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

Some functions describe the setup of players, serve and return.

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
        event!(𝐶, SF(step!, p.opp, Serve()), after, ts)
        @printf("%5.2f: %s serves %s\n", tau()+ts, p.name, p.opp.name)
    else
        event!(𝐶, SF(step!, p.opp, Miss()), after, ts)
        @printf("%5.2f: %s serves and misses %s\n", tau()+ts, p.name, p.opp.name)
    end
    if rand() ≥ p.attentiveness
        p.state = Unalert()
    end
end

function ret(p::Player)
    tr = dist*rd(0.15)/(vr*rd(0.25))
    if rand() ≤ p.accuracy
        event!(𝐶, SF(step!, p.opp, Return()), after, tr)
        @printf("%5.2f: %s returns %s\n", tau()+tr, p.name, p.opp.name)
    else
        event!(𝐶, SF(step!, p.opp, Miss()), after, tr)
        @printf("%5.2f: %s returns and misses %s\n", tau()+tr, p.name, p.opp.name)
    end
    if rand() ≥ p.attentiveness
        p.state = Unalert()
    end
end
```

We can model the players as state machines. Their behaviour is described by the following `step!`-transition functions, leading to some actions and a new state.

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
    @printf("%5.2f: %s looses ball\n", τ(), p.name)
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

We define and setup the players and give Ping the `Start()` command.

```julia
ping = Player("Ping", 0.90, 0.90)
pong = Player("Pong", 0.90, 0.90)
init!(ping, pong)
init!(pong, ping)
step!(ping, Start())
```

Finally we setup a simulation and analysis of the results:

```julia
Random.seed!(123)

println(run!(𝐶, 30))
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
run! finished with 47 clock events, 0 sample steps, simulation time: 30.0
Ping scored 3
Pong scored 5
```

Finally we reset the clock for further simulations:

```julia
julia> reset!(𝐶)
clock reset to t₀=0, sampling rate Δt=0.
```

**See also:** [`event!`](@ref), [`SF`](@ref SimFunction), [`tau`](@ref), [`𝐶`](@ref),  [`run!`](@ref), [`reset!`](@ref)
