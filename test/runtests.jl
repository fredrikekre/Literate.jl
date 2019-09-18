import Literate
import Literate: Chunk, MDChunk, CodeChunk
using Test

# compare content of two parsed chunk vectors
function compare_chunks(chunks1, chunks2)
    @test length(chunks1) == length(chunks2)
    for (c1, c2) in zip(chunks1, chunks2)
        # compare types
        @test typeof(c1) == typeof(c2)
        # test that the chunk don't start or end with empty line
        @test first(c1.lines) != "" && first(c1.lines) != ("" => "")
        @test first(c2.lines) != "" && first(c2.lines) != ("" => "")
        @test last(c1.lines) != "" && last(c1.lines) != ("" => "")
        @test last(c2.lines) != "" && last(c2.lines) != ("" => "")
        # compare content
        for (l1, l2) in zip(c1.lines, c2.lines)
            @test l1 == l2
        end
        # test continued code
        if isa(c1, CodeChunk)
            @test c1.continued == c2.continued
        end
    end
end

@testset "Literate.parse" begin
    content = """
    # Line 1
    Line 2
    # Line 3
    #
    # Line 5
    Line 6

    Line 8
    # Line 9
    #-
    # Line 11
    Line 12
    #-
    Line 14
    # Line 15
    #-----------------
    # Line 17
    Line 18
    #-----------------
    Line 20
    # Line 21
    Line 22
        Line 23
    Line 24
    #-
    Line 26
        Line 27
    #+
    Line 29
    #-
    Line 31
        Line 32
    # Line 33
    #+
    Line 34
    #-
    Line 36
    #+
        Line 38
    #+
    Line 40
    #-
    Line 42
        Line 43
    # Line 44
    #+
        Line 45
    # Line 46
    #+
    Line 47
    # Line 48
    #Line 49
    Line 50
    #
    #
    # Line 53
    #
    #
    #-
    ## Line 57
    Line 58
    ## Line 59
    ##Line 60
    #-
        # Line 62
        # # Line 63
    Line 64
        ## Line 65
        Line 66
    Line 67
    #-
    #
    #-
        #
    #-
    ## Line 73
    ##
    ## Line 75
    #-
        ## Line 77
        ##
        ## Line 79
    """
    expected_chunks = Chunk[
        MDChunk(["" => "Line 1"]),
        CodeChunk(["Line 2"], false),
        MDChunk(["" => "Line 3", "" => "","" => "Line 5"]),
        CodeChunk(["Line 6", "","Line 8"], false),
        MDChunk(["" => "Line 9"]),
        MDChunk(["" => "Line 11"]),
        CodeChunk(["Line 12"], false),
        CodeChunk(["Line 14"], false),
        MDChunk(["" => "Line 15"]),
        MDChunk(["" => "Line 17"]),
        CodeChunk(["Line 18"], false),
        CodeChunk(["Line 20"], false),
        MDChunk(["" => "Line 21"]),
        CodeChunk(["Line 22", "    Line 23", "Line 24"], false),
        CodeChunk(["Line 26", "    Line 27"], true),
        CodeChunk(["Line 29"], false),
        CodeChunk(["Line 31", "    Line 32"], true),
        MDChunk(["" => "Line 33"]),
        CodeChunk(["Line 34"], false),
        CodeChunk(["Line 36"], true),
        CodeChunk(["    Line 38"], true),
        CodeChunk(["Line 40"], false),
        CodeChunk(["Line 42", "    Line 43"], true),
        MDChunk(["" => "Line 44"]),
        CodeChunk(["    Line 45"], true),
        MDChunk(["" => "Line 46"]),
        CodeChunk(["Line 47"], false),
        MDChunk(["" => "Line 48"]),
        CodeChunk(["#Line 49", "Line 50"], false),
        MDChunk(["" => "Line 53"]),
        CodeChunk(["# Line 57", "Line 58", "# Line 59", "##Line 60"], false),
        MDChunk(["    " => "Line 62", "    " => "# Line 63"]),
        CodeChunk(["Line 64", "    # Line 65", "    Line 66", "Line 67"], false),
        CodeChunk(["# Line 73", "#", "# Line 75"], false),
        CodeChunk(["    # Line 77", "    #", "    # Line 79"], false),
        ]
    parsed_chunks = Literate.parse(content)
    compare_chunks(parsed_chunks, expected_chunks)

    # test leading/trailing whitespace removal
    io = IOBuffer()
    iows = IOBuffer()
    for c in expected_chunks
        if isa(c, CodeChunk)
            foreach(x-> println(io,   x), c.lines)
            foreach(x-> println(iows, x, "  "), c.lines)
        else
            foreach(x -> println(io,   "# ", x), c.lines)
            foreach(x -> println(iows, "# ", x, "  "), c.lines)
        end
        println(io,   "#-")
        println(iows, "#-")
        foreach(x -> println(iows), 1:rand(2:5))
    end

    compare_chunks(Literate.parse(String(take!(io))), Literate.parse(String(take!(iows))))

