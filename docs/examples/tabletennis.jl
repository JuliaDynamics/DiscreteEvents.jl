using Sim, Printf
import Sim.init!

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

const dist = 3 # distance for ball to fly [m]
const vs   = 10 # serve velocity [m/s]
const vr   = 20 # return velocity [m/s]

rd(s::Float64) = randn()*s + 1

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

ping = Player("Ping", 0.90, 0.90)
pong = Player("Pong", 0.90, 0.90)
init!(ping, pong)
init!(pong, ping)
step!(ping, Start())

run!(𝐶, 30)
println("Ping scored $(ping.score)")
println("Pong scored $(pong.score)")

reset!(𝐶)
