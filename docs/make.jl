using Documenter

if haskey(ENV, "GITHUB_ACTIONS")
    ENV["JULIA_DEBUG"] = "Documenter"
end

deployconfig = Documenter.auto_detect_deploy_system()
Documenter.post_status(deployconfig; type="pending", repo="github.com/fredrikekre/Literate.jl.git")
using Literate
using Plots # to not capture precompilation output

# generate examples
EXAMPLE = joinpath(@__DIR__, "..", "examples", "example.jl")
OUTPUT = joinpath(@__DIR__, "src/generated")

function preprocess(str)
    str = replace(str, "x = 123" => "y = 321"; count=1)
    return str
end

Literate.markdown(EXAMPLE, OUTPUT, preprocess = preprocess)
Literate.notebook(EXAMPLE, OUTPUT, preprocess = preprocess)
Literate.script(EXAMPLE, OUTPUT, preprocess = preprocess)

# generate the example notebook for the documentation, keep in sync with outputformats.md
Literate.markdown(joinpath(@__DIR__, "src/outputformats.jl"), OUTPUT; credit = false, name = "name")
Literate.notebook(joinpath(@__DIR__, "src/outputformats.jl"), OUTPUT; name = "notebook")
Literate.script(joinpath(@__DIR__, "src/outputformats.jl"), OUTPUT; credit = false)

# Replace the link in outputformats.md
# since that page is not "literated"
if haskey(ENV, "GITHUB_ACTIONS")
    folder = Base.CoreLogging.with_logger(Base.CoreLogging.NullLogger()) do
        Documenter.deploy_folder(
            deployconfig;
            repo = "github.com/fredrikekre/Literate.jl.git",
            devbranch = "master",
            push_preview = true,
            devurl = "dev",
        ).subfolder
    end
    url = "https://nbviewer.jupyter.org/github/fredrikekre/Literate.jl/blob/gh-pages/$(folder)/"
    str = read(joinpath(@__DIR__, "src/outputformats.md"), String)
    str = replace(str, "[notebook.ipynb](generated/notebook.ipynb)." => "[notebook.ipynb]($(url)generated/notebook.ipynb).")
    write(joinpath(@__DIR__, "src/outputformats.md"), str)
end

makedocs(
    format = Documenter.HTML(
        assets = ["assets/custom.css", "assets/favicon.ico"],
        prettyurls = true, # haskey(ENV, "GITHUB_ACTIONS"),
        canonical = "https://fredrikekre.github.io/Literate.jl/v2",
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
        "tips.md",
        "generated/example.md"]
)

deploydocs(
    repo = "github.com/fredrikekre/Literate.jl.git",
    push_preview = true,
    versions = ["v2" => "v^", "v#.#", "dev" => "dev"],
    deploy_config = deployconfig,
)
