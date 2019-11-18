#
# This example shows the use of processes and channels with Simulate.jl
#
# pb, 2019-11-09
#

using Simulate, Printf, Random

function simple(input::Channel, output::Channel, name, id, op)
    token = take!(input)         # take something from the input
    now!(SF(println, @sprintf("%5.2f: %s %d took token %d", tau(), name, id, token)))
    d = delay!(rand())           # after a delay
    put!(output, op(token, id))  # put it out with some op applied
end

reset!(𝐶)
Random.seed!(123)

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8    # create and register 8 SimProcesses SP
    process!(SP(i, simple, ch1, ch2, "foo", i, +))
    process!(SP(i+1, simple, ch2, ch1, "bar", i+1, *))
end

put!(ch1, 1)  # put first token into channel 1
run!(𝐶, 10)   # and run for 10 time units
