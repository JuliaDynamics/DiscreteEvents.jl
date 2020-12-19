#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# This is a Julia package for discrete event simulation
#
# ------------------------------------------
# mostly static tests of multithreading
#
sleeptime = 0.5
a = [0.0]
b = [0.0]
c = [0.0]
d = [0.0]
incr!(x) = x[1] += 1

println("... testing multithreading  stage 1, (sleeptime=$sleeptime) ...")
println("number of available threads: ", nthreads())

clk = PClock()
Δt = clk.Δt
sleep(sleeptime)

print(clk)
@test clk.id == 1
m = match(r"Clock 1 \(\+(\d+)\)", repr(clk))
@test parse(Int, m.captures[1]) == nthreads()-1
@test length(clk.ac) == nthreads()-1
@test clk.ac[1].thread == 2

# parallel clock identification 
id = nthreads()+1
@test_warn "parallel clock $id not available!" pclock(clk, id)
c2 = pclock(clk, 2)
@test c2.id == 2
@test c2.clock.id == 2
@test c2.clock.ac[].master[].id == 1
m = match(r"Active clock (\d+)\:", repr(c2))
@test parse(Int, m.captures[1]) == 2
@test pclock(c2.clock, 2) isa DiscreteEvents.ActiveClock
@test clk == pclock(c2.clock, 1)

# test fork!
@test_warn "only the master clock" fork!(c2.clock)

# test _cid with parallel clocks
@test DiscreteEvents._cid(clk, 2, false) == 2
@test DiscreteEvents._cid(clk, 2, true) in 1:nthreads()
@test DiscreteEvents._cid(clk, nthreads()+1, false) == 1
@test DiscreteEvents._cid(clk, nthreads()+1, true) in 1:nthreads()
@test DiscreteEvents._cid(c2, 2, false) == 2
@test DiscreteEvents._cid(c2, 2, true) in 1:nthreads()
@test DiscreteEvents._cid(c2, 1, false) == 1
@test DiscreteEvents._cid(c2, 1, true) == 1
@test DiscreteEvents._cid(c2, nthreads()+1, false) == 2
@test DiscreteEvents._cid(c2, nthreads()+1, true) in 1:nthreads()
@test DiscreteEvents._cid(c2.clock, 2, false) == 2
@test DiscreteEvents._cid(c2.clock, 2, true) in 1:nthreads()
@test DiscreteEvents._cid(c2.clock, 1, false) == 1
@test DiscreteEvents._cid(c2.clock, 1, true) == 1
@test DiscreteEvents._cid(c2.clock, nthreads()+1, false) == 2
@test DiscreteEvents._cid(c2.clock, nthreads()+1, true) in 1:nthreads()

# exception handling and diagnosis
if DiscreteEvents._handle_exceptions[1]
    println("... remote error handling ...")
    put!(clk.ac[1].forth, DiscreteEvents.Clear())
    sleep(sleeptime)
    err = diagnose(clk, 2)
    @test err[1] isa ErrorException
    # @test occursin(r"^step\!\(\:\:DiscreteEvents.ActiveClock.+ at threads\.jl", string(err[2][2]))
end
old = DiscreteEvents._handle_exceptions[1]
DiscreteEvents._handle_exceptions[1] = false
put!(clk.ac[1].forth, DiscreteEvents.Clear())
sleep(sleeptime)
@test diagnose(clk, 2).state === :failed
DiscreteEvents._handle_exceptions[1] = old
@test_warn "parallel clock $id not available!" diagnose(clk, id)

# now testing parallel events and runs 
#
# start a parallel clock again
clk = PClock()
Δt = clk.Δt
sleep(sleeptime)
c2 = pclock(clk, 2)

function pinc!(c::Clock, x)
    delay!(c, 1)
    incr!(x)
end

println("... register events to parallel clock 2 over master ...")
event!(clk, fun(incr!, a), 1.0, cid=2)
sleep(sleeptime)
@test length(c2.clock.sc.events) == 1
event!(clk, fun(incr!, b), fun(≥, fun(tau, c2), 5), cid=2)
sleep(sleeptime)
@test length(c2.clock.sc.cevents) == 1
periodic!(clk, fun(incr!, c), cid=2)
sleep(sleeptime)
@test length(c2.clock.sc.samples) == 1
process!(clk, Prc(1, pinc!, d), cid=2)
sleep(sleeptime)
@test length(c2.clock.processes) == 1

println("... 1st run parallel clock 2 (thread 2) ...")
# put!(clk.ac[1].forth, DiscreteEvents.Run(10.0))
# @test take!(clk.ac[1].back).t > 0
# sleep(sleeptime)
tns = [0]
t1 = time_ns()
iter = [0]
while (c2.clock.time+Δt) ≤ 10
    put!(clk.ac[1].forth, DiscreteEvents.Run(Δt, false))
    tns[1] += take!(clk.ac[1].back).t
    iter[1] += 1
end
t1 = time_ns() - t1
println("$iter ticks took $(Int(t1)*1e-9) s, clock time $(Int(tns[1])*1e-9) s")
@test c2.clock.time ≈ 10
@test c2.clock.scount == 1000
@test a[1] == 1
@test b[1] == 1
@test c[1] == 1000
@test d[1] >= 10

println("... parallel clock 2 reset ...")
put!(clk.ac[1].forth, DiscreteEvents.Reset(true))
@test take!(clk.ac[1].back).x == 1
@test c2.clock.time == 0
@test c2.clock.scount == 0
empty!(c2.clock.processes)

