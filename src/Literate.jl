"""
    Literate

Julia package for Literate Programming. See
https://fredrikekre.github.io/Literate.jl/ for documentation.
"""
module Literate

import JSON, REPL, IOCapture

include("IJulia.jl")
import .IJulia

abstract type AbstractFlavor end
struct DefaultFlavor <: AbstractFlavor end
struct DocumenterFlavor <: AbstractFlavor end
struct CommonMarkFlavor <: AbstractFlavor end
struct FranklinFlavor <: AbstractFlavor end

# # Some simple rules:
#
# * All lines starting with `# ` are considered markdown, everything else is considered code
# * The file is parsed in "chunks" of code and markdown. A new chunk is created when the
#   lines switch context from markdown to code and vice versa.
# * Lines starting with `#-` can be used to start a new chunk.
# * Lines starting/ending with `#md` are filtered out unless creating a markdown file
# * Lines starting/ending with `#nb` are filtered out unless creating a notebook
# * Lines starting/ending with, `#jl` are filtered out unless creating a script file
# * Lines starting/ending with, `#src` are filtered out unconditionally
# * #md, #nb, and #jl can be negated as #!md, #!nb, and #!jl
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
                # ---
                #
                # *This $(sym === :md ? "page" : "notebook") was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*
                """
        end
    end

    push!(repls, "\r\n" => "\n") # normalize line endings

    # unconditionally rewrite multiline comments and
    # conditionally multiline markdown strings to regular comments
    function replace_multiline(multiline_r, str)
        while (m = match(multiline_r, str); m !== nothing)
            newlines = sprint() do io
                foreach(l -> println(io, "# ", l), eachline(IOBuffer(m[1])))
            end
            str = replace(str, multiline_r => chop(newlines); count=1)
        end
        return str
    end
    content = replace_multiline(r"(*ANYCRLF)^#=+$\R^(\X*?)\R^=+#$"m, content)
    if config["mdstrings"]::Bool
        content = replace_multiline(r"(*ANYCRLF)^md\"\"\"$\R^(\X*?)\R^\"\"\"$"m, content)
    end


    # unconditionally remove #src lines
    push!(repls, r"^#src.*\n?"m => "") # remove leading #src lines
    push!(repls, r".*#src$\n?"m => "") # remove trailing #src lines

    if sym === :md
        push!(repls, r"^#(md|!nb|!jl) "m => "")    # remove leading #md, #!nb, and #!jl
        push!(repls, r" #(md|!nb|!jl)$"m => "")    # remove trailing #md, #!nb, and #!jl
        push!(repls, r"^#(!md|nb|jl).*\n?"m => "") # remove leading #!md, #nb and #jl lines
        push!(repls, r".*#(!md|nb|jl)$\n?"m => "") # remove trailing #!md, #nb, and #jl lines
    elseif sym === :nb
        push!(repls, r"^#(!md|nb|!jl) "m => "")    # remove leading #!md, #nb, and #!jl
        push!(repls, r" #(!md|nb|!jl)$"m => "")    # remove trailing #!md, #nb, and #!jl
        push!(repls, r"^#(md|!nb|jl).*\n?"m => "") # remove leading #md, #!nb and #jl lines
        push!(repls, r".*#(md|!nb|jl)$\n?"m => "") # remove trailing #md, #!nb, and #jl lines
        # Replace Markdown stdlib math environments
        push!(repls, r"```math(.*?)```"s => s"$$\1$$")
        push!(repls, r"(?<!`)``([^`]+?)``(?!`)" => s"$\1$")
    else # sym === :jl
        push!(repls, r"^#(!md|!nb|jl) "m => "")    # remove leading #!md, #!nb, and #jl
        push!(repls, r" #(!md|!nb|jl)$"m => "")    # remove trailing #!md, #!nb, and #jl
        push!(repls, r"^#(md|nb|!jl).*\n?"m => "") # remove leading #md, #nb and #!jl lines
        push!(repls, r".*#(md|nb|!jl)$\n?"m => "") # remove trailing #md, #nb, and #!jl lines
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

    # Run some Documenter specific things
    if !isdocumenter(config)
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
isdocumenter(cfg) = cfg["flavor"]::AbstractFlavor isa DocumenterFlavor

_DEFAULT_IMAGE_FORMATS = [(MIME("image/svg+xml"), ".svg"), (MIME("image/png"), ".png"),
                          (MIME("image/jpeg"), ".jpeg")]

# Cache of inputfile => head branch
const HEAD_BRANCH_CACHE = Dict{String,String}()

# Guess the package (or repository) root url with "master" as fallback
# see JuliaDocs/Documenter.jl#1751
function edit_commit(inputfile, user_config)
    fallback_edit_commit = "master"
    if (c = get(user_config, "edit_commit", nothing); c !== nothing)
        return c
    end
    if (git = Sys.which("git"); git !== nothing)
        # Check the cache for the git root
        git_root = try
            readchomp(
                pipeline(
                    setenv(`$(git) rev-parse --show-toplevel`; dir=dirname(inputfile));
                    stderr=devnull,
                )
            )
        catch
        end
        if (c = get(HEAD_BRANCH_CACHE, git_root, nothing); c !== nothing)
            return c
        end
        # Check the cache for the file
        if (c = get(HEAD_BRANCH_CACHE, inputfile, nothing); c !== nothing)
            return c
        end
        # Fallback to git remote show
        env = copy(ENV)
        # Set environment variables to block interactive prompt
        env["GIT_TERMINAL_PROMPT"] = "0"
        env["GIT_SSH_COMMAND"] = get(ENV, "GIT_SSH_COMMAND", "ssh -o \"BatchMode yes\"")
        str = try
            read(
                pipeline(
                    setenv(`$(git) remote show origin`, env; dir=dirname(inputfile)),
                    stderr=devnull,
                ),
                String,
            )
        catch
        end
        if str !== nothing && (m = match(r"^\s*HEAD branch:\s*(.*)$"m, str); m !== nothing)
            head = String(m[1])
            HEAD_BRANCH_CACHE[something(git_root, inputfile)] = head
            return head
        end
    end
    return fallback_edit_commit
end

function create_configuration(inputfile; user_config, user_kwargs, type=nothing)
    # Combine user config with user kwargs
    user_config = Dict{String,Any}(string(k) => v for (k, v) in user_config)
    user_kwargs = Dict{String,Any}(string(k) => v for (k, v) in user_kwargs)
    user_config = merge!(user_config, user_kwargs)

    # deprecation of documenter kwarg
    if (d = get(user_config, "documenter", nothing); d !== nothing)
        if type === :md
            Base.depwarn("The documenter=$(d) keyword to Literate.markdown is deprecated." *
                " Pass `flavor = Literate.$(d ? "DocumenterFlavor" : "CommonMarkFlavor")()`" *
                " instead.", Symbol("Literate.markdown"))
            user_config["flavor"] = d ? DocumenterFlavor() : CommonMarkFlavor()
        elseif type === :nb
            Base.depwarn("The documenter=$(d) keyword to Literate.notebook is deprecated." *
                " It is not used anymore for notebook output.", Symbol("Literate.notebook"))
        elseif type === :jl
            Base.depwarn("The documenter=$(d) keyword to Literate.script is deprecated." *
                " It is not used anymore for script output.", Symbol("Literate.script"))
        end
    end

    # Add default config
    cfg = Dict{String,Any}()
    cfg["name"] = filename(inputfile)
    cfg["preprocess"] = identity
    cfg["postprocess"] = identity
    cfg["flavor"] = type === (:md) ? DocumenterFlavor() : DefaultFlavor()
    cfg["credit"] = true
    cfg["mdstrings"] = false
    cfg["keep_comments"] = false
    cfg["execute"] = type === :md ? false : true
    cfg["codefence"] = get(user_config, "flavor", cfg["flavor"]) isa DocumenterFlavor &&
                       !get(user_config, "execute", cfg["execute"]) ?
                       ("````@example $(get(user_config, "name", replace(cfg["name"], r"\s" => "_")))" => "````") :
                       ("````julia" => "````")
    cfg["image_formats"] = _DEFAULT_IMAGE_FORMATS
    cfg["edit_commit"] = edit_commit(inputfile, user_config)
    deploy_branch = "gh-pages" # TODO: Make this configurable like Documenter?
    # Strip build version from a tag (cf. JuliaDocs/Documenter.jl#1298, Literate.jl#162)
    function version_tag_strip_build(tag)
        m = match(Base.VERSION_REGEX, tag)
        m === nothing && return tag
        s0 = startswith(tag, 'v') ? "v" : ""
        s1 = m[1] # major
        s2 = m[2] === nothing ? "" : ".$(m[2])" # minor
        s3 = m[3] === nothing ? "" : ".$(m[3])" # patch
        s4 = m[5] === nothing ? "" : m[5] # pre-release (starting with -)
        # m[7] is the build, which we want to discard
        return "$s0$s1$s2$s3$s4"
    end

    if haskey(ENV, "HAS_JOSH_K_SEAL_OF_APPROVAL") # Travis CI
        repo_slug = get(ENV, "TRAVIS_REPO_SLUG", "unknown-repository")
        deploy_folder = if get(ENV, "TRAVIS_PULL_REQUEST", nothing) == "false"
            t = get(ENV, "TRAVIS_TAG", "")
            isempty(t) ? get(user_config, "devurl", "dev") : version_tag_strip_build(t)
        else
            "previews/PR$(get(ENV, "TRAVIS_PULL_REQUEST", "##"))"
        end
        cfg["repo_root_url"] = "https://github.com/$(repo_slug)/blob/$(cfg["edit_commit"])"
        cfg["nbviewer_root_url"] = "https://nbviewer.jupyter.org/github/$(repo_slug)/blob/$(deploy_branch)/$(deploy_folder)"
        cfg["binder_root_url"] = "https://mybinder.org/v2/gh/$(repo_slug)/$(deploy_branch)?filepath=$(deploy_folder)"
    elseif haskey(ENV, "GITHUB_ACTIONS")
        repo_slug = get(ENV, "GITHUB_REPOSITORY", "unknown-repository")
        deploy_folder = if get(ENV, "GITHUB_EVENT_NAME", nothing) == "push"
            if (m = match(r"^refs\/tags\/(.*)$", get(ENV, "GITHUB_REF", ""))) !== nothing
                version_tag_strip_build(String(m.captures[1]))
            else
                get(user_config, "devurl", "dev")
            end
        elseif (m = match(r"refs\/pull\/(\d+)\/merge", get(ENV, "GITHUB_REF", ""))) !== nothing
            "previews/PR$(m.captures[1])"
        else
            "dev"
        end
        cfg["repo_root_url"] = "https://github.com/$(repo_slug)/blob/$(cfg["edit_commit"])"
        cfg["nbviewer_root_url"] = "https://nbviewer.jupyter.org/github/$(repo_slug)/blob/$(deploy_branch)/$(deploy_folder)"
        cfg["binder_root_url"] = "https://mybinder.org/v2/gh/$(repo_slug)/$(deploy_branch)?filepath=$(deploy_folder)"
    elseif haskey(ENV, "GITLAB_CI")
        if (url = get(ENV, "CI_PROJECT_URL", nothing)) !== nothing
            cfg["repo_root_url"] = "$(url)/blob/$(cfg["edit_commit"])"
        end
        if (url = get(ENV, "CI_PAGES_URL", nothing)) !== nothing &&
           (m = match(r"https://(.+)", url)) !== nothing
            cfg["nbviewer_root_url"] = "https://nbviewer.jupyter.org/urls/$(m[1])"
        end
    end

    # Merge default_config with user_config
    merge!(cfg, user_config)
    return cfg
end

"""
    DEFAULT_CONFIGURATION

