#
# This example shows the use of processes and channels with Simulate.jl
#
# pb, 2019-11-07
#

using Simulate, Printf
reset!(𝐶)

function foo(in::Channel, out::Channel, id)
    token = take!(in)
    @printf("%5.2f: foo %d took token %d\n", τ(), id, token)
    d = delay!(rand())
    put!(out, token+id)
end

function bar(in::Channel, out::Channel, id)
    token = take!(in)
    @printf("%5.2f: bar %d took token %d\n", τ(), id, token)
    d = delay!(rand())
    put!(out, token*id)
end

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8    # create and register SimProcesses
    process!(𝐶, SimProcess(i, foo, ch1, ch2, i))
    process!(𝐶, SimProcess(i+1, bar, ch2, ch1, i+1))
end

start!(𝐶) # start all registered processes
put!(ch1, 1) # put first token into channel 1

sleep(0.1) # we give the processes some time to startup

run!(𝐶, 10)
