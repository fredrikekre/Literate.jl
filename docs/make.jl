using Documenter
using Literate

# generate examples
EXAMPLE = joinpath(@__DIR__, "..", "examples", "example.jl")
OUTPUT = joinpath(@__DIR__, "src/generated")

Literate.markdown(EXAMPLE, OUTPUT)
Literate.notebook(EXAMPLE, OUTPUT)
Literate.script(EXAMPLE, OUTPUT)

makedocs(
    modules = [Literate],
    format = :html,
    sitename = "Literate.jl",
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
    repo = "github.com/fredrikekre/Literate.jl.git",
    target = "build",
    deps = nothing,
    make = nothing
)
