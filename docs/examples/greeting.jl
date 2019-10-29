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
    num
    from
end

comm = ("Nice to meet you!", "How are you?", "Have a nice day!", "bye bye")
say(name, n) =  @printf("%5.2f s, %s: %s\n", τ(), name, comm[n])

function step!(me::Guy, σ::Meet)
    event!(Τ, SimFunction(step!, σ.someone, Greet(1, me)), after, 2*rand())
    say(me.name, 1)
end

function step!(me::Guy, σ::Greet)
    if σ.num < 3
        event!(Τ, SimFunction(step!, σ.from, Response(σ.num, me)), after, 2*rand())
        say(me.name, σ.num)
    else
        say(me.name, 4)
    end
end

function step!(me::Guy, σ::Response)
    event!(Τ, SimFunction(step!, σ.from, Greet(σ.num+1, me)), after, 2*rand())
    say(me.name, σ.num+1)
end

foo = Guy("Foo")
bar = Guy("Bar")

event!(Τ, SimFunction(step!, foo, Meet(bar)), at, 10*rand())
run!(Τ, 20)