println("... register events to active clock 2 ...")
event!(c2, fun(incr!, a), 1.0)
sleep(sleeptime)
@test length(c2.clock.sc.events) == 1
event!(c2, fun(incr!, b), fun(≥, fun(tau, c2), 5))
sleep(sleeptime)
@test length(c2.clock.sc.cevents) == 1
periodic!(c2, fun(incr!, c))
sleep(sleeptime)
@test length(c2.clock.sc.samples) == 1

println("... 2nd run parallel clock 2 (thread 2) ...")
# put!(clk.ac[1].forth, DiscreteEvents.Run(10.0))
# @test take!(clk.ac[1].back).t > 0
# sleep(sleeptime)
tns = [0]
t1 = time_ns()
iter = [0]
while (c2.clock.time+Δt) ≤ 10
    put!(clk.ac[1].forth, DiscreteEvents.Run(Δt, false))
    tns[1] += take!(clk.ac[1].back).t
    iter[1] += 1
end
t1 = time_ns() - t1
println("$iter ticks took $(Int(t1)*1e-9) s, clock time $(Int(tns[1])*1e-9) s")
@test c2.clock.time ≈ 10
@test c2.clock.scount == 1000
@test a[1] == 2
@test b[1] == 2
@test c[1] == 2000

println("... parallel clock 2 reset ...")
put!(clk.ac[1].forth, DiscreteEvents.Reset(true))
@test take!(clk.ac[1].back).x == 1

println("... testing register(!) five cases ... ")
ev1 = DiscreteEvents.DiscreteEvent(fun(incr!, a), 1.0, 0.0, 1)
ev2 = DiscreteEvents.DiscreteEvent(fun(incr!, a), 2.0, 0.0, 1)
ev3 = DiscreteEvents.DiscreteEvent(fun(incr!, a), 3.0, 0.0, 1)
ev4 = DiscreteEvents.DiscreteEvent(fun(incr!, a), 4.0, 0.0, 1)
DiscreteEvents._register(clk, ev1, 1)              # 1. register ev1 to clk
@test DiscreteEvents._nextevent(clk) == ev1
DiscreteEvents._register(clk, ev1, 2)              # 2. register ev1 to 1st parallel clock
sleep(sleeptime)
@test DiscreteEvents._nextevent(c2.clock) == ev1
DiscreteEvents._register(c2, ev2, 2)               # 3. register ev2 directly to 1st parallel clock
sleep(sleeptime)
@test length(c2.clock.sc.events) == 2
DiscreteEvents._register(c2, ev2, 1)               # 4. register ev2 back to master
sleep(sleeptime)
@test length(clk.sc.events) == 2
DiscreteEvents._register(c2.clock, ev3, 1)
sleep(sleeptime)
@test length(clk.sc.events) == 3
clk.state = DiscreteEvents.Busy()  # mock busy master
DiscreteEvents._register(c2.clock, ev4, 1)
clk.state = DiscreteEvents.Idle()
@test take!(clk.ac[1].back).ev == ev4

if nthreads() > 2                           # This fails on CI (only 2 threads)
    DiscreteEvents._register(c2, ev2, 3)           # 5. register ev2 to another parallel clock
    c3 = pclock(clk, 3)
    sleep(sleeptime)
    @test DiscreteEvents._nextevent(c3.clock) == ev2
end

println("... testing API on multiple threads ...")

function clocks_ok(clk::Clock)
    ok = true
    for i in eachindex(clk.ac)
        while isready(clk.ac[i].back)
            token = take!(clk.ac[i].back)
            if token isa Error
                println("clock $i error: ", token.exc)
                ok = false
            end
        end
        if istaskfailed(clk.ac[i].ref[])
            println("clock $i error, stacktrace:")
            println(clk.ac[i].ref[])
            ok = false
        end
    end
    return ok
end

clock = Vector{Clock}()
push!(clock, clk)
for i in eachindex(clk.ac)
    put!(clk.ac[i].forth, DiscreteEvents.Query())
    push!(clock, take!(clk.ac[i].back).x.clock )
end
println("    got $(length(clock)) clocks")
@test sum(length(c.sc.events) for c in clock) ≥ 4
resetClock!(clk)                            # test resetClock! on multiple clocks
@test clk.Δt == Δt                          # must still be the same
@test sum(length(c.sc.events) for c in clock) == 0
println("    resetClock!     ok")

x = zeros(Int, nthreads())
event!(clk, ()->x[1]+=1, 1)
sleep(sleeptime); @test clocks_ok(clk)
event!(clk, ()->x[2]+=1, 1, cid=1)
sleep(sleeptime); @test clocks_ok(clk)
event!(c2,  ()->x[2]+=1, 2)
sleep(sleeptime); @test clocks_ok(clk)
event!(c2,  ()->x[1]+=1, 2, cid=2)
sleep(sleeptime); @test clocks_ok(clk)
if nthreads() > 2
    event!(c3,  ()->x[3]+=1, 1, cid=3)
    sleep(sleeptime); @test clocks_ok(clk)
end
sleep(sleeptime)
@test length(clk.sc.events) == 2
@test length(c2.clock.sc.events) == 2
nthreads() > 2 && @test length(c3.clock.sc.events) == 1
error = false
@test !error
println("    distributed events ok")
run!(clk, 3)
@test x[1] == 2
@test x[2] == 2
nthreads() > 2 && @test x[3] == 1
println("    first parallel run ok")

println("... collapse! ...")
@test_warn "only the master clock" collapse!(c2.clock)
ac = clk.ac
collapse!(clk)
@test all(x->istaskdone(x.ref[]), ac)
@test all(x->x.ch.state == :closed, ac)
