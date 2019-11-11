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

    Server(id, name, input, output, op) = new(id, name, input, output, op, Idle, nothing)
end

δ(A::Server, ::Idle, ::Arrive) = (A.state=Busy(); event!(𝐅(δ,A,A.state,Leave()), after, rand())
δ(A::Server, ::Busy, ::Leave) = put(A)
δ(A::Server, q::Q, σ::Σ) = println(stderr, "$(A.name) $(A.id) undefined transition $q, $σ")

function take(A::Server)
    if isempty(A.input)
        event!(𝐅(take, A), !isempty(A.input))
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
