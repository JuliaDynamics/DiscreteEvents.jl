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
            "manual/intro.md",
            "manual/approach.md",
            "manual/usage.md"],
        "Performance" => [
            "performance/performance.md",
            "performance/parallel.md",
            "performance/benchmarks.md"],
        "Examples" => [
            "examples/examples.md",
            "examples/tabletennis.md",
            "examples/singleserver.md",
            "examples/postoffice/postoffice.md",
            "examples/dicegame/dicegame.md",
            "examples/house_heating/house_heating.md"],
        "Internals" => "manual/internals.md",
        "Troubleshooting" => "manual/troubleshooting.md",
        "Release notes" => "manual/history.md"
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