end # testset parser

content = """
    # # [Example](@id example-id)
    # [foo](@ref), [bar](@ref bbaarr)
    x = 1
    #md # Only markdown
    #md x + 1
    #!md # Not markdown
    #!md x * 1
    #nb # Only notebook
    #nb x + 2
    #!nb # Not notebook
    #!nb x * 2
    #jl # Only script
    #jl x + 3
    #!jl # Not script
    #!jl x * 3
    #src # Source code only
    Source code only          #src
    ## # Comment
    ## another comment
    #-
    for i in 1:10
        print(i)
    # some markdown in a code block
    #+
    end
    # name: @__NAME__
    # Link to repo root: @__REPO_ROOT_URL__/file.jl
    # Link to nbviewer: @__NBVIEWER_ROOT_URL__/file.jl
    # Link to binder: @__BINDER_ROOT_URL__/file.jl
    ## name: @__NAME__
    ## Link to repo root: @__REPO_ROOT_URL__/file.jl
    ## Link to nbviewer: @__NBVIEWER_ROOT_URL__/file.jl
    ## Link to binder: @__BINDER_ROOT_URL__/file.jl

    # PLACEHOLDER1
    # PLACEHOLDER2
    ## PLACEHOLDER3
    ## PLACEHOLDER4

    # Some math:
    # ```math
    # \\int f(x) dx
    # ```
    #-
        # Indented markdown
    for i in 1:10
        # Indented markdown
    #+
        ## Indented comment
    end

    #nb # A notebook cell with special metadata
    #nb %% Meta1 {"meta": "data"}
    #nb 1+1
    #nb #-
    #nb # A explicit code notebook cell
    #nb #-
    #nb %% [code]
    #nb 1+2
    #nb #-
    #nb # %% [markdown] {"meta": "data"}
    #nb # # Explicit markdown cell with metadata
    """

const expansion_warning = get(ENV, "HAS_JOSH_K_SEAL_OF_APPROVAL", "") == "true" ? () : (:warn, r"expansion of")