Default configuration for [`Literate.markdown`](@ref), [`Literate.notebook`](@ref) and
[`Literate.script`](@ref) which is used for everything not specified by the user.
Configuration can be passed as individual keyword arguments or as a dictionary passed
with the `config` keyword argument.
See the manual section about [Configuration](@ref) for more information.

Available options:

- `name` (default: `filename(inputfile)`): Name of the output file (excluding the file
  extension).
- `preprocess` (default: `identity`): Custom preprocessing function mapping a `String` to
  a `String`. See [Custom pre- and post-processing](@ref Custom-pre-and-post-processing).
- `postprocess` (default: `identity`): Custom preprocessing function mapping a `String` to
  a `String`. See [Custom pre- and post-processing](@ref Custom-pre-and-post-processing).
- `credit` (default: `true`): Boolean for controlling the addition of
  `This file was generated with Literate.jl ...` to the bottom of the page. If you find
  Literate.jl useful then feel free to keep this.
- `keep_comments` (default: `false`): When `true`, keeps markdown lines as comments in the
  output script. Only applicable for `Literate.script`.
- `execute` (default: `true` for notebook, `false` for markdown): Whether to execute and
  capture the output. Only applicable for `Literate.notebook` and `Literate.markdown`.
- `codefence` (default: `````"````@example \$(name)" => "````"````` for `DocumenterFlavor()`
  and `````"````julia" => "````"````` otherwise): Pair containing opening and closing
  code fence for wrapping code blocks.
