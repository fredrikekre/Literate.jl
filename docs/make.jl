using Documenter
using Literate

# generate examples
EXAMPLE = joinpath(@__DIR__, "..", "examples", "example.jl")
OUTPUT = joinpath(@__DIR__, "src/generated")

function preprocess(str)
    str = replace(str, "MYVARIABLE" => "z")
    str = replace(str, "MYVALUE" => "1.0 + 2.0im")
    return str
end

Literate.markdown(EXAMPLE, OUTPUT, preprocess = preprocess)
Literate.notebook(EXAMPLE, OUTPUT, preprocess = preprocess)
Literate.script(EXAMPLE, OUTPUT, preprocess = preprocess)

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
    julia = "0.6",
    deps = nothing,
    make = nothing
)
