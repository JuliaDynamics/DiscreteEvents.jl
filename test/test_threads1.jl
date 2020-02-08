println("... testing multithreading  1 ...")
println("number of available threads: ", nthreads())

clk = PClock()
print(clk)
@test clk.id == 0
m = match(r"Clock thread 1 \(\+ (\d+) ac\)", repr(clk))
@test parse(Int, m.captures[1]) > 0
@test length(clk.ac) >= (nthreads() >>> 1)
@test clk.ac[1].thread == 2

println("... parallel clock identification ...")
c1 = pclock(clk, 1)
@test c1.thread == 2
@test c1.clock.id == 1
m = match(r"Active clock 1 on thrd (\d+)\:", repr(c1))
@test parse(Int, m.captures[1]) > 1

println("... remote error handling ...")
put!(clk.ac[1].forth, Simulate.Clear())
err = diag(clk, 1)
@test err[1] isa ErrorException
@test occursin(r"^step\!\(\:\:ActiveClock.+ at threads\.jl", string(err[2][2]))

println("... testing channel and active clock ...")
a = 0
ev = Simulate.DiscreteEvent(Fun(()->global a+=1),Main,1.0,0.0)
put!(clk.ac[1].forth, Simulate.Register(ev))
sleep(0.1)
@test length(c1.clock.sc.events) == 1
cev = Simulate.DiscreteCond(Fun(≥, Fun(tau, c1), 5), Fun(()->global a+=1), Main)
put!(clk.ac[1].forth, Simulate.Register(cev))
sleep(0.1)
@test length(c1.clock.sc.cevents) == 1
b = 0
sp = Simulate.Sample(Fun(()->global b+=1), Main)
put!(clk.ac[1].forth, Simulate.Register(sp))
sleep(0.1)
@test length(c1.clock.sc.samples) == 1

println("... run parallel clock 1 (thread 2) ...")
put!(clk.ac[1].forth, Simulate.Run(10.0))
sleep(0.5)
@test c1.clock.time ≈ 10
@test c1.clock.scount == 1000
@test a == 2
@test b == 1000

println("... testing register(!) five cases ... ")
reset!(c1.clock)
@test c1.clock.time == 0
ev1 = Simulate.DiscreteEvent(Fun(()->global a+=1),Main,1.0,0.0)
ev2 = Simulate.DiscreteEvent(Fun(()->global a+=1),Main,2.0,0.0)
Simulate.register(clk, ev1, 0)              # 1. register ev1 to clk
@test Simulate.nextevent(clk) == ev1
Simulate.register(clk, ev1, 1)              # 2. register ev1 to 1st parallel clock
@test Simulate.nextevent(c1.clock) == ev1
Simulate.register(c1, ev2, 1)               # 3. register ev2 directly to 1st parallel clock
@test length(c1.clock.sc.events) == 2
Simulate.register(c1, ev2, 0)               # 4. register ev2 back to master
@test length(clk.sc.events) == 2

if nthreads() > 2                           # This fails on CI (only 2 threads)
    Simulate.register(c1, ev2, 2)           # 5. register ev2 to another parallel clock
    c2 = pclock(clk, 2)
    @test Simulate.nextevent(c2.clock) == ev2
end

println("... collapse! ...")
ac = clk.ac
collapse!(clk)
@test all(x->istaskdone(x.ref[]), ac)
@test all(x->x.ch.state == :closed, ac)
