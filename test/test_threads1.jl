const sleeptime = 0.3

println("... testing multithreading  1, (sleeptime=$sleeptime) ...")
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
err = diagnose(clk, 1)
@test err[1] isa ErrorException
@test occursin(r"^step\!\(\:\:ActiveClock.+ at threads\.jl", string(err[2][2]))

println("... testing channel and active clock ...")
a = 0
ev = Simulate.DiscreteEvent(fun(()->global a+=1),1.0,0.0)
put!(clk.ac[1].forth, Simulate.Register(ev))
sleep(0.1)
@test length(c1.clock.sc.events) == 1
cev = Simulate.DiscreteCond(fun(≥, fun(tau, c1), 5), fun(()->global a+=1))
put!(clk.ac[1].forth, Simulate.Register(cev))
sleep(0.1)
@test length(c1.clock.sc.cevents) == 1
b = 0
sp = Simulate.Sample(fun(()->global b+=1))
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

println("... parallel clock 1 reset ...")
put!(clk.ac[1].forth, Simulate.Reset(true))
@test take!(clk.ac[1].back).x == 1
@test c1.clock.time == 0
@test c1.clock.scount == 0

println("... testing register(!) five cases ... ")
ev1 = Simulate.DiscreteEvent(fun(()->global a+=1),1.0,0.0)
ev2 = Simulate.DiscreteEvent(fun(()->global a+=1),2.0,0.0)
Simulate._register(clk, ev1, 0)              # 1. register ev1 to clk
@test Simulate._nextevent(clk) == ev1
Simulate._register(clk, ev1, 1)              # 2. register ev1 to 1st parallel clock
sleep(sleeptime)
@test Simulate._nextevent(c1.clock) == ev1
Simulate._register(c1, ev2, 1)               # 3. register ev2 directly to 1st parallel clock
sleep(sleeptime)
@test length(c1.clock.sc.events) == 2
Simulate._register(c1, ev2, 0)               # 4. register ev2 back to master
sleep(sleeptime)
@test length(clk.sc.events) == 2

if nthreads() > 2                           # This fails on CI (only 2 threads)
    Simulate._register(c1, ev2, 2)           # 5. register ev2 to another parallel clock
    c2 = pclock(clk, 2)
    sleep(sleeptime)
    @test Simulate._nextevent(c2.clock) == ev2
end

println("... testing API on multiple threads ...")
clock = Vector{Clock}()
push!(clock, clk)
for i in eachindex(clk.ac)
    push!(clock, pclock(clk, i).clock)
end
println("    got $(length(clock)) clocks")
@test sum(length(c.sc.events) for c in clock) ≥ 4
reset!(clk)                                 # test reset! on multiple clocks
@test sum(length(c.sc.events) for c in clock) == 0
println("    reset!     ok")

a = zeros(Int, nthreads())
event!(clk, ()->a[1]+=1, 1)
event!(clk, ()->a[2]+=1, 1, cid=1)
event!(c1,  ()->a[2]+=1, 2)
event!(c1,  ()->a[1]+=1, 2, cid=0)
if nthreads() > 2
    event!(c1,  ()->a[3]+=1, 1, cid=2)
end
sleep(sleeptime)
@test length(clk.sc.events) == 2
@test length(c1.clock.sc.events) == 2
nthreads() > 2 && @test length(c2.clock.sc.events) == 1

println("... collapse! ...")
ac = clk.ac
collapse!(clk)
@test all(x->istaskdone(x.ref[]), ac)
@test all(x->x.ch.state == :closed, ac)
