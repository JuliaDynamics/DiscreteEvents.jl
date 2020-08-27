println(".... run examples and notebooks ....")

using NBInclude

function redirect_devnull(f)
    open(@static(Sys.iswindows() ? "nul" : "/dev/null"), "w") do io
        redirect_stdout(io) do
            f()
        end
    end
end

const ex_dir = "../examples/"
const nb_dir = "../examples/"
# trash = open(@static(Sys.iswindows() ? "nul" : "/dev/null"), "w")

dir = pwd()
cd(@__DIR__)


ex = [x for x in readdir(ex_dir) if occursin(r".jl", x)]
nb = [x for x in readdir(nb_dir) if occursin(r".ipynb", x)]

for x in ex
    print("... include $ex_dir$x (output suppressed) ")
    nam = string(rsplit(x, ".", limit=2)[1])
    mod = gensym(nam)
    expr = :(begin include($ex_dir*$x) end)
    redirect_devnull() do
        @eval module $mod
            using Test
            @testset $nam $expr
        end 
    end
    println(" ok ...")
end

for x in nb
    print("... @nbinclude $nb_dir$x (output suppressed) ")
    nam = string(rsplit(x, ".", limit=2)[1])
    mod = gensym(nam)
    expr = :(begin @nbinclude($nb_dir*$x) end)
    redirect_devnull() do
        @eval module $mod
            using Test, NBInclude
            @testset $nam $expr
        end 
    end
    println(" ok ...")
end

cd(dir)
