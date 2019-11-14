using Simulate, Random

ch1 = Channel(1)
ch2 = Channel(1)

a = 1
b = 1
res = []
incb() = global b +=1
checktime(x) = τ() ≥ x
checka(x) = a == x
checkb(x) = b ≥ x

function testwait(c1::Channel, c2::Channel)
    wait!((𝐅(checktime, 2), 𝐅(checka, 1)))
    push!(res, (τ(), 1, a, b))
    wait!(𝐅(isa, a, Int64)) # must return immediately
    push!(res, (τ(), 2, a, b))
    sample!(𝐅(incb))
#    event!(𝐅(incb), every, 0.1)
    wait!(𝐅(checkb, 201))
    push!(res, (τ(), 3, a, b))
    take!(c1)
end

reset!(𝐶)
process!(𝐏(1, testwait, ch1, ch2))
start!(𝐶)

sleep(0.01)

println(run!(𝐶, 10))
res
