"""
    Literate

Julia package for Literate Programming. See
https://fredrikekre.github.io/Literate.jl/ for documentation.
"""
module Literate

import JSON, REPL

include("IJulia.jl")
import .IJulia
include("Documenter.jl")
import .Documenter

# # Some simple rules:
#
# * All lines starting with `# ` are considered markdown, everything else is considered code
# * The file is parsed in "chunks" of code and markdown. A new chunk is created when the
#   lines switch context from markdown to code and vice versa.
# * Lines starting with `#-` can be used to start a new chunk.
# * Lines starting with `#md` are filtered out unless creating a markdown file
# * Lines starting with `#nb` are filtered out unless creating a notebook
# * Lines starting with, or ending with, `#jl` are filtered out unless creating a script file
# * Lines starting with, or ending with, `#src` are filtered out unconditionally
# * Whitespace within a chunk is preserved
# * Empty chunks are removed, leading and trailing empty lines in a chunk are also removed

# Parser
abstract type Chunk end
struct MDChunk <: Chunk
    lines::Vector{Pair{String,String}} # indent and content
end
MDChunk() = MDChunk(String[])
mutable struct CodeChunk <: Chunk
    lines::Vector{String}
    continued::Bool
end
CodeChunk() = CodeChunk(String[], false)

ismdline(line) = (occursin(r"^\h*#$", line) || occursin(r"^\h*# .*$", line)) && !occursin(r"^\h*##", line)

function parse(content; allow_continued = true)
    lines = collect(eachline(IOBuffer(content)))

    chunks = Chunk[]
    push!(chunks, ismdline(rstrip(lines[1])) ? MDChunk() : CodeChunk())

    for line in lines
        line = rstrip(line)
        if occursin(r"^\h*#-", line) # new chunk
            # assume same as last chunk, will be cleaned up otherwise
            push!(chunks, typeof(chunks[end])())
        elseif occursin(r"^\h*#\+", line) # new code chunk, that continues the previous one
            idx = findlast(x -> isa(x, CodeChunk), chunks)
            if idx !== nothing
                chunks[idx].continued = true
            end
            push!(chunks, CodeChunk())
        elseif ismdline(line) # markdown
            if !(chunks[end] isa MDChunk)
                push!(chunks, MDChunk())
            end
            # capture what is before and after # (need to store the indent)
            m = match(r"^(\h*)#( (.*))?$", line)
            indent = convert(String, m.captures[1])
            linecontent = m.captures[3] === nothing ? "" : convert(String, m.captures[3])
            push!(chunks[end].lines, indent => linecontent)
        else # code
            if !(chunks[end] isa CodeChunk)
                push!(chunks, CodeChunk())
            end
            # remove "## " and "##\n"
            line = replace(replace(line, r"^(\h*)#(# .*)$" => s"\1\2"), r"^(\h*#)#$" => s"\1")
            push!(chunks[end].lines, line)
        end
    end

    # clean up the chunks
    ## remove empty chunks
    filter!(x -> !isempty(x.lines), chunks)
    filter!(x -> !all(y -> isempty(y) || isempty(last(y)), x.lines), chunks)
    ## remove leading/trailing empty lines
    for chunk in chunks
        while isempty(chunk.lines[1]) || isempty(last(chunk.lines[1]))
            popfirst!(chunk.lines)
        end
        while isempty(chunk.lines[end]) || isempty(last(chunk.lines[end]))
            pop!(chunk.lines)
        end
    end

    # if we don't allow continued code blocks we need to merge MDChunks into the CodeChunks
    if !allow_continued
        merged_chunks = Chunk[]
        continued = false
        for chunk in chunks
            if continued
                @assert !isempty(merged_chunks)
                if isa(chunk, CodeChunk)
                    append!(merged_chunks[end].lines, chunk.lines)
                else # need to put back "#"
                    for line in chunk.lines
                        push!(merged_chunks[end].lines, rstrip(line.first * "# " * line.second))
                    end
                end
            else
                push!(merged_chunks, chunk)
            end
            if isa(chunk, CodeChunk)
                continued = chunk.continued
            end
        end
        chunks = merged_chunks
    end

    return chunks
end

