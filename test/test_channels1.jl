#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

mutable struct Server
  id::Int
  name::String
  input::Channel
  output::Channel
  op     # operation to take
  token  # current token

  Server(id, name, input, output, op) = new(id, name, input, output, op, nothing)
end

A = []

function take(S::Server)
    if isready(S.input)
        S.token = take!(S.input)
        push!(A, (tau(), S.name, S.id, S.token))
        event!(Fun(put, S), after, rand())         # call put after some time
    else
        event!(Fun(take, S), Fun(isready, S.input)) # call again if input is ready
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

si = shuffle(1:8)
for i in 1:2:8
    take(Server(si[i], "foo", ch1, ch2, +))
    take(Server(si[i+1], "bar", ch2, ch1, *))
end

put!(ch1, 1) # put first token into channel 1
run!(𝐶, 10)

@test length(A) > 20
p = [i[3] for i in A]
for i in 1:8
    @test i ∈ p  # all processes did something
end
