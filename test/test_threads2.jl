using Printf

println("... test threading 2 ...")


# println("... test channel 4 example parallel ...")
# A = []
# ch1 = Channel(32)
# ch2 = Channel(32)
#
# function simple1(c::Clock, input::Channel, output::Channel, name, id, op)
#     token = take!(input)         # take something from the input
#     push!(A, (tau(c), name, id, token))
# #    println(@sprintf("%5.2f: %s %d took %d", tau(c), name, id, token))
#     d = delay!(c, rand())           # after a delay
# #    println(@sprintf("%5.2f: %s %d now after a delay ...", tau(c), name, id))
#     put!(output, op(token, id))  # put it out with some op applied
# #    println(@sprintf("%5.2f: %s %d sent %d", tau(c), name, id, op(token, id)))
# end
#
# clk = Clock(0.001)
# Random.seed!(123)
#
# for i in 1:2:8    # create, register and start 8 SimProcesses SP
#     process!(clk, SP(i, simple1, clk, ch1, ch2, "foo", i, +), spawn=true)
#     process!(clk, SP(i+1, simple1, clk, ch2, ch1, "bar", i+1, *), spawn=true)
# end
#
# @test length(clk.processes) == 8
# for p in values(clk.processes)
#     @test p.state == Simulate.Idle()
#     @test istaskstarted(p.task)
# end
#
# put!(ch1, 1)
# sleep(0.1)
# run!(clk, 10)
#
# # @test length(A) > 20
# # p = [i[3] for i in A]
# # for i in 1:8
# #     @test i ∈ p  # all processes did something
# # end
