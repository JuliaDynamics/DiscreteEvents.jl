#
# This file is part of the DiscreteEvents.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#
using DiscreteEvents, Random, Distributions

println("... basic tests: processes ...")
simex = DiscreteEvents.PrcException(DiscreteEvents.Stop(), nothing)
@test simex.event == DiscreteEvents.Stop()
@test simex.value === nothing

# ===== test process registration
ch1 = Channel(32)
ch2 = Channel(32)

resetClock!(𝐶)
incr(𝐶, c1::Channel, c2::Channel, a) = (a+1, yield())
a = [1,1,3.0,3.0,"A","A","A","A"]
b = [1,2,3.0,nextfloat(3.0),"A","A#1","A#2","A#3"]
for i in 1:8
    @test process!(Prc(a[i], incr, ch1, ch2, 1)) == b[i]
end
for i in 1:8
    @test 𝐶.processes[b[i]].id == b[i]
end
@test process!(Prc((1,2), incr, ch1, ch2, 1)) == (1,2)
@test process!(Prc((1,2), incr, ch1, ch2, 1)).state === :failed # Julia 1.0

println("... test channel 4 example ...")
A = []

function simple(c::Clock, input::Channel, output::Channel, name, id, op)
    token = take!(input)         # take something from the input
    push!(A, (tau(c), name, id, token))
    delay!(c, 0.5)           # after a delay
    put!(output, op(token, id))  # put it out with some op applied
end

resetClock!(𝐶)
Random.seed!(123)

for i in 1:2:8    # create, register and start 8 SimProcesses Prc
    process!(Prc(i, simple, ch1, ch2, "foo", i, +))
    process!(Prc(i+1, simple, ch2, ch1, "bar", i+1, *))
end

@test length(𝐶.processes) == 8
for p in values(𝐶.processes)
    @test istaskstarted(p.task)
end

put!(ch1, 1)
sleep(0.01)
run!(𝐶, 10)

@test length(A) > 20
p = [i[3] for i in A]
for i in 1:8
    @test i ∈ p  # all processes did something
end

println("... test errors and stop ...")
schedule(𝐶.processes[8].task, ErrorException, error=true)
sleep(0.1)
@test 𝐶.processes[8].task.state == :failed
delete!(𝐶.processes, 8)

for p in values(𝐶.processes)
    @test istaskstarted(p.task)
    DiscreteEvents.stop!(p, DiscreteEvents.Stop())
    @test istaskdone(p.task)
end

println("... test wait! ...")

ch1 = Channel(1)
ch2 = Channel(1)

a = 1
b = 1
res = []
incb() = global b +=1
checktime(clk, x) = tau(clk) ≥ x
checka(x) = a == x
checkb(x) = b ≥ x

function testwait(clk::Clock, c1::Channel, c2::Channel)
    wait!(clk, (fun(checktime, clk, 2), fun(checka, 1)))
    push!(res, (tau(clk), 1, a, b))
    wait!(clk, fun(isa, a, Int)) # must return immediately
    push!(res, (tau(clk), 2, a, b))
    periodic!(clk, fun(incb))
    wait!(clk, fun(checkb, 201))
    push!(res, (tau(clk), 3, a, b))
    take!(c1)
end

resetClock!(𝐶)
process!(Prc(1, testwait, ch1, ch2))

run!(𝐶, 10)
r = [i[1] for i in res]
@test r[1] ≈ 2
@test r[2] ≈ 2
@test r[3] ≈ 4
@test res[3][4] == 201
@test b == 801

a = [1]
function testdelay(clk::Clock, x)
    delay!(clk, at, 2)     # assertion error bad timing
    x[1] += 10
end

function testdelay2(clk::Clock, x)
    delay!(clk, until, 5)
    x[1] += 1
end

function testdelay3(clk::Clock, x)
    delay!(clk, until, Normal(5,1))
    x[1] += 1
end

resetClock!(𝐶)
process!(Prc(1, testdelay, a), 3)
process!(Prc(2, testdelay2, a), 3)
process!(Prc(3, testdelay3, a), 3)
run!(𝐶, 10)

@test 𝐶.processes[1].task.state == :failed
@test a[1] == 7

function testnow(c, x)
    delay!(c, 1); 
    x[1] += 1; 
    println(c, "$(tau(c)): ", "x is $(x[1])")
end

resetClock!(𝐶)
process!(Prc(1, testnow, a), 3)
run!(𝐶, 5)
@test a[1] == 10
