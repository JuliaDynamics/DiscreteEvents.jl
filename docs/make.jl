using Documenter, Simulate

makedocs(
    modules = [Simulate],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "Simulate.jl",
    authors  = "Paul Bayer",
    pages = [
        "Home" => "index.md",
        "Approaches" => "approach.md",
        "Overview" => "overview.md",
        "Usage" => "usage.md",
        "Examples" => [
            "Two guys meet" => "examples/greeting.md",
            "Table tennis" => "examples/tabletennis.md",
            "Single server" => "examples/singleserver.md",
            "Further examples" => "examples/examples.md"
        ],
        "Internals" => "internals.md"
    ]
)

deploydocs(
    repo   = "github.com/pbayer/Simulate.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing
)
