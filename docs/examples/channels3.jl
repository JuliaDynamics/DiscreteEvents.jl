# the channel example using an activity-based approach
#
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
