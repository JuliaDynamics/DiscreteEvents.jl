#
# This example shows the use of processes and channels with Simulate.jl
#
# pb, 2019-11-09
#

using Simulate, Printf
reset!(𝐶) # reset the central clock

# a function with Channels input and output as the first
# two arguments can be registered as a SimProcess
# the function is put in a loop, so no need to have a loop here
function simple(input::Channel, output::Channel, name, id, op)
    token = take!(input)         # take something from the input
    @printf("%5.2f: %s %d took token %d\n", τ(), name, id, token)
    d = delay!(rand())           # after a delay
    put!(output, op(token, id))  # put it out with some op applied
end

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8    # create and register 8 SimProcesses 𝐏
    process!(𝐏(i, simple, ch1, ch2, "foo", i, +))
    process!(𝐏(i+1, simple, ch2, ch1, "bar", i+1, *))
end

start!(𝐶)     # start all registered processes
put!(ch1, 1)  # put first token into channel 1

sleep(0.1)    # give the processes some time to startup

run!(𝐶, 10)   # an run for 10 time units
