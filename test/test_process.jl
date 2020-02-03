#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

println("... basic tests: processes ...")
simex = Simulate.ClockException(Simulate.Stop())
@test simex.ev == Simulate.Stop()
@test simex.value === nothing

# ===== test process registration
ch1 = Channel(32)
ch2 = Channel(32)

reset!(𝐶)
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
@test_throws ArgumentError process!(Prc((1,2), incr, ch1, ch2, 1))

println("... test channel 4 example ...")
A = []

function simple(c::Clock, input::Channel, output::Channel, name, id, op)
    token = take!(input)         # take something from the input
    push!(A, (tau(c), name, id, token))
    d = delay!(c, rand())           # after a delay
    put!(output, op(token, id))  # put it out with some op applied
end

reset!(𝐶)
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
    stop!(p, Simulate.Stop())
    @test istaskdone(p.task)
end

println("... test wait! ...")

ch1 = Channel(1)
ch2 = Channel(1)

a = 1
b = 1
res = []
incb() = global b +=1
checktime(x) = tau() ≥ x
checka(x) = a == x
checkb(x) = b ≥ x

function testwait(clk::Clock, c1::Channel, c2::Channel)
    wait!(clk, (Fun(checktime, 2), Fun(checka, 1)))
    push!(res, (tau(), 1, a, b))
    wait!(clk, Fun(isa, a, Int)) # must return immediately
    push!(res, (tau(), 2, a, b))
    periodic!(clk, Fun(incb))
    wait!(clk, Fun(checkb, 201))
    push!(res, (tau(), 3, a, b))
    take!(c1)
end

reset!(𝐶)
process!(Prc(1, testwait, ch1, ch2))

run!(𝐶, 10)
r = [i[1] for i in res]
@test r[1] ≈ 2
@test r[2] ≈ 2
@test r[3] ≈ 4
@test res[3][4] == 201
@test b == 801

a = 1
function testdelay(clk::Clock)
    delay!(clk, at, 2)
    global a += 10
end

function testdelay2(clk::Clock)
    delay!(clk, until, 5)
    global a += 1
end

reset!(𝐶)
process!(Prc(1, testdelay), 3)
process!(Prc(2, testdelay2), 3)
run!(𝐶, 10)

@test 𝐶.processes[1].task.state == :failed
@test a == 4

testnow(c) = (delay!(c, 1); global a += 1; now!(c, Fun(println, "$(tau(c)): a is $a")))
reset!(𝐶)
process!(Prc(1, testnow), 3)
run!(𝐶, 5)
@test a == 7
