using Documenter, Sim
push!(LOAD_PATH,"../src/")

makedocs(
    modules = [Sim],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "Sim.jl",
    authors  = "Paul Bayer",
    pages = [
        "Home" => "index.md",
        "Overview" => "overview.md",
        "Usage" => "usage.md",
        "Examples" => "examples.md",
    ]
)

deploydocs(
    repo   = "github.com/pbayer/Sim.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing
)