function replace_default(content, sym;
                         config::Dict,
                         branch = "gh-pages",
                         commit = "master"
                         )
    repls = Pair{Any,Any}[]

    # add some shameless advertisement
    if config["credit"]::Bool
        if sym === :jl
            content *= """

                #-
                ## This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
                """
        else
            content *= """

                #-
                # *This $(sym === :md ? "page" : "notebook") was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*
                """
        end
    end

    push!(repls, "\r\n" => "\n") # normalize line endings

    # unconditionally remove #src lines
    push!(repls, r"^#src.*\n?"m => "")
    push!(repls, r".*#src$\n?"m => "")

    if sym === :md
        push!(repls, r"^#md "m => "")      # remove leading #md
        push!(repls, r"^#!md.*\n?"m => "") # remove leading #!md lines
        push!(repls, r"^#nb.*\n?"m => "")  # remove #nb lines
        push!(repls, r"^#!nb "m => "")     # remove leading #!nb
        push!(repls, r"^#jl.*\n?"m => "")  # remove leading #jl lines
        push!(repls, r"^#!jl "m => "")     # remove leading #!jl
    elseif sym === :nb
        push!(repls, r"^#md.*\n?"m => "")  # remove #md lines
        push!(repls, r"^#!md "m => "")     # remove leading #!md
        push!(repls, r"^#nb "m => "")      # remove leading #nb
        push!(repls, r"^#!nb.*\n?"m => "") # remove #!nb lines
        push!(repls, r"^#jl.*\n?"m => "")  # remove leading #jl lines
        push!(repls, r"^#!jl "m => "")     # remove leading #!jl
        push!(repls, r"```math(.*?)```"s => s"$$\1$$")
    else # sym === :jl
        push!(repls, r"^#md.*\n?"m => "")  # remove #md lines
        push!(repls, r"^#!md "m => "")     # remove leading #!md
        push!(repls, r"^#nb.*\n?"m => "")  # remove #nb lines
        push!(repls, r"^#!nb "m => "")     # remove leading #!nb
        push!(repls, r"^#jl "m => "")      # remove leading #jl
        push!(repls, r"^#!jl.*\n?"m => "") # remove #!jl lines
    end

    # name
    push!(repls, "@__NAME__" => config["name"]::String)

    # fix links

    if get(ENV, "DOCUMENTATIONGENERATOR", "") == "true"
        ## DocumentationGenerator.jl
        base_url = get(ENV, "DOCUMENTATIONGENERATOR_BASE_URL", "DOCUMENTATIONGENERATOR_BASE_URL")
        nbviewer_root_url = "https://nbviewer.jupyter.org/urls/$(base_url)"
        push!(repls, "@__NBVIEWER_ROOT_URL__" => nbviewer_root_url)
    else
        push!(repls, "@__REPO_ROOT_URL__" => get(config, "repo_root_url", "<unknown>"))
        push!(repls, "@__NBVIEWER_ROOT_URL__" => get(config, "nbviewer_root_url", "<unknown>"))
        push!(repls, "@__BINDER_ROOT_URL__" => get(config, "binder_root_url", "<unknown>"))
    end

    # run some Documenter specific things
    if config["documenter"]::Bool && sym !== :md
        ## - remove documenter style `@ref`s and `@id`s
        push!(repls, r"\[(.*?)\]\(@ref\)" => s"\1")     # [foo](@ref) => foo
        push!(repls, r"\[(.*?)\]\(@ref .*?\)" => s"\1") # [foo](@ref bar) => foo
        push!(repls, r"\[(.*?)\]\(@id .*?\)" => s"\1")  # [foo](@id bar) => foo
    end

    # do the replacements
    for repl in repls
        content = replace(content, repl)
    end

    return content
end

filename(str) = first(splitext(last(splitdir(str))))

