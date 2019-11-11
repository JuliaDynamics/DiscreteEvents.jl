# the channel example using an event-based approach
#

using Simulate, Printf, Random

mutable struct Entity
  id::Int64
  name::AbstractString
  input::Channel
  output::Channel
  op     # operation to take
  token  # current token

  Entity(id, name, input, output, op) = new(id, name, input, output, op, nothing)
end

function take(en::Entity)
    isempty(en.input) || event!(𝐅(take, en), :(!isempty(en.input)))
    en.token = take!(en.input)
    @printf("%5.2f: %s %d took token %d\n", τ(), en.name, en.id, en.token)
    proc(en)
end

proc(en) = event!(𝐅(put, en), after, rand())

function put(en)
    put!(en.output, en.op(en.id, ))
    en.token = nothing
    take(en)
end

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8
    take(Entity(i, "foo", ch1, ch2, +))
    take(Entity(i+1, "bar", ch2, ch1, *))
end

put!(ch1, 1) # put first token into channel 1

# run!(𝐶, 10)
println("conditional events are not yet implemented !!")
