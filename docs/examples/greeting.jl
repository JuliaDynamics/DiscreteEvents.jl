using Sim, Printf

struct Guy
    name
end

abstract type Encounter end
struct Meet <: Encounter
    someone
end
struct Greet <: Encounter
    num
    from
end
struct Response <: Encounter

    from
end

comm = ("Nice to meet you!", "How are you?", "Have a nice day!", "bye bye")
sim = Clock()

say(name, n) =  @printf("%5.2f s, %s: %s\n", now(sim), name, comm[n])

function step!(me::Guy, σ::Meet)
    event!(sim, SimFunction(step!, σ.someone, Greet(1, me)), after, 2*rand())
    say(me.name, 1)
end

function step!(me::Guy, σ::Greet)
    if σ. < 3
        event!(sim, SimFunction(step!, σ.from, Response(σ., me)), after, 2*rand())
        say(me.name, σ.)
    else
        say(me.name, 4)
    end
end

function step!(me::Guy, σ::Response)
    event!(sim, SimFunction(step!, σ.from, Greet(σ.+1, me)), after, 2*rand())
    say(me.name, σ.+1)
end

foo = Guy("Foo")
bar = Guy("Bar")

event!(sim, SimFunction(step!, foo, Meet(bar)), at, 10*rand())
run!(sim, 20)
