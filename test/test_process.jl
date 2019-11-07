function foo(in::Channel, out::Channel, id)
    token = take!(in)
    println("$(τ()): foo $id took $token")
    d = delay!(rand())
    println("$(τ()): foo $id woke up after delay of $d")
    put!(out, token+id)
end

function bar(in::Channel, out::Channel, id)
    token = take!(in)
    println("$(τ()): bar $id took $token")
    d = delay!(rand())
    println("$(τ()): bar $id woke up after delay of $d")
    put!(out, token*id)
end

ch1 = Channel(32)
ch2 = Channel(32)

reset!(𝐶)
for i in 1:2:8
    process!(𝐶, SimProcess(i, foo, ch1, ch2, i))
    process!(𝐶, SimProcess(i+1, bar, ch2, ch1, i+1))
end

@test length(𝐶.processes) == 8

start!(𝐶)
for p in values(𝐶.processes)
    @test p.state == Simulate.Idle()
end

put!(ch1, 1)

run!(𝐶, 10)
