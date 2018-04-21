module Literate

import Compat: replace, popfirst!, @error, @info

import JSON

include("IJulia.jl")
import .IJulia
include("Documenter.jl")
import .Documenter

# # Some simple rules:
#
# * All lines starting with `#'` are considered markdown, everything else is considered code
# * The file is parsed in "chunks" of code and markdown. A new chunk is created when the
#   lines switch context from markdown to code and vice versa.
# * Lines starting with `#-` can be used to start a new chunk.
# * Lines starting with `#md` are filtered out unless creating a markdown file
# * Lines starting with `#nb` are filtered out unless creating a notebook
# * Lines starting with, or ending with, `#jl` are filtered out unless creating a script file
# * Whitespace within a chunk is preserved
# * Empty chunks are removed, leading and trailing empty lines in a chunk are also removed

# Parser
abstract type Chunk end
struct MDChunk <: Chunk
    lines::Vector{String}
end
MDChunk() = MDChunk(String[])
mutable struct CodeChunk <: Chunk
    lines::Vector{String}
    continued::Bool
end
CodeChunk() = CodeChunk(String[], false)

function parse(content; allow_continued = true)
    lines = collect(eachline(IOBuffer(content)))

    chunks = Chunk[]
    push!(chunks, startswith(lines[1], "#'") ? MDChunk() : CodeChunk())

    for line in lines
        line = rstrip(line)
        if startswith(line, "#-") # new chunk
            # assume same as last chunk, will be cleaned up otherwise
            push!(chunks, typeof(chunks[end])())
        elseif startswith(line, "#'") # markdown
            if !(chunks[end] isa MDChunk)
                push!(chunks, MDChunk())
            end
            # remove "#' " and "#'\n"
            line = replace(replace(line, r"^#' " => ""), r"^#'$" => "")
            push!(chunks[end].lines, line)
        else # code
            if !(chunks[end] isa CodeChunk)
                push!(chunks, CodeChunk())
            end
            push!(chunks[end].lines, line)
        end
    end

    # clean up the chunks
    ## remove empty chunks
    filter!(x -> !isempty(x.lines), chunks)
    filter!(x -> !all(y -> isempty(y), x.lines), chunks)
    ## remove leading/trailing empty lines
    for chunk in chunks
        while isempty(chunk.lines[1])
            popfirst!(chunk.lines)
        end
        while isempty(chunk.lines[end])
            pop!(chunk.lines)
        end
    end

    # find code chunks that are continued
    last_code_chunk = 0
    for (i, chunk) in enumerate(chunks)
        isa(chunk, MDChunk) && continue
        if startswith(last(chunk.lines)," ")
            chunk.continued = true
        end
        if startswith(first(chunk.lines)," ")
            chunks[last_code_chunk].continued = true
        end
        last_code_chunk = i
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
                else # need to put back #'
                    for line in chunk.lines
                        push!(merged_chunks[end].lines, rstrip("#' " * line))
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
                         name = error("required kwarg"),
                         documenter = true,
                         branch = "gh-pages",
                         commit = "master"
                         )
    repls = Pair{Any,Any}[]

    push!(repls, "\r\n" => "\n") # normalize line endings

    if sym === :md
        push!(repls, r"^#nb.*\n?"m => "") # remove #nb lines
        push!(repls, r"^#jl.*\n?"m => "") # remove leading #jl lines
        push!(repls, r".*#jl$\n?"m => "") # remove trailing #jl lines
        push!(repls, r"^#md "m => "")     # remove leading #md
    elseif sym === :nb
        push!(repls, r"^#md.*\n?"m => "") # remove #md lines
        push!(repls, r"^#jl.*\n?"m => "") # remove leading #jl lines
        push!(repls, r".*#jl$\n?"m => "") # remove trailing #jl lines
        push!(repls, r"^#nb "m => "")     # remove leading #nb
        push!(repls, r"```math(.*?)```"s => s"\\begin{equation}\1\\end{equation}")
    else # sym === :jl
        push!(repls, r"^#md.*\n?"m => "") # remove #md lines
        push!(repls, r"^#nb.*\n?"m => "") # remove #nb lines
        push!(repls, r"^#jl "m => "")     # remove leading #jl
        push!(repls, r" #jl$"m => "")     # remove trailing #jl
    end

    # name
    push!(repls, "@__NAME__" => name)

    # fix links
    travis_repo_slug = get(ENV, "TRAVIS_REPO_SLUG", "TRAVIS_REPO_SLUG")
    ## use same logic as Documenter to figure out the deploy folder
    travis_tag = get(ENV, "TRAVIS_TAG", "TRAVIS_TAG")
    if isempty(travis_tag)
        folder = "latest"
    else
        # use the versioned directory for links, even for the stable and release-
        # folders since this will never change
        folder = travis_tag
    end

    ## replace @__REPO_ROOT_URL__ to master/commit
    repo_root_url = "https://github.com/$(travis_repo_slug)/blob/$(commit)/"
    push!(repls, "@__REPO_ROOT_URL__" => repo_root_url)

    ## replace @__NBVIEWER_ROOT_URL__ to latest or version directory
    nbviewer_root_url = "https://nbviewer.jupyter.org/github/$(travis_repo_slug)/blob/$(branch)/$(folder)/"
    push!(repls, "@__NBVIEWER_ROOT_URL__" => nbviewer_root_url)

    if get(ENV, "HAS_JOSH_K_SEAL_OF_APPROVAL", "") != "true"
        @info "not running on Travis, skipping links will not be correct."
    end

    # run some Documenter specific things
    if documenter && sym !== :md
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

