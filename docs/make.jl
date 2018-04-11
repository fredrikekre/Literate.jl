using Documenter
using Examples

# generate examples
EXAMPLE = joinpath(@__DIR__, "..", "examples", "example.jl")
OUTPUT = joinpath(@__DIR__, "src/generated")

Examples.markdown(EXAMPLE, OUTPUT; documenter = true)
Examples.notebook(EXAMPLE, OUTPUT; documenter = true)
Examples.script(EXAMPLE, OUTPUT; documenter = true)

makedocs(
    modules = [Examples],
    format = :html,
    sitename = "Examples.jl",
    pages = Any[
        "index.md",
        "fileformat.md",
        "pipeline.md",
        "outputformats.md",
        "customprocessing.md",
        "documenter.md",
        "generated/example.md"]
)

deploydocs(
    repo = "github.com/fredrikekre/Examples.jl.git",
    target = "build",
    deps = nothing,
    make = nothing
)
