using Documenter
using Literate
using Plots # to not capture precompilation output

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

# generate the example notebook for the documentation, keep in sync with outputformats.md
Literate.markdown(joinpath(@__DIR__, "src/outputformats.jl"), OUTPUT; credit = false, name = "name")
Literate.notebook(joinpath(@__DIR__, "src/outputformats.jl"), OUTPUT, name = "notebook")
Literate.script(joinpath(@__DIR__, "src/outputformats.jl"), OUTPUT, credit = false)

# replace the link in outputformats.md
travis_tag = get(ENV, "TRAVIS_TAG", "")
folder = isempty(travis_tag) ? "latest" : travis_tag
url = "https://nbviewer.jupyter.org/github/fredrikekre/Literate.jl/blob/gh-pages/$(folder)/"
if get(ENV, "HAS_JOSH_K_SEAL_OF_APPROVAL", "") == "true"
    str = read(joinpath(@__DIR__, "src/outputformats.md"), String)
    str = replace(str, "[notebook.ipynb](generated/notebook.ipynb)." => "[notebook.ipynb]($(url)generated/notebook.ipynb).")
    write(joinpath(@__DIR__, "src/outputformats.md"), str)
end


makedocs(
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        assets = ["assets/custom.css"],

    ),
    modules = [Literate],
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
)
