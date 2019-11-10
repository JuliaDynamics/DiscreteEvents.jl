# the channel example using a activity-based approach
#

mutable struct Server
  id::Int64
  name::AbstractString
  input::Channel
  output::Channel
  op     # operation to take
  token  # current token

  Server(id, name, input, output, op) = new(id, name, input, output, op, nothing)
end

cond(en) = !isempty(en.input) && en.state == Idle

function serve(en::Server)
    if isempty(en.input)
      event!(𝐶, SimFunction(take, en), !isempty(en.input))
    else
      en.token = take!(en.input)
      @printf("%5.2f: %s %d took token %d\n", τ(), en.name, en.id, en.token)
      event!(𝐶, SimFunction((put!, en.output, token), (serve, en)), after, rand())
    end
end

reset!(𝐶)

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8
    serve(Server(i, "foo", ch1, ch2, +))
    serve(Server(i+1, "bar", ch2, ch1, *))
end

put!(ch1, 1) # put first token into channel 1

# run!(𝐶, 10)

println("conditional events are not yet implemented !!")