"""
    Literate.script(inputfile, outputdir; kwargs...)

Generate a plain script file from `inputfile` and write the result to `outputdir`.

Keyword arguments:
- `name`: name of the output file, excluding `.jl`. `name` is also used to
  replace `@__NAME__`. Defaults to the filename of `inputfile`.
- `preprocess`, `postprocess`: custom pre- and post-processing functions,
  see the [Custom pre- and post-processing](@ref Custom-pre-and-post-processing)
  section of the manual. Defaults to `identity`.
- `documenter`: boolean that says if the source contains Documenter.jl specific things
  to filter out during script generation. Defaults to `true`. See the the manual
  section on [Interaction with Documenter](@ref Interaction-with-Documenter).
"""
function script(inputfile, outputdir; preprocess = identity, postprocess = identity,
                name = filename(inputfile), documenter = true, kwargs...)
    # normalize paths
    inputfile = realpath(abspath(inputfile))
    mkpath(outputdir)
    outputdir = realpath(abspath(outputdir))
    @info "generating plain script file from $(inputfile)"
    # read content
    content = read(inputfile, String)

    # run custom pre-processing from user
    content = preprocess(content)

    # default replacements
    content = replace_default(content, :jl; name = name, documenter = documenter)

    # create the script file
    chunks = parse(content)
    ioscript = IOBuffer()
    for chunk in chunks
        if isa(chunk, CodeChunk)
            for line in chunk.lines
                write(ioscript, line, '\n')
            end
            write(ioscript, '\n') # add a newline between each chunk
        end
    end

    # custom post-processing from user
    content = postprocess(String(take!(ioscript)))

    # write to file
    isdir(outputdir) || error("not a directory: $(outputdir)")
    outputfile = joinpath(outputdir, name * ".jl")

    @info "writing result to $(outputfile)"
    write(outputfile, content)

    return outputfile
end

