using Documenter, Simulate

makedocs(
    modules = [Simulate],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "Simulate.jl",
    authors  = "Paul Bayer",
    pages = [
        "Home" => "index.md",
        "News" => "news.md",
        "Manual" => [
            "intro.md",
            "usage.md",
            "troubleshooting.md",
            "history.md"]
    ]
)

deploydocs(
    repo   = "github.com/pbayer/Simulate.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
    devbranch = "master",
    devurl = "dev",
    versions = ["stable" => "v^", "v#.#", "dev" => "dev"]
)