@testset "Literate.script" begin
    mktempdir(@__DIR__) do sandbox
        cd(sandbox) do
            # write content to inputfile
            inputfile = "inputfile.jl"
            write(inputfile, content)
            outdir = mktempdir(pwd())

            # test defaults
            withenv("TRAVIS_REPO_SLUG" => "fredrikekre/Literate.jl",
                    "TRAVIS_TAG" => "v1.2.0",
                    "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true") do
                Literate.script(inputfile, outdir)
            end
            expected_script = """
            x = 1

            x * 1

            x * 2

            x + 3
            # # Comment
            # another comment

            for i in 1:10
                print(i)

            end

            # name: inputfile
            # Link to repo root: https://github.com/fredrikekre/Literate.jl/blob/master/file.jl
            # Link to nbviewer: https://nbviewer.jupyter.org/github/fredrikekre/Literate.jl/blob/gh-pages/v1.2.0/file.jl
            # Link to binder: https://mybinder.org/v2/gh/fredrikekre/Literate.jl/gh-pages?filepath=v1.2.0/file.jl

            # PLACEHOLDER3
            # PLACEHOLDER4

            for i in 1:10

                # Indented comment
            end

            # This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

            """
            script = read(joinpath(outdir, "inputfile.jl"), String)
            @test script == expected_script

            # no tag -> latest directory
            withenv("TRAVIS_REPO_SLUG" => "fredrikekre/Literate.jl",
                    "TRAVIS_TAG" => "",
                    "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true") do
                Literate.script(inputfile, outdir)
            end
            script = read(joinpath(outdir, "inputfile.jl"), String)
            @test occursin("fredrikekre/Literate.jl/blob/gh-pages/dev/", script)

            # building under DocumentationGenerator.jl
            withenv("DOCUMENTATIONGENERATOR" => "true",
                    "DOCUMENTATIONGENERATOR_BASE_URL" => "pkg.julialang.org/docs/Literate/XPnWG/1.2.0") do
                @test_logs((:warn, r"mybinder.org"), match_mode=:any,
                    Literate.script(inputfile, outdir))
            end
            script = read(joinpath(outdir, "inputfile.jl"), String)
            @test occursin("jupyter.org/urls/pkg.julialang.org/docs/Literate/XPnWG/1.2.0/file.jl", script)
            @test_broken occursin("https://github.com/fredrikekre/Literate.jl/blob/master/file.jl", script)

            # pre- and post-processing
            @test_logs(expansion_warning, match_mode=:any,
                Literate.script(inputfile, outdir,
                    preprocess = x -> replace(x, "PLACEHOLDER3" => "3REDLOHECALP"),
                    postprocess = x -> replace(x, "PLACEHOLDER4" => "4REDLOHECALP")))
            script = read(joinpath(outdir, "inputfile.jl"), String)
            @test !occursin("PLACEHOLDER1", script)
            @test !occursin("PLACEHOLDER2", script)
            @test !occursin("PLACEHOLDER3", script)
            @test !occursin("PLACEHOLDER4", script)
            @test occursin("3REDLOHECALP", script)
            @test occursin("4REDLOHECALP", script)

            # name
            @test_logs(expansion_warning, match_mode=:any,
                Literate.script(inputfile, outdir, name = "foobar"))
            script = read(joinpath(outdir, "foobar.jl"), String)
            @test occursin("name: foobar", script)
            @test !occursin("name: inputfile", script)
            @test !occursin("name: @__NAME__", script)

            # keep_comments
            @test_logs(expansion_warning, match_mode=:any,
                Literate.script(inputfile, outdir, keep_comments = true))
            script = read(joinpath(outdir, "inputfile.jl"), String)
            @test occursin("# # Example", script)
            @test occursin("# foo, bar", script)
            @test occursin("# \\int f(x) dx", script)

            # verify that inputfile exists
            @test_throws ArgumentError Literate.script("nonexistent.jl", outdir)
        end
    end
end

