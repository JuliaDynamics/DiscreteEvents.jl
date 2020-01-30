println("... testing multithreading  1 ...")

clk = PClock()
@test clk.id == 0
@test length(clk.ac) >= (nthreads() >>> 1)
# for i in 2:nthreads()
#     @test clk.ac[i-1].id == i
#     c = pclock(clk, i)
#     @test c.clock.id == i
# end
@test clk.ac[1].thread == 2

println("... parallel clock identification ...")
c1 = pclock(clk, 1)
@test c1.thread == 2
@test c1.clock.id == 1

println("... remote error handling ...")
put!(clk.ac[1].forth, Simulate.Clear())
err = diag(clk, 1)
@test err[1] isa ErrorException
@test occursin(r"^step\!\(\:\:ActiveClock.+ at threads\.jl", string(err[2][2]))

println("... register parallel events, cevents, samples ...")
a = 0
ev = Simulate.DiscreteEvent(Fun(()->global a+=1),Main,1.0,0.0)
put!(clk.ac[1].forth, Simulate.Register(ev))
sleep(0.01)
@test length(c1.clock.sc.events) == 1
cev = Simulate.DiscreteCond(Fun(≥, Fun(tau, c1), 5), Fun(()->global a+=1), Main)
put!(clk.ac[1].forth, Simulate.Register(cev))
sleep(0.01)
@test length(c1.clock.sc.cevents) == 1
b = 0
sp = Simulate.Sample(Fun(()->global b+=1), Main)
put!(clk.ac[1].forth, Simulate.Register(sp))
sleep(0.01)
@test length(c1.clock.sc.samples) == 1

println("... run parallel clock 1 (thread 2) ...")
put!(clk.ac[1].forth, Simulate.Run(10.0))
sleep(0.1)
@test c1.clock.time ≈ 10
@test c1.clock.scount == 1000
@test a == 2
@test b == 1000

println("... collapse! ...")
ac = clk.ac
collapse!(clk)
@test all(x->istaskdone(x.ref[]), ac)
@test all(x->x.ch.state == :closed, ac)