function create_configuration(inputfile; user_config, user_kwargs)
    # Combine user config with user kwargs
    user_config = Dict{String,Any}(string(k) => v for (k, v) in user_config)
    user_kwargs = Dict{String,Any}(string(k) => v for (k, v) in user_kwargs)
    user_config = merge!(user_config, user_kwargs)

    # Add default config
    cfg = Dict{String,Any}()
    cfg["name"] = filename(inputfile)
    cfg["preprocess"] = identity
    cfg["postprocess"] = identity
    cfg["documenter"] = true
    cfg["credit"] = true
    cfg["keep_comments"] = false
    cfg["codefence"] = get(user_config, "documenter", true) ?
        ("```@example $(get(user_config, "name", cfg["name"]))" => "```") : ("```julia" => "```")
    cfg["execute"] = true
    # Guess the package (or repository) root url
    edit_commit = "master" # TODO: Make this configurable like Documenter?
    deploy_branch = "gh-pages" # TODO: Make this configurable like Documenter?
    if haskey(ENV, "HAS_JOSH_K_SEAL_OF_APPROVAL") # Travis CI
        repo_slug = get(ENV, "TRAVIS_REPO_SLUG", "unknown-repository")
        deploy_folder = if get(ENV, "TRAVIS_PULL_REQUEST", nothing) == "false"
            get(ENV, "TRAVIS_TAG", get(user_config, "devurl", "dev"))
        else
            "previews/PR$(get(ENV, "TRAVIS_PULL_REQUEST", "##"))"
        end
        cfg["repo_root_url"] = "https://github.com/$(repo_slug)/blob/$(edit_commit)"
        cfg["nbviewer_root_url"] = "https://nbviewer.jupyter.org/github/$(repo_slug)/blob/$(deploy_branch)/$(deploy_folder)"
        cfg["binder_root_url"] = "https://mybinder.org/v2/gh/$(repo_slug)/$(deploy_branch)?filepath=$(deploy_folder)"
        if (dir = get(ENV, "TRAVIS_BUILD_DIR", nothing)) !== nothing
            cfg["repo_root_path"] = dir
        end
    elseif haskey(ENV, "GITHUB_ACTIONS")
        repo_slug = get(ENV, "GITHUB_REPOSITORY", "unknown-repository")
        deploy_folder = if get(ENV, "GITHUB_EVENT_NAME", nothing) == "push"
            if (m = match(r"^refs\/tags\/(.*)$", get(ENV, "GITHUB_REF", ""))) !== nothing
                String(m.captures[1])
            else
                get(user_config, "devurl", "dev")
            end
        elseif (m = match(r"refs\/pull\/(\d+)\/merge", get(ENV, "GITHUB_REF", ""))) !== nothing
            "previews/PR$(m.captures[1])"
        else
            "dev"
        end
        cfg["repo_root_url"] = "https://github.com/$(repo_slug)/blob/$(edit_commit)"
        cfg["nbviewer_root_url"] = "https://nbviewer.jupyter.org/github/$(repo_slug)/blob/$(deploy_branch)/$(deploy_folder)"
        cfg["binder_root_url"] = "https://mybinder.org/v2/gh/$(repo_slug)/$(deploy_branch)?filepath=$(deploy_folder)"
        if (dir = get(ENV, "GITHUB_WORKSPACE", nothing)) !== nothing
            cfg["repo_root_path"] = dir
        end
    elseif haskey(ENV, "GITLAB_CI")
        if (url = get(ENV, "CI_PROJECT_URL", nothing)) !== nothing
            cfg["repo_root_url"] = "$(url)/blob/$(edit_commit)"
        end
        if (url = get(ENV, "CI_PAGES_URL", nothing)) !== nothing &&
           (m = match(r"https://(.+)", url)) !== nothing
            cfg["nbviewer_root_url"] = "https://nbviewer.jupyter.org/urls/$(m[1])"
        end
        if (dir = get(ENV, "CI_PROJECT_DIR", nothing)) !== nothing
            cfg["repo_root_path"] = dir
        end
    end

    # Merge default_config with user_config
    merge!(cfg, user_config)
    return cfg
end

