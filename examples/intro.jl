#
# introductory example in README.md
#
using DiscreteEvents, Printf, Random

function simple(c::Clock, input::Channel, output::Channel, name, id, op)
    token = take!(input)         # take something from the input
    print(c, @sprintf("%5.2f: %s %d took token %d\n", tau(c), name, id, token))
    delay!(c, rand())            # after a delay
    put!(output, op(token, id))  # put it out with some op applied
end

clk = Clock()      # create a clock
Random.seed!(123)  # seed the random number generator

ch1 = Channel(32)  # create two channels
ch2 = Channel(32)

for i in 1:2:8     # create and register 8 SimProcesses SP
    process!(clk, Prc(i, simple, ch1, ch2, "foo", i, +))
    process!(clk, Prc(i+1, simple, ch2, ch1, "bar", i+1, *))
end

put!(ch1, 1)       # put first token into channel 1
yield()            # let the first task take it
run!(clk, 10)      # and run for 10 time units