"""
    Literate.markdown(inputfile, outputdir; kwargs...)

Generate a markdown file from `inputfile` and write the result
to the directory`outputdir`.

Keyword arguments:
- `name`: name of the output file, excluding `.md`. `name` is also used to name
  all the `@example` blocks, and to replace `@__NAME__`.
  Defaults to the filename of `inputfile`.
- `preprocess`, `postprocess`: custom pre- and post-processing functions,
  see the [Custom pre- and post-processing](@ref Custom-pre-and-post-processing)
  section of the manual. Defaults to `identity`.
- `documenter`: boolean that tells if the output is intended to use with Documenter.jl.
  Defaults to `true`. See the the manual section on
  [Interaction with Documenter](@ref Interaction-with-Documenter).
- `codefence`: A `Pair` of opening and closing code fence. Defaults to
  ````
  "```@example \$(name)" => "```"
  ````
  if `documenter = true` and
  ````
  "```julia" => "```"
  ````
  if `documenter = false`.
"""
function markdown(inputfile, outputdir; preprocess = identity, postprocess = identity,
                  name = filename(inputfile), documenter::Bool = true,
                  codefence::Pair = documenter ? "```@example $(name)" => "```" : "```julia" => "```",
                  kwargs...)
    # normalize paths
    inputfile = realpath(abspath(inputfile))
    mkpath(outputdir)
    outputdir = realpath(abspath(outputdir))
    @info "generating markdown page from $(inputfile)"
    # read content
    content = read(inputfile, String)

    # run custom pre-processing from user
    content = preprocess(content)

    # run some Documenter specific things
    if documenter
        # change the Edit on GitHub link
        repo = get(ENV, "TRAVIS_REPO_SLUG", "")
        pkg = first(split(last(split(repo, '/')), '.'))
        content = """
        #' ```@meta
        #' EditURL = "@__REPO_ROOT_URL__$(replace(relpath(inputfile, Pkg.dir(pkg)), "\\" => "/"))"
        #' ```

        """ * content
    end

    # default replacements
    content = replace_default(content, :md; name = name, documenter = documenter)

    # create the markdown file
    chunks = parse(content)
    iomd = IOBuffer()
    continued = false
    for chunk in chunks
        if isa(chunk, MDChunk)
            for line in chunk.lines
                write(iomd, line, '\n')
            end
        else # isa(chunk, CodeChunk)
            write(iomd, codefence.first)
            # make sure the code block is finalized if we are printing to ```@example
            if chunk.continued && startswith(codefence.first, "```@example") && documenter
                write(iomd, "; continued = true")
            end
            write(iomd, '\n')
            for line in chunk.lines
                write(iomd, line, '\n')
            end
            write(iomd, codefence.second, '\n')
        end
        write(iomd, '\n') # add a newline between each chunk
    end

    # custom post-processing from user
    content = postprocess(String(take!(iomd)))

    # write to file
    isdir(outputdir) || error("not a directory: $(outputdir)")
    outputfile = joinpath(outputdir, name * ".md")

    @info "writing result to $(outputfile)"
    write(outputfile, content)

    return outputfile
end

const JUPYTER_VERSION = v"4.3.0"

