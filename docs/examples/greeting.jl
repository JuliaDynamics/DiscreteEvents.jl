using Sim, Printf

sim = Clock()
comm = ["Hi nice to meet you!", "How are you?", "Have a nice day!"]

greet(name, n) =  @printf("%5.2f s, %s: %s\n", now(sim), name, comm[n])

function foo(n)
    greet("Foo", n)
    event!(sim, :(bar($n)), after, 2*rand())
end

function bar(n)
    greet("Bar", n)
    if n < 3
        event!(sim, :(foo($n+1)), after, 2*rand())
    else
        println("bye bye")
    end
end

event!(sim, :(foo(1)), at, 10*rand())
run!(sim, 20)
