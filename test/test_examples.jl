println(".... run examples and notebooks ....")

using NBInclude

const ex_dir = "../examples/src/"
const nb_dir = "../examples/nb/"

dir = pwd()
cd(@__DIR__)


ex = [x for x in readdir(ex_dir) if occursin(r".jl", x)]
nb = [x for x in readdir(nb_dir) if occursin(r".ipynb", x)]

for x in ex
    println("... include $ex_dir$x:")
    include(ex_dir*x)
end

for x in nb
    println("... @nbinclude $nb_dir$x:")
    @nbinclude(nb_dir*x)
end

cd(dir)