@testset "Literate.markdown" begin
    mktempdir(@__DIR__) do sandbox
        cd(sandbox) do
            # write content to inputfile
            inputfile = "inputfile.jl"
            write(inputfile, content)
            outdir = mktempdir(pwd())

            # test defaults
            withenv("TRAVIS_REPO_SLUG" => "fredrikekre/Literate.jl",
                    "TRAVIS_TAG" => "v1.2.0",
                    "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true") do
                Literate.markdown(inputfile, outdir)
            end
            expected_markdown = """
            ```@meta
            EditURL = "https://github.com/fredrikekre/Literate.jl/blob/master/test/$(basename(sandbox))/inputfile.jl"
            ```

            # [Example](@id example-id)
            [foo](@ref), [bar](@ref bbaarr)

            ```@example inputfile
            x = 1
            ```

            Only markdown

            ```@example inputfile
            x + 1
            ```

            Not notebook

            ```@example inputfile
            x * 2
            ```

            Not script

            ```@example inputfile
            x * 3
            # # Comment
            # another comment
            ```

            ```@example inputfile; continued = true
            for i in 1:10
                print(i)
            ```

            some markdown in a code block

            ```@example inputfile
            end
            ```

            name: inputfile
            Link to repo root: https://github.com/fredrikekre/Literate.jl/blob/master/file.jl
            Link to nbviewer: https://nbviewer.jupyter.org/github/fredrikekre/Literate.jl/blob/gh-pages/v1.2.0/file.jl
            Link to binder: https://mybinder.org/v2/gh/fredrikekre/Literate.jl/gh-pages?filepath=v1.2.0/file.jl

            ```@example inputfile
            # name: inputfile
            # Link to repo root: https://github.com/fredrikekre/Literate.jl/blob/master/file.jl
            # Link to nbviewer: https://nbviewer.jupyter.org/github/fredrikekre/Literate.jl/blob/gh-pages/v1.2.0/file.jl
            # Link to binder: https://mybinder.org/v2/gh/fredrikekre/Literate.jl/gh-pages?filepath=v1.2.0/file.jl
            ```

            PLACEHOLDER1
            PLACEHOLDER2

            ```@example inputfile
            # PLACEHOLDER3
            # PLACEHOLDER4
            ```

            Some math:
            ```math
            \\int f(x) dx
            ```

            Indented markdown

            ```@example inputfile; continued = true
            for i in 1:10
            ```

            Indented markdown

            ```@example inputfile
                # Indented comment
            end
            ```

            *This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

            """
            markdown = read(joinpath(outdir, "inputfile.md"), String)
            @test markdown == expected_markdown

            # no tag -> latest directory
            withenv("TRAVIS_REPO_SLUG" => "fredrikekre/Literate.jl",
                    "TRAVIS_TAG" => "",
                    "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true") do
                Literate.markdown(inputfile, outdir)
            end
            markdown = read(joinpath(outdir, "inputfile.md"), String)
            @test occursin("fredrikekre/Literate.jl/blob/gh-pages/dev/", markdown)

            # building under DocumentationGenerator.jl
            withenv("DOCUMENTATIONGENERATOR" => "true",
                    "DOCUMENTATIONGENERATOR_BASE_URL" => "pkg.julialang.org/docs/Literate/XPnWG/1.2.0") do
                @test_logs((:warn, r"mybinder.org"), match_mode=:any,
                    Literate.markdown(inputfile, outdir))
            end
            markdown = read(joinpath(outdir, "inputfile.md"), String)
            @test occursin("jupyter.org/urls/pkg.julialang.org/docs/Literate/XPnWG/1.2.0/file.jl", markdown)
            @test_broken occursin("https://github.com/fredrikekre/Literate.jl/blob/master/file.jl", markdown)

            # pre- and post-processing
            @test_logs(expansion_warning, match_mode=:any,
                Literate.markdown(inputfile, outdir,
                    preprocess = x -> replace(replace(x, "PLACEHOLDER1" => "1REDLOHECALP"), "PLACEHOLDER3" => "3REDLOHECALP"),
                    postprocess = x -> replace(replace(x, "PLACEHOLDER2" => "2REDLOHECALP"), "PLACEHOLDER4" => "4REDLOHECALP")))
            markdown = read(joinpath(outdir, "inputfile.md"), String)
            @test !occursin("PLACEHOLDER1", markdown)
            @test !occursin("PLACEHOLDER2", markdown)
            @test !occursin("PLACEHOLDER3", markdown)
            @test !occursin("PLACEHOLDER4", markdown)
            @test occursin("1REDLOHECALP", markdown)
            @test occursin("2REDLOHECALP", markdown)
            @test occursin("3REDLOHECALP", markdown)
            @test occursin("4REDLOHECALP", markdown)

            # documenter = false
            @test_logs(expansion_warning, match_mode=:any,
                Literate.markdown(inputfile, outdir, documenter = false))
            markdown = read(joinpath(outdir, "inputfile.md"), String)
            @test occursin("```julia", markdown)
            @test !occursin("```@example", markdown)
            @test !occursin("continued = true", markdown)
            @test !occursin("EditURL", markdown)

            # codefence
            @test_logs(expansion_warning, match_mode=:any,
                Literate.markdown(inputfile, outdir, codefence = "```c" => "```"))
            markdown = read(joinpath(outdir, "inputfile.md"), String)
            @test occursin("```c", markdown)
            @test !occursin("```@example", markdown)
            @test !occursin("```julia", markdown)

            # name
            @test_logs(expansion_warning, match_mode=:any,
                Literate.markdown(inputfile, outdir, name = "foobar"))
            markdown = read(joinpath(outdir, "foobar.md"), String)
            @test occursin("```@example foobar", markdown)
            @test !occursin("```@example inputfile", markdown)
            @test occursin("name: foobar", markdown)
            @test !occursin("name: inputfile", markdown)
            @test !occursin("name: @__NAME__", markdown)

            # verify that inputfile exists
            @test_throws ArgumentError Literate.markdown("nonexistent.jl", outdir)
        end
    end
end

