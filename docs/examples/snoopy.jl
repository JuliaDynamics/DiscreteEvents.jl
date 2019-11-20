using Simulate, Printf, Random

function watchdog(name)
    delay!(until, 6 + rand())
    now!(SF(println, @sprintf("%5.2f %s: yawn!, bark!, yawn!", tau(), name)))
    wait!(((@val :hunger :≥ 7),(@tau :≥ 6.5)))
    while 5 ≤ hunger ≤ 10
        now!(SF(println, @sprintf("%5.2f %s: %s", tau(), name, repeat("wow ", Int(trunc(hunger))))))
        delay!(rand()/2)
        if scuff
            now!(SF(println, @sprintf("%5.2f %s: smack smack smack", tau(), name)))
            global hunger = 2
            global scuff = false
        end
    end
    delay!(rand())
    now!(SF(println, @sprintf("%5.2f %s: snore ... snore ... snore", tau(), name)))
end

hunger = 0
scuff = false
reset!(𝐶)
Random.seed!(1122)

sample!(SF(()-> global hunger += rand()), 0.5)
event!(SF(()-> global scuff = true ), 7+rand())
process!(SP(1, watchdog, "Snoopy"), 1)

run!(𝐶, 10)