"""
    Literate.notebook(inputfile, outputdir; kwargs...)

Generate a notebook from `inputfile` and write the result to `outputdir`.

Keyword arguments:
- `name`: name of the output file, excluding `.ipynb`. `name` is also used to
  replace `@__NAME__`. Defaults to the filename of `inputfile`.
- `preprocess`, `postprocess`: custom pre- and post-processing functions,
  see the [Custom pre- and post-processing](@ref Custom-pre-and-post-processing)
  section of the manual. Defaults to `identity`.
- `execute`: a boolean deciding if the generated notebook should also
  be executed or not. Defaults to `true`. The current working directory
  is set to `outputdir` when executing the notebook.
- `documenter`: boolean that says if the source contains Documenter.jl specific things
  to filter out during notebook generation. Defaults to `true`. See the the manual
  section on [Interaction with Documenter](@ref Interaction-with-Documenter).
"""
function notebook(inputfile, outputdir; preprocess = identity, postprocess = identity,
                  execute::Bool=true, documenter::Bool=true,
                  name = filename(inputfile), kwargs...)
    # normalize paths
    inputfile = realpath(abspath(inputfile))
    mkpath(outputdir)
    outputdir = realpath(abspath(outputdir))
    @info "generating notebook from $(inputfile)"

    # read content
    content = read(inputfile, String)

    # run custom pre-processing from user
    content = preprocess(content)

    # default replacements
    content = replace_default(content, :nb; name = name, documenter = documenter)

    # create the notebook
    nb = Dict()
    nb["nbformat"] = JUPYTER_VERSION.major
    nb["nbformat_minor"] = JUPYTER_VERSION.minor

    # parse
    chunks = parse(content; allow_continued = false)

    ## create the notebook cells
    cells = []
    for chunk in chunks
        cell = Dict()
        if isa(chunk, MDChunk)
            cell["cell_type"] = "markdown"
            cell["metadata"] = Dict()
            @views map!(x -> x * '\n', chunk.lines[1:end-1], chunk.lines[1:end-1])
            cell["source"] = chunk.lines
            cell["outputs"] = []
        else # isa(chunk, CodeChunk)
            cell["cell_type"] = "code"
            cell["metadata"] = Dict()
            @views map!(x -> x * '\n', chunk.lines[1:end-1], chunk.lines[1:end-1])
            cell["source"] = chunk.lines
            cell["execution_count"] = nothing
            cell["outputs"] = []
        end
        push!(cells, cell)
    end
    nb["cells"] = cells

    ## create metadata
    metadata = Dict()

    kernelspec = Dict()
    kernelspec["language"] =  "julia"
    kernelspec["name"] =  "julia-$(VERSION.major).$(VERSION.minor)"
    kernelspec["display_name"] = "Julia $(VERSION.major).$(VERSION.minor).$(VERSION.patch)"
    metadata["kernelspec"] = kernelspec

    language_info = Dict()
    language_info["file_extension"] = ".jl"
    language_info["mimetype"] = "application/julia"
    language_info["name"]=  "julia"
    language_info["version"] = "$(VERSION.major).$(VERSION.minor).$(VERSION.patch)"
    metadata["language_info"] = language_info

    nb["metadata"] = metadata

    # custom post-processing from user
    nb = postprocess(nb)

    if execute
        @info "executing notebook $(name * ".ipynb")"
        try
            # run(`jupyter nbconvert --ExecutePreprocessor.timeout=-1 --to notebook --execute $(abspath(outputfile)) --output $(filename(outputfile)).ipynb`)
            cd(outputdir) do
                nb = execute_notebook(nb)
            end
        catch err
            @error "error when executing notebook $(name * ".ipynb")"
            rethrow(err)
        end
        # clean up (only needed for jupyter-nbconvert)
        rm(joinpath(outputdir, ".ipynb_checkpoints"), force=true, recursive = true)
    end

    # write to file
    isdir(outputdir) || error("not a directory: $(outputdir)")
    outputfile = joinpath(outputdir, name * ".ipynb")

    @info "writing result to $(outputfile)"
    ionb = IOBuffer()
    JSON.print(ionb, nb, 1)
    write(outputfile, seekstart(ionb))

    return outputfile
end

function execute_notebook(nb)
    # sandbox module for the notebook (TODO: Do this in Main?)
    m = Module(gensym())
    io = IOBuffer()

    execution_count = 0
    for cell in nb["cells"]
        cell["cell_type"] == "code" || continue
        execution_count += 1
        cell["execution_count"] = execution_count
        block = join(cell["source"], '\n')
        # r is the result
        # status = (true|false)
        # _: backtrace
        # str combined stdout, stderr output
        r, status, _, str = Documenter.withoutput() do
            include_string(m, block)
        end
        status || error("something went wrong when evaluating code")

        # str should go into stream
        if !isempty(str)
            stream = Dict{String,Any}()
            stream["output_type"] = "stream"
            stream["name"] = "stdout"
            stream["text"] = collect(Any, eachline(IOBuffer(String(str)), chomp = false)) # 0.7 chomp = false => keep = true
            push!(cell["outputs"], stream)
        end

        # check if ; is used to suppress output
        r = Base.REPL.ends_with_semicolon(block) ? nothing : r

        # r should go into execute_result
        if r !== nothing
            execute_result = Dict{String,Any}()
            execute_result["output_type"] = "execute_result"
            execute_result["metadata"] = Dict()
            execute_result["execution_count"] = execution_count
            execute_result["data"] = IJulia.display_dict(r)

            push!(cell["outputs"], execute_result)
        end

    end
    nb
end

end # module