"""
    DEFAULT_CONFIGURATION

Default configuration for [`Literate.markdown`](@ref), [`Literate.notebook`](@ref) and
[`Literate.script`] which is used for everything not specified by the user.
See the manual section about [Configuration](@ref) for more information.

| Configuration key | Description | Default value | Comment |
| ----------------- |:----------- |:------------- |:------- |
| `name` | Name of the output file (excluding file extension). | `filename(inputfile)` |   |
| `preprocess` | Custom preprocessing function mapping `String` to `String`. | `identity` | See [Custom pre- and post-processing](@ref Custom-pre-and-post-processing). |
| `postprocess` | Custom preprocessing function mapping `String` to `String`. | `identity` | See [Custom pre- and post-processing](@ref Custom-pre-and-post-processing). |
| `documenter` | Boolean signaling that the source contains Documenter.jl elements. | `true` | See [Interaction with Documenter](@ref Interaction-with-Documenter). |
| `credit` | Boolean for controlling the addition of `This file was generated with Literate.jl ...` to the bottom of the page. If you find Literate.jl useful then feel free to keep this. | `true` |    |
| `keep_comments` | When `true`, keeps markdown lines as comments in the output script. | `false` | Only applicable for `Literate.script`. |
| `codefence` | Pair containing opening and closing fence for wrapping code blocks. | `````"```julia" => "```"````` | If `documenter` is `true` the default is `````"```@example"=>"```"`````. |
| `execute` | Whether to execute and capture the output. | `true` | Only applicable for `Literate.notebook`. |
| `devurl` | URL for "in-development" docs. | `"dev"` | See [Documenter docs](https://juliadocs.github.io/Documenter.jl/). Unused if `repo_root_url`/`nbviewer_root_url`/`binder_root_url` are set. |
| `repo_root_url` | URL to the root of the repository. | - | Determined automatically on Travis CI, GitHub Actions and GitLab CI. Used for `@__REPO_ROOT_URL__`. |
| `nbviewer_root_url` | URL to the root of the repository as seen on nbviewer. | - | Determined automatically on Travis CI, GitHub Actions and GitLab CI. Used for `@__NBVIEWER_ROOT_URL__`. |
| `binder_root_url` | URL to the root of the repository as seen on mybinder. | - | Determined automatically on Travis CI, GitHub Actions and GitLab CI. Used for `@__BINDER_ROOT_URL__`. |
| `repo_root_path` | Filepath to the root of the repository. | - | Determined automatically on Travis CI, GitHub Actions and GitLab CI. Used for computing [Documenters `EditURL`](@ref Interaction-with-Documenter). |
"""
const DEFAULT_CONFIGURATION=nothing # Dummy const for documentation

"""
    Literate.script(inputfile, outputdir; config::Dict=Dict(), kwargs...)

Generate a plain script file from `inputfile` and write the result to `outputdir`.

See the manual section on [Configuration](@ref) for documentation
of possible configuration with `config` and other keyword arguments.
"""
function script(inputfile, outputdir; config::Dict=Dict(), kwargs...)
    # Create configuration by merging default and userdefined
    config = create_configuration(inputfile; user_config=config, user_kwargs=kwargs)

    # normalize paths
    inputfile = normpath(inputfile)
    isfile(inputfile) || throw(ArgumentError("cannot find inputfile `$(inputfile)`"))
    inputfile = realpath(abspath(inputfile))
    mkpath(outputdir)
    outputdir = realpath(abspath(outputdir))

    @info "generating plain script file from `$(Base.contractuser(inputfile))`"
    # read content
    content = read(inputfile, String)

    # run custom pre-processing from user
    content = config["preprocess"](content)

    # default replacements
    content = replace_default(content, :jl; config=config)

    # create the script file
    chunks = parse(content)
    ioscript = IOBuffer()
    for chunk in chunks
        if isa(chunk, CodeChunk)
            for line in chunk.lines
                write(ioscript, line, '\n')
            end
            write(ioscript, '\n') # add a newline between each chunk
        elseif isa(chunk, MDChunk) && config["keep_comments"]::Bool
            for line in chunk.lines
                write(ioscript, rstrip(line.first * "# " * line.second * '\n'))
            end
            write(ioscript, '\n') # add a newline between each chunk
        end
    end

    # custom post-processing from user
    content = config["postprocess"](String(take!(ioscript)))

    # write to file
    isdir(outputdir) || error("not a directory: $(outputdir)")
    outputfile = joinpath(outputdir, config["name"]::String * ".jl")

    @info "writing result to `$(Base.contractuser(outputfile))`"
    write(outputfile, content)

    return outputfile
end

