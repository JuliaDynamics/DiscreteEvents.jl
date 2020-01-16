#
# This file is part of the Simulate.jl Julia package, MIT license
#
# Paul Bayer, 2019
#
# This is a Julia package for discrete event simulation
#

println("... testing multithreading  ...")

clk = Clock()
@test clk.id == 1

if VERSION ≥ v"1.3"
    if nthreads() > 1
        println("... multiply!: ")
        multiply!(clk)
        @test length(clk.ac) == nthreads()-1
        for i in 2:nthreads()
            @test clk.ac[i-1].id == i
            c = pclock(clk, i)
            @test c.id == i
        end

        println("... register remote events, cevents, samples:")
        a = 0
        b = 0
        ev = Simulate.SimEvent(SF(()->global a+=1),Main,1.0,0.0)
        put!(clk.ac[1].ch, Simulate.Register(ev))
        @test take!(clk.ac[1].ch).x == 1.0
        c2 = pclock(clk, 2)
        @test length(c2.sc.events) == 1
        cev = Simulate.SimCond(SF((c)->tau(c)≥5, c2), SF(()->global a+=2), Main)
        put!(clk.ac[1].ch, Simulate.Register(cev))
        @test take!(clk.ac[1].ch).x == 0.0
        @test length(c2.sc.cevents) == 1
        sp = Simulate.Sample(SF(()->global b+=1), Main)
        put!(clk.ac[1].ch, Simulate.Register(sp))
        @test take!(clk.ac[1].ch).x == true
        @test length(c2.sc.sexpr) == 1

        println("... stop remote clocks")
        foreach(x->put!(x.ch, Simulate.Stop()), clk.ac)
        @test all(x->istaskdone(x.ref[]), clk.ac)
        @test all(x->x.ch.state == :closed, clk.ac)
    else
        @test_warn "no parallel threads available!" multiply!(clk)
    end
else
    @test_warn "threading is available for ≥ 1.3!" multiply!(clk)
end