- `flavor` (default: `Literate.DocumenterFlavor()`) Output flavor for markdown, see
  [Markdown flavors](@ref). Only applicable for `Literate.markdown`.
- `devurl` (default: `"dev"`): URL for "in-development" docs, see [Documenter docs]
  (https://juliadocs.github.io/Documenter.jl/). Unused if `repo_root_url`/
  `nbviewer_root_url`/`binder_root_url` are set.
- `repo_root_url`: URL to the root of the repository. Determined automatically on Travis CI,
  GitHub Actions and GitLab CI. Used for `@__REPO_ROOT_URL__`.
- `nbviewer_root_url`: URL to the root of the repository as seen on nbviewer. Determined
  automatically on Travis CI, GitHub Actions and GitLab CI.
  Used for `@__NBVIEWER_ROOT_URL__`.
- `binder_root_url`: URL to the root of the repository as seen on mybinder. Determined
  automatically on Travis CI, GitHub Actions and GitLab CI.
  Used for `@__BINDER_ROOT_URL__`.
- `image_formats`: A vector of `(mime, ext)` tuples, with the default
  `$(_DEFAULT_IMAGE_FORMATS)`. Results which are `showable` with a MIME type are saved with
  the first match, with the corresponding extension.
"""
const DEFAULT_CONFIGURATION=nothing # Dummy const for documentation

function preprocessor(inputfile, outputdir; user_config, user_kwargs, type)
    # Create configuration by merging default and userdefined
    config = create_configuration(inputfile; user_config=user_config,
        user_kwargs=user_kwargs, type=type)

    # normalize paths
    inputfile = normpath(inputfile)
    isfile(inputfile) || throw(ArgumentError("cannot find inputfile `$(inputfile)`"))
    inputfile = realpath(abspath(inputfile))
    mkpath(outputdir)
    outputdir = realpath(abspath(outputdir))
    isdir(outputdir) || error("not a directory: $(outputdir)")
    ext = type === (:nb) ? ".ipynb" : ".$(type)"
    outputfile = joinpath(outputdir, config["name"]::String * ext)
    if inputfile == outputfile
        throw(ArgumentError("outputfile (`$outputfile`) is identical to inputfile (`$inputfile`)"))
    end

    output_thing = type === (:md) ? "markdown page" :
                   type === (:nb) ? "notebook" :
                   type === (:jl) ? "plain script file" : error("nope")
    @info "generating $(output_thing) from `$(Base.contractuser(inputfile))`"

    # Add some information for passing around Literate methods
    config["literate_inputfile"] = inputfile
    config["literate_outputdir"] = outputdir
    config["literate_ext"] = ext
    config["literate_outputfile"] = outputfile

    # read content
    content = read(inputfile, String)

    # run custom pre-processing from user
    content = config["preprocess"](content)

    # run some Documenter specific things for markdown output
    if type === :md && isdocumenter(config)
        # change the Edit on GitHub link
        edit_url = relpath(inputfile, config["literate_outputdir"])
        edit_url = replace(edit_url, "\\" => "/")
        content = """
        # ```@meta
        # EditURL = "$(edit_url)"
        # ```

        """ * content
    end

    # default replacements
    content = replace_default(content, type; config=config)

    # parse the content into chunks
    chunks = parse(content; allow_continued = type !== :nb)

    return chunks, config
end

function write_result(content, config; print=print)
    outputfile = config["literate_outputfile"]
    @info "writing result to `$(Base.contractuser(outputfile))`"
    open(outputfile, "w") do io
        print(io, content)
    end
    return outputfile
end

"""
    Literate.script(inputfile, outputdir=pwd(); config::AbstractDict=Dict(), kwargs...)

Generate a plain script file from `inputfile` and write the result to `outputdir`.

See the manual section on [Configuration](@ref) for documentation
of possible configuration with `config` and other keyword arguments.
"""
function script(inputfile, outputdir=pwd(); config::AbstractDict=Dict(), kwargs...)
    # preprocessing and parsing
    chunks, config =
        preprocessor(inputfile, outputdir; user_config=config, user_kwargs=kwargs, type=:jl)

    # create the script file
    ioscript = IOBuffer()
    for chunk in chunks
        if isa(chunk, CodeChunk)
            for line in chunk.lines
                write(ioscript, line, '\n')
            end
            write(ioscript, '\n') # add a newline between each chunk
        elseif isa(chunk, MDChunk) && config["keep_comments"]::Bool
            for line in chunk.lines
                write(ioscript, rstrip(line.first * "# " * line.second) * '\n')
            end
            write(ioscript, '\n') # add a newline between each chunk
        end
    end

    # custom post-processing from user
    content = config["postprocess"](String(take!(ioscript)))

    # write to file
    outputfile = write_result(content, config)
    return outputfile
end


"""
    Literate.markdown(inputfile, outputdir=pwd(); config::AbstractDict=Dict(), kwargs...)

Generate a markdown file from `inputfile` and write the result
to the directory `outputdir`.

See the manual section on [Configuration](@ref) for documentation
of possible configuration with `config` and other keyword arguments.
"""
function markdown(inputfile, outputdir=pwd(); config::AbstractDict=Dict(), kwargs...)
    # preprocessing and parsing
    chunks, config =
        preprocessor(inputfile, outputdir; user_config=config, user_kwargs=kwargs, type=:md)

    # create the markdown file
    sb = sandbox()
    iomd = IOBuffer()
    for (chunknum, chunk) in enumerate(chunks)
        if isa(chunk, MDChunk)
            for line in chunk.lines
                write(iomd, line.second, '\n') # skip indent here
            end
        else # isa(chunk, CodeChunk)
            iocode = IOBuffer()
            codefence = config["codefence"]::Pair
            write(iocode, codefence.first)
            # make sure the code block is finalized if we are printing to ```@example
            # (or ````@example, any number of backticks >= 3 works)
            if chunk.continued && occursin(r"^`{3,}@example", codefence.first) && isdocumenter(config)
                write(iocode, "; continued = true")
            end
            write(iocode, '\n')
            # filter out trailing #hide unless code is executed by Documenter
            execute = config["execute"]::Bool
            write_hide = isdocumenter(config) && !execute
            write_line(line) = write_hide || !endswith(line, "#hide")
            for line in chunk.lines
                write_line(line) && write(iocode, line, '\n')
            end
            if write_hide && REPL.ends_with_semicolon(chunk.lines[end])
                write(iocode, "nothing #hide\n")
            end
            write(iocode, codefence.second, '\n')
            any(write_line, chunk.lines) && write(iomd, seekstart(iocode))
            if execute
                cd(config["literate_outputdir"]) do
                    execute_markdown!(iomd, sb, join(chunk.lines, '\n'), outputdir;
                                      inputfile=config["literate_inputfile"],
                                      fake_source=config["literate_outputfile"],
                                      flavor=config["flavor"],
                                      image_formats=config["image_formats"],
                                      file_prefix="$(config["name"])-$(chunknum)",
                    )
                end
            end
        end
        write(iomd, '\n') # add a newline between each chunk
    end

    # custom post-processing from user
    content = config["postprocess"](String(take!(iomd)))

    # write to file
    outputfile = write_result(content, config)
    return outputfile
end

function execute_markdown!(io::IO, sb::Module, block::String, outputdir;
                           inputfile::String, fake_source::String,
                           flavor::AbstractFlavor, image_formats::Vector, file_prefix::String)
    # TODO: Deal with explicit display(...) calls
    r, str, _ = execute_block(sb, block; inputfile=inputfile, fake_source=fake_source)
    # issue #101: consecutive codefenced blocks need newline
    # issue #144: quadruple backticks allow for triple backticks in the output
    plain_fence = "\n````\n" =>  "\n````"
    if r !== nothing && !REPL.ends_with_semicolon(block)
        if (flavor isa FranklinFlavor || flavor isa DocumenterFlavor) &&
           Base.invokelatest(showable, MIME("text/html"), r)
            htmlfence = flavor isa FranklinFlavor ? ("~~~" => "~~~") : ("```@raw html" => "```")
            write(io, "\n", htmlfence.first, "\n")
            Base.invokelatest(show, io, MIME("text/html"), r)
            write(io, "\n", htmlfence.second, "\n")
            return
        end
        for (mime, ext) in image_formats
            if Base.invokelatest(showable, mime, r)
                file = file_prefix * ext
                open(joinpath(outputdir, file), "w") do io
                    Base.invokelatest(show, io, mime, r)
                end
                write(io, "![](", file, ")\n")
                return
            end
        end
        if Base.invokelatest(showable, MIME("text/markdown"), r)
            write(io, '\n')
            Base.invokelatest(show, io, MIME("text/markdown"), r)
            write(io, '\n')
            return
        end
        # fallback to text/plain
        write(io, plain_fence.first)
        Base.invokelatest(show, io, "text/plain", r)
        write(io, plain_fence.second, '\n')
        return
    elseif !isempty(str)
        write(io, plain_fence.first, str, plain_fence.second, '\n')
        return
    end
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
    Literate.notebook(inputfile, outputdir=pwd(); config::AbstractDict=Dict(), kwargs...)

Generate a notebook from `inputfile` and write the result to `outputdir`.

See the manual section on [Configuration](@ref) for documentation
of possible configuration with `config` and other keyword arguments.
"""
function notebook(inputfile, outputdir=pwd(); config::AbstractDict=Dict(), kwargs...)
    # preprocessing and parsing
    chunks, config =
        preprocessor(inputfile, outputdir; user_config=config, user_kwargs=kwargs, type=:nb)

    # create the notebook
    nb = jupyter_notebook(chunks, config)

    # write to file
    outputfile = write_result(nb, config; print = (io, c)->JSON.print(io, c, 1))
    return outputfile
end

function jupyter_notebook(chunks, config)
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
        if chunktype == "code"
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
            cd(config["literate_outputdir"]) do
                nb = execute_notebook(nb; inputfile=config["literate_inputfile"],
                                          fake_source=config["literate_outputfile"])
            end
        catch err
            @error "error when executing notebook based on input file: " *
                   "`$(Base.contractuser(config["literate_inputfile"]))`"
            rethrow(err)
        end
    end
    return nb
end

function execute_notebook(nb; inputfile::String, fake_source::String)
    sb = sandbox()
    execution_count = 0
    for cell in nb["cells"]
        cell["cell_type"] == "code" || continue
        execution_count += 1
        cell["execution_count"] = execution_count
        block = join(cell["source"])
        r, str, display_dicts = execute_block(sb, block; inputfile=inputfile, fake_source=fake_source)

        # str should go into stream
        if !isempty(str)
            stream = Dict{String,Any}()
            stream["output_type"] = "stream"
            stream["name"] = "stdout"
            stream["text"] = collect(Any, eachline(IOBuffer(String(str)), keep = true))
            push!(cell["outputs"], stream)
        end

        # Some mimes need to be split into vectors of lines instead of a single string
        # TODO: Seems like text/plain and text/latex are also split now, but not doing
        # it seems to work fine. Leave for now.
        function split_mime(dict)
            for mime in ("image/svg+xml", "text/html")
                if haskey(dict, mime)
                    dict[mime] = collect(Any, eachline(IOBuffer(dict[mime]), keep = true))
                end
            end
            return dict
        end

        # Any explicit calls to display(...)
        for dict in display_dicts
            display_data = Dict{String,Any}()
            display_data["output_type"] = "display_data"
            display_data["metadata"] = Dict()
            display_data["data"] = split_mime(dict)
            push!(cell["outputs"], display_data)
        end

        # check if ; is used to suppress output
        r = REPL.ends_with_semicolon(block) ? nothing : r

        # r should go into execute_result
        if r !== nothing
            execute_result = Dict{String,Any}()
            execute_result["output_type"] = "execute_result"
            execute_result["metadata"] = Dict()
            execute_result["execution_count"] = execution_count
            dict = Base.invokelatest(IJulia.display_dict, r)
            execute_result["data"] = split_mime(dict)
            push!(cell["outputs"], execute_result)
        end
    end
    return nb
end

# Create a sandbox module for evaluation
function sandbox()
    m = Module(gensym())
    # eval(expr) is available in the REPL (i.e. Main) so we emulate that for the sandbox
    Core.eval(m, :(eval(x) = Core.eval($m, x)))
    # modules created with Module() does not have include defined
    # abspath is needed since this will call `include_relative`
    Core.eval(m, :(include(x) = Base.include($m, abspath(x))))
    return m
end

# Capture display for notebooks
struct LiterateDisplay <: AbstractDisplay
    data::Vector
    LiterateDisplay() = new([])
end
function Base.display(ld::LiterateDisplay, x)
    push!(ld.data, Base.invokelatest(IJulia.display_dict, x))
    return nothing
end
# TODO: Problematic to accept mime::MIME here?
function Base.display(ld::LiterateDisplay, mime::MIME, x)
    r = Base.invokelatest(IJulia.limitstringmime, mime, x)
    display_dicts = Dict{String,Any}(string(mime) => r)
    # TODO: IJulia does this part below for unknown mimes
    # if istextmime(mime)
    #     display_dicts["text/plain"] = r
    # end
    push!(ld.data, display_dicts)
    return nothing
end

# Execute a code-block in a module and capture stdout/stderr and the result
function execute_block(sb::Module, block::String; inputfile::String, fake_source::String)
    @debug """execute_block($sb, block)
    ```
    $(block)
    ```
    """
    # Push a capturing display on the displaystack
    disp = LiterateDisplay()
    pushdisplay(disp)
    # We use the following fields of the object returned by IOCapture.capture:
    #  - c.value: return value of the do-block (or the error object, if it throws)
    #  - c.error: set to `true` if the do-block throws an error
    #  - c.output: combined stdout and stderr
    # `rethrow = Union{}` means that we try-catch all the exceptions thrown in the do-block
    # and return them via the return value (they get handled below).
    c = IOCapture.capture(rethrow = Union{}) do
        include_string(sb, block, fake_source)
    end
    popdisplay(disp) # IOCapture.capture has a try-catch so should always end up here
    if c.error
        error("""
             $(sprint(showerror, c.value))
             when executing the following code block from inputfile `$(Base.contractuser(inputfile))`

             ```julia
             $block
             ```
             """)
    end
    return c.value, c.output, disp.data
end

end # module