"""
    Literate.markdown(inputfile, outputdir; config::Dict=Dict(), kwargs...)

Generate a markdown file from `inputfile` and write the result
to the directory `outputdir`.

See the manual section on [Configuration](@ref) for documentation
of possible configuration with `config` and other keyword arguments.
"""
function markdown(inputfile, outputdir; config::Dict=Dict(), kwargs...)
    # Create configuration by merging default and userdefined
    config = create_configuration(inputfile; user_config=config, user_kwargs=kwargs)

    # normalize paths
    inputfile = normpath(inputfile)
    isfile(inputfile) || throw(ArgumentError("cannot find inputfile `$(inputfile)`"))
    inputfile = realpath(abspath(inputfile))
    mkpath(outputdir)
    outputdir = realpath(abspath(outputdir))

    @info "generating markdown page from `$(Base.contractuser(inputfile))`"
    # read content
    content = read(inputfile, String)

    # run custom pre-processing from user
    content = config["preprocess"](content)

    # run some Documenter specific things
    if config["documenter"]::Bool
        # change the Edit on GitHub link
        path = relpath(inputfile, get(config, "repo_root_path", pwd())::String)
        path = replace(path, "\\" => "/")
        content = """
        # ```@meta
        # EditURL = "@__REPO_ROOT_URL__/$(path)"
        # ```

        """ * content
    end

    # default replacements
    content = replace_default(content, :md; config=config)

    # create the markdown file
    chunks = parse(content)
    iomd = IOBuffer()
    continued = false
    for chunk in chunks
        if isa(chunk, MDChunk)
            for line in chunk.lines
                write(iomd, line.second, '\n') # skip indent here
            end
        else # isa(chunk, CodeChunk)
            codefence = config["codefence"]::Pair
            write(iomd, codefence.first)
            # make sure the code block is finalized if we are printing to ```@example
            if chunk.continued && startswith(codefence.first, "```@example") && config["documenter"]::Bool
                write(iomd, "; continued = true")
            end
            write(iomd, '\n')
            last_line = ""
            for line in chunk.lines
                write(iomd, line, '\n')
                last_line = line
            end
            if config["documenter"]::Bool && REPL.ends_with_semicolon(last_line)
                write(iomd, "nothing #hide\n")
            end
            write(iomd, codefence.second, '\n')
        end
        write(iomd, '\n') # add a newline between each chunk
    end

    # custom post-processing from user
    content = config["postprocess"](String(take!(iomd)))

    # write to file
    isdir(outputdir) || error("not a directory: $(outputdir)")
    outputfile = joinpath(outputdir, config["name"]::String * ".md")

    @info "writing result to `$(Base.contractuser(outputfile))`"
    write(outputfile, content)

    return outputfile
end

const JUPYTER_VERSION = v"4.3.0"

parse_nbmeta(line::Pair) = parse_nbmeta(line.second)
function parse_nbmeta(line)
    # Format: %% optional ignored text [type] {optional metadata JSON}
    # Cf. https://jupytext.readthedocs.io/en/latest/formats.html#the-percent-format
    m = match(r"^%% ([^[{]+)?\s*(?:\[(\w+)\])?\s*(\{.*)?$", line)
    typ = m.captures[2]
    name = m.captures[1] === nothing ? Dict{String, String}() : Dict("name" => m.captures[1])
    meta = m.captures[3] === nothing ? Dict{String, Any}() : JSON.parse(m.captures[3])
    return typ, merge(name, meta)
end
line_is_nbmeta(line::Pair) = line_is_nbmeta(line.second)
line_is_nbmeta(line) = startswith(line, "%% ")

