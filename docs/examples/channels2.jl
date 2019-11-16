# the channel example using a state-based approach
#
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

arrive(A::Server) = event!(SF(δ, A, A.state, Arrive()), SF(isready, A.input))

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