@testset "Literate.notebook" begin
    mktempdir(@__DIR__) do sandbox
        cd(sandbox) do
            # write content to inputfile
            inputfile = "inputfile.jl"
            write(inputfile, content)
            outdir = mktempdir(pwd())

            # test defaults
            withenv("TRAVIS_REPO_SLUG" => "fredrikekre/Literate.jl",
                    "TRAVIS_TAG" => "v1.2.0",
                    "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true") do
                Literate.notebook(inputfile, outdir, execute = false)
            end
            expected_cells = rstrip.((
            """
             "cells": [
            """,

            """
               "source": [
                "# Example\\n",
                "foo, bar"
               ]
            """,

            """
               "source": [
                "x = 1"
               ]
            """,

            """
               "source": [
                "Not markdown"
               ],
            """,

            """
               "source": [
                "x * 1"
               ],
            """,

            """
               "source": [
                "Only notebook"
               ]
            """,

            """
               "source": [
                "x + 2"
               ]
            """,

            """
               "source": [
                "Not script"
               ],
            """,

            """
               "source": [
                "x * 3\\n",
                "# # Comment\\n",
                "# another comment"
               ],
            """,

            """
               "source": [
                "for i in 1:10\\n",
                "    print(i)\\n",
                "# some markdown in a code block\\n",
                "end"
               ]
            """,

            """
               "source": [
                "name: inputfile\\n",
                "Link to repo root: https://github.com/fredrikekre/Literate.jl/blob/master/file.jl\\n",
                "Link to nbviewer: https://nbviewer.jupyter.org/github/fredrikekre/Literate.jl/blob/gh-pages/v1.2.0/file.jl\\n",
                "Link to binder: https://mybinder.org/v2/gh/fredrikekre/Literate.jl/gh-pages?filepath=v1.2.0/file.jl"
               ]
            """,

            """
               "source": [
                "# name: inputfile\\n",
                "# Link to repo root: https://github.com/fredrikekre/Literate.jl/blob/master/file.jl\\n",
                "# Link to nbviewer: https://nbviewer.jupyter.org/github/fredrikekre/Literate.jl/blob/gh-pages/v1.2.0/file.jl\\n",
                "# Link to binder: https://mybinder.org/v2/gh/fredrikekre/Literate.jl/gh-pages?filepath=v1.2.0/file.jl"
               ]
            """,

            """
               "source": [
                "PLACEHOLDER1\\n",
                "PLACEHOLDER2"
               ]
            """,

            """
               "source": [
                "# PLACEHOLDER3\\n",
                "# PLACEHOLDER4"
               ]
            """,

            """
               "source": [
                "Some math:\\n",
                "\$\$\\n",
                "\\\\int f(x) dx\\n",
                "\$\$"
               ]
            """,

            """
               "source": [
                "Indented markdown"
               ]
            """,

            """
               "source": [
                "for i in 1:10\\n",
                "    # Indented markdown\\n",
                "    # Indented comment\\n",
                "end"
               ]
            """,

            """
               "metadata": {
                "meta": "data"
               }
            """,

            """
               "source": [
                "*This notebook was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*"
               ]
            """))

            notebook = read(joinpath(outdir, "inputfile.ipynb"), String)

            lastidx = 1
            for cell in expected_cells
                idx = findnext(cell, notebook, lastidx)
                @test idx !== nothing
                lastidx = nextind(notebook, last(idx))
            end
            # test some of the required metadata
            for metadata in (" \"nbformat\": ", " \"nbformat_minor\": ", " \"metadata\": {", "  \"language_info\": {",
                "   \"file_extension\": \".jl\"", "   \"mimetype\": \"application/julia\"",
                "   \"name\": \"julia\"", "   \"version\": ", "  \"kernelspec\": {",
                "   \"name\": \"julia-", "   \"display_name\": \"Julia ", "   \"language\": \"julia\"")
                @test occursin(metadata, notebook)
            end

            # no tag -> latest directory
            withenv("TRAVIS_REPO_SLUG" => "fredrikekre/Literate.jl",
                    "TRAVIS_TAG" => "",
                    "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true") do
                Literate.notebook(inputfile, outdir, execute = false)
            end
            notebook = read(joinpath(outdir, "inputfile.ipynb"), String)
            @test occursin("fredrikekre/Literate.jl/blob/gh-pages/dev/", notebook)

            # building under DocumentationGenerator.jl
            withenv("DOCUMENTATIONGENERATOR" => "true",
                    "DOCUMENTATIONGENERATOR_BASE_URL" => "pkg.julialang.org/docs/Literate/XPnWG/1.2.0") do
                @test_logs((:warn, r"mybinder.org"), match_mode=:any,
                    Literate.notebook(inputfile, outdir, execute = false))
            end
            notebook = read(joinpath(outdir, "inputfile.ipynb"), String)
            @test occursin("jupyter.org/urls/pkg.julialang.org/docs/Literate/XPnWG/1.2.0/file.jl", notebook)
            @test_broken occursin("https://github.com/fredrikekre/Literate.jl/blob/master/file.jl", notebook)

            # pre- and post-processing
            function post(nb)
                for cell in nb["cells"]
                    for i in eachindex(cell["source"])
                        cell["source"][i] = replace(cell["source"][i], "PLACEHOLDER2" => "2REDLOHECALP")
                        cell["source"][i] = replace(cell["source"][i], "PLACEHOLDER4" => "4REDLOHECALP")
                    end
                end
                return nb
            end
            @test_logs(expansion_warning, match_mode=:any,
                Literate.notebook(inputfile, outdir, execute = false,
                    preprocess = x -> replace(replace(x, "PLACEHOLDER1" => "1REDLOHECALP"), "PLACEHOLDER3" => "3REDLOHECALP"),
                    postprocess = post))
            notebook = read(joinpath(outdir, "inputfile.ipynb"), String)
            @test !occursin("PLACEHOLDER1", notebook)
            @test !occursin("PLACEHOLDER2", notebook)
            @test !occursin("PLACEHOLDER3", notebook)
            @test !occursin("PLACEHOLDER4", notebook)
            @test occursin("1REDLOHECALP", notebook)
            @test occursin("2REDLOHECALP", notebook)
            @test occursin("3REDLOHECALP", notebook)
            @test occursin("4REDLOHECALP", notebook)

            # documenter = false
            @test_logs(expansion_warning, match_mode=:any,
                Literate.notebook(inputfile, outdir, documenter = false, execute = false))
            notebook = read(joinpath(outdir, "inputfile.ipynb"), String)
            @test occursin("# [Example](@id example-id", notebook)
            @test occursin("[foo](@ref), [bar](@ref bbaarr)", notebook)

            # name
            @test_logs(expansion_warning, match_mode=:any,
                Literate.notebook(inputfile, outdir, name = "foobar", execute = false))
            notebook = read(joinpath(outdir, "foobar.ipynb"), String)
            @test occursin("name: foobar", notebook)
            @test !occursin("name: inputfile", notebook)
            @test !occursin("name: @__NAME__", notebook)

            # execute = true
            @test_logs(expansion_warning, match_mode=:any,
                Literate.notebook(inputfile, outdir))
            expected_outputs = rstrip.((
            """
             "cells": [
            """,

            """
                 "data": {
                  "text/plain": "3"
                 },
            """,

            """
                 "text": [
                  "12345678910"
                 ]
            """))

            notebook = read(joinpath(outdir, "inputfile.ipynb"), String)

            lastidx = 1
            for out in expected_outputs
                idx = findnext(out, notebook, lastidx)
                @test idx !== nothing
                lastidx = nextind(notebook, last(idx))
            end

            # issue #31
            write(inputfile, "include(\"issue31.jl\")")
            write(joinpath(outdir, "issue31.jl"), "10 + 21")
            Literate.notebook(inputfile, outdir)
            notebook = read(joinpath(outdir, "inputfile.ipynb"), String)
            @test occursin("\"data\": {\n      \"text/plain\": \"31\"\n     }", notebook)

            # test error when executing notebook
            write(inputfile, "for i in 1:10\n    println(i)")
            r = @test_logs((:error, r"error when executing"), match_mode=:any,
                try
                    Literate.notebook(inputfile, outdir)
                catch err
                    err
                end)
            @test isa(r, ErrorException)
            @test occursin("when executing the following code block", r.msg)

            # verify that inputfile exists
            @test_throws ArgumentError Literate.notebook("nonexistent.jl", outdir)

            # world time problem with `IJulia.display_dict`
            write(inputfile, """
            struct VegaLiteRenderable end
            Base.show(io::IO, ::MIME"application/vnd.vegalite.v2+json", ::VegaLiteRenderable) =
                write(io, \"\"\"
            {"encoding":{"x":{"field":"x","type":"quantitative"},"y":{"field":"y","type":"quantitative"}},"data":{"values":[{"x":1,"y":1},{"x":2,"y":3},{"x":3,"y":2}]},"mark":"point"}
            \"\"\")
            Base.Multimedia.istextmime(::MIME{Symbol("application/vnd.vegalite.v2+json")}) = true
            VegaLiteRenderable()
            """)
            Literate.notebook(inputfile, outdir)
            notebook = read(joinpath(outdir, "inputfile.ipynb"), String)
            @test occursin("\"application/vnd.vegalite.v2+json\":", notebook)
        end
    end
end