"""
    Literate.notebook(inputfile, outputdir; config::Dict=Dict(), kwargs...)

Generate a notebook from `inputfile` and write the result to `outputdir`.

See the manual section on [Configuration](@ref) for documentation
of possible configuration with `config` and other keyword arguments.
"""
function notebook(inputfile, outputdir; config::Dict=Dict(), kwargs...)
    # Create configuration by merging default and userdefined
    config = create_configuration(inputfile; user_config=config, user_kwargs=kwargs)

    # normalize paths
    inputfile = normpath(inputfile)
    isfile(inputfile) || throw(ArgumentError("cannot find inputfile `$(inputfile)`"))
    inputfile = realpath(abspath(inputfile))
    mkpath(outputdir)
    outputdir = realpath(abspath(outputdir))

    @info "generating notebook from `$(Base.contractuser(inputfile))`"
    # read content
    content = read(inputfile, String)

    # run custom pre-processing from user
    content = config["preprocess"](content)

    # default replacements
    content = replace_default(content, :nb; config=config)

    # parse
    chunks = parse(content; allow_continued = false)

    # create the notebook
    nb = Dict()
    nb["nbformat"] = JUPYTER_VERSION.major
    nb["nbformat_minor"] = JUPYTER_VERSION.minor

    ## create the notebook cells
    cells = []
    for chunk in chunks
        cell = Dict()
        chunktype = isa(chunk, MDChunk) ? "markdown" : "code"
        if !isempty(chunk.lines) && line_is_nbmeta(chunk.lines[1])
            metatype, metadata = parse_nbmeta(chunk.lines[1])
            metatype !== nothing && metatype != chunktype && error("specifying a different cell type is not supported")
            popfirst!(chunk.lines)
        else
            metadata = Dict{String, Any}()
        end
        lines = isa(chunk, MDChunk) ?
                    String[x.second for x in chunk.lines] : # skip indent
                    chunk.lines
        @views map!(x -> x * '\n', lines[1:end-1], lines[1:end-1])
        cell["cell_type"] = chunktype
        cell["metadata"] = metadata
        cell["source"] = lines
        cell["outputs"] = []
        if chunktype == "code"
            cell["execution_count"] = nothing
        end
        push!(cells, cell)
    end
    nb["cells"] = cells

    ## create metadata
    metadata = Dict()

    kernelspec = Dict()
    kernelspec["language"] =  "julia"
    kernelspec["name"] =  "julia-$(VERSION.major).$(VERSION.minor)"
    kernelspec["display_name"] = "Julia $(string(VERSION))"
    metadata["kernelspec"] = kernelspec

    language_info = Dict()
    language_info["file_extension"] = ".jl"
    language_info["mimetype"] = "application/julia"
    language_info["name"]=  "julia"
    language_info["version"] = string(VERSION)
    metadata["language_info"] = language_info

    nb["metadata"] = metadata

    # custom post-processing from user
    nb = config["postprocess"](nb)

    if config["execute"]::Bool
        @info "executing notebook `$(config["name"] * ".ipynb")`"
        try
            cd(outputdir) do
                nb = execute_notebook(nb)
            end
        catch err
            @error "error when executing notebook based on input file: `$(Base.contractuser(inputfile))`"
            rethrow(err)
        end
    end

    # write to file
    isdir(outputdir) || error("not a directory: $(outputdir)")
    outputfile = joinpath(outputdir, config["name"]::String * ".ipynb")

    @info "writing result to `$(Base.contractuser(outputfile))`"
    ionb = IOBuffer()
    JSON.print(ionb, nb, 1)
    write(outputfile, seekstart(ionb))

    return outputfile
end

function execute_notebook(nb)
    m = Module(gensym())
    # eval(expr) is available in the REPL (i.e. Main) so we emulate that for the sandbox
    Core.eval(m, :(eval(x) = Core.eval($m, x)))
    # modules created with Module() does not have include defined
    # abspath is needed since this will call `include_relative`
    Core.eval(m, :(include(x) = Base.include($m, abspath(x))))

    io = IOBuffer()

    execution_count = 0
    for cell in nb["cells"]
        cell["cell_type"] == "code" || continue
        execution_count += 1
        cell["execution_count"] = execution_count
        block = join(cell["source"])
        # r is the result
        # status = (true|false)
        # _: backtrace
        # str combined stdout, stderr output
        r, status, _, str = Documenter.withoutput() do
            include_string(m, block)
        end
        if !status
            error("""
                 $(sprint(showerror, r))
                 when executing the following code block

                 ```julia
                 $block
                 ```
                 """)
        end

        # str should go into stream
        if !isempty(str)
            stream = Dict{String,Any}()
            stream["output_type"] = "stream"
            stream["name"] = "stdout"
            stream["text"] = collect(Any, eachline(IOBuffer(String(str)), keep = true))
            push!(cell["outputs"], stream)
        end

        # check if ; is used to suppress output
        r = REPL.ends_with_semicolon(block) ? nothing : r

        # r should go into execute_result
        if r !== nothing
            execute_result = Dict{String,Any}()
            execute_result["output_type"] = "execute_result"
            execute_result["metadata"] = Dict()
            execute_result["execution_count"] = execution_count
            dd = Base.invokelatest(IJulia.display_dict, r)
            # we need to split some mime types into vectors of lines instead of a single string
            for mime in ("image/svg+xml", "text/html")
                if haskey(dd, mime)
                    dd[mime] = collect(Any, eachline(IOBuffer(dd[mime]), keep = true))
                end
            end
            execute_result["data"] = dd

            push!(cell["outputs"], execute_result)
        end

    end
    return nb
end

end # module
