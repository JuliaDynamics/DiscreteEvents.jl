println("... testing multithreading  1 ...")

clk = Clock()
@test clk.id == 1
println("... fork! ...")
fork!(clk)
@test length(clk.ac) >= (nthreads() >>> 1)
# for i in 2:nthreads()
#     @test clk.ac[i-1].id == i
#     c = pclock(clk, i)
#     @test c.clock.id == i
# end
t1 = clk.ac[1].id        # get id of first parallel clock

println("... remote error handling ...")
@test talk(clk, t1, Simulate.Clear()).x isa ErrorException
st = talk(clk, t1, Simulate.Diag()).x[1]
@test occursin(r"^activeClock\(\:\:Channel\{Any\}\) at threads\.jl", string(st))

println("... register parallel events, cevents, samples ...")
a = 0
ev = Simulate.SimEvent(SF(()->global a+=1),Main,1.0,0.0)
@test talk(clk, t1, Simulate.Register(ev)).x == 1.0
c2 = pclock(clk, t1)
@test length(c2.clock.sc.events) == 1
cev = Simulate.SimCond(SF(≥, SF(tau, c2), 5), SF(()->global a+=1), Main)
@test talk(clk, t1, Simulate.Register(cev)).x == 0.0
@test length(c2.clock.sc.cevents) == 1
b = 0
sp = Simulate.Sample(SF(()->global b+=1), Main)
@test talk(clk, t1, Simulate.Register(sp)).x == true
@test length(c2.clock.sc.samples) == 1

println("... run parallel clock 1 (thread $t1) ...")
@test talk(clk, t1, Simulate.Run(10.0)).x == 10.0
@test c2.clock.time ≈ 10
@test c2.clock.scount == 1000
@test a == 2
@test b == 1000

println("... collapse! ...")
ac = clk.ac
collapse!(clk)
@test all(x->istaskdone(x.ref[]), ac)
@test all(x->x.ch.state == :closed, ac)
