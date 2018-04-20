import Literate
import Literate: Chunk, MDChunk, CodeChunk
using Compat.Test

# compare content of two parsed chunk vectors
function compare_chunks(chunks1, chunks2)
    @test length(chunks1) == length(chunks2)
    for (c1, c2) in zip(chunks1, chunks2)
        # compare types
        @test typeof(c1) == typeof(c2)
        # test that no chunk start or end with ""
        @test !isempty(first(c1.lines)); @test !isempty(last(c1.lines))
        @test !isempty(first(c2.lines)); @test !isempty(last(c2.lines))
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
    #' Line 1
    Line 2
    #' Line 3
    #'
    #' Line 5
    Line 6

    Line 8
    #' Line 9
    #-
    #' Line 11
    Line 12
    #-
    Line 14
    #' Line 15
    #-----------------
    #' Line 17
    Line 18
    #-----------------
    Line 20
    #' Line 21
    Line 22
        Line 23
    Line 24
    #-
    Line 26
        Line 27
    #-
    Line 29
    #-
    Line 31
        Line 32
    #' Line 33
    Line 34
    #-
    Line 36
    #-
        Line 38
    #-
    Line 40
    #-
    Line 42
        Line 43
    #' Line 44
        Line 45
    #' Line 46
    Line 47
    #' Line 48
    #Line 49
    Line 50
    #'
    #'
    #' Line 53
    #'
    #'
    """
    expected_chunks = Chunk[
        MDChunk(["Line 1"]),
        CodeChunk(["Line 2"], false),
        MDChunk(["Line 3", "","Line 5"]),
        CodeChunk(["Line 6", "","Line 8"], false),
        MDChunk(["Line 9"]),
        MDChunk(["Line 11"]),
        CodeChunk(["Line 12"], false),
        CodeChunk(["Line 14"], false),
        MDChunk(["Line 15"]),
        MDChunk(["Line 17"]),
        CodeChunk(["Line 18"], false),
        CodeChunk(["Line 20"], false),
        MDChunk(["Line 21"]),
        CodeChunk(["Line 22", "    Line 23", "Line 24"], false),
        CodeChunk(["Line 26", "    Line 27"], true),
        CodeChunk(["Line 29"], false),
        CodeChunk(["Line 31", "    Line 32"], true),
        MDChunk(["Line 33"]),
        CodeChunk(["Line 34"], false),
        CodeChunk(["Line 36"], true),
        CodeChunk(["    Line 38"], true),
        CodeChunk(["Line 40"], false),
        CodeChunk(["Line 42", "    Line 43"], true),
        MDChunk(["Line 44"]),
        CodeChunk(["    Line 45"], true),
        MDChunk(["Line 46"]),
        CodeChunk(["Line 47"], false),
        MDChunk(["Line 48"]),
        CodeChunk(["#Line 49", "Line 50"], false),
        MDChunk(["Line 53"]),
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
            foreach(x -> println(io,   "#' ", x), c.lines)
            foreach(x -> println(iows, "#' ", x, "  "), c.lines)
        end
        println(io,   "#-")
        println(iows, "#-")
        foreach(x -> println(iows), 1:rand(2:5))
    end

    compare_chunks(Literate.parse(String(take!(io))), Literate.parse(String(take!(iows))))

end # testset parser

content = """
    #' # [Example](@id example-id)
    #' [foo](@ref), [bar](@ref bbaarr)
    x = 1
    #md #' Only markdown
    #md x + 1
    #nb #' Only notebook
    #nb x + 2
    #jl #' Only script
    #jl x + 3
    #' Only script too  #jl
    x + 4               #jl
    # #' Comment
    # another comment
    #-
    for i in 1:10
        print(i)
    #' some markdown in a code block
    end
    #' name: @__NAME__
    #' Link to repo root: @__REPO_ROOT_URL__
    #' Link to nbviewer: @__NBVIEWER_ROOT_URL__
    # name: @__NAME__
    # Link to repo root: @__REPO_ROOT_URL__
    # Link to nbviewer: @__NBVIEWER_ROOT_URL__

    #' PLACEHOLDER1
    #' PLACEHOLDER2
    # PLACEHOLDER3
    # PLACEHOLDER4

    #' Some math:
    #' ```math
    #' \\int f(x) dx
    #' ```
    """

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

            x + 3

            x + 4
            # #' Comment
            # another comment

            for i in 1:10
                print(i)

            end

            # name: inputfile
            # Link to repo root: https://github.com/fredrikekre/Literate.jl/blob/master/
            # Link to nbviewer: https://nbviewer.jupyter.org/github/fredrikekre/Literate.jl/blob/gh-pages/v1.2.0/

            # PLACEHOLDER3
            # PLACEHOLDER4

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
            @test contains(script, "fredrikekre/Literate.jl/blob/gh-pages/latest/")

            # pre- and post-processing
            Literate.script(inputfile, outdir,
                preprocess = x -> replace(x, "PLACEHOLDER3" => "3REDLOHECALP"),
                postprocess = x -> replace(x, "PLACEHOLDER4" => "4REDLOHECALP"))
            script = read(joinpath(outdir, "inputfile.jl"), String)
            @test !contains(script, "PLACEHOLDER1")
            @test !contains(script, "PLACEHOLDER2")
            @test !contains(script, "PLACEHOLDER3")
            @test !contains(script, "PLACEHOLDER4")
            @test contains(script, "3REDLOHECALP")
            @test contains(script, "4REDLOHECALP")

            # name
            Literate.script(inputfile, outdir, name = "foobar")
            script = read(joinpath(outdir, "foobar.jl"), String)
            @test contains(script, "name: foobar")
            @test !contains(script, "name: inputfile")
            @test !contains(script, "name: @__NAME__")
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
            # #' Comment
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
            Link to repo root: https://github.com/fredrikekre/Literate.jl/blob/master/
            Link to nbviewer: https://nbviewer.jupyter.org/github/fredrikekre/Literate.jl/blob/gh-pages/v1.2.0/

            ```@example inputfile
            # name: inputfile
            # Link to repo root: https://github.com/fredrikekre/Literate.jl/blob/master/
            # Link to nbviewer: https://nbviewer.jupyter.org/github/fredrikekre/Literate.jl/blob/gh-pages/v1.2.0/
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
            @test contains(markdown, "fredrikekre/Literate.jl/blob/gh-pages/latest/")

            # pre- and post-processing
            Literate.markdown(inputfile, outdir,
                preprocess = x -> replace(replace(x, "PLACEHOLDER1" => "1REDLOHECALP"), "PLACEHOLDER3" => "3REDLOHECALP"),
                postprocess = x -> replace(replace(x, "PLACEHOLDER2" => "2REDLOHECALP"), "PLACEHOLDER4" => "4REDLOHECALP"))
            markdown = read(joinpath(outdir, "inputfile.md"), String)
            @test !contains(markdown, "PLACEHOLDER1")
            @test !contains(markdown, "PLACEHOLDER2")
            @test !contains(markdown, "PLACEHOLDER3")
            @test !contains(markdown, "PLACEHOLDER4")
            @test contains(markdown, "1REDLOHECALP")
            @test contains(markdown, "2REDLOHECALP")
            @test contains(markdown, "3REDLOHECALP")
            @test contains(markdown, "4REDLOHECALP")

            # documenter = false
            Literate.markdown(inputfile, outdir, documenter = false)
            markdown = read(joinpath(outdir, "inputfile.md"), String)
            @test contains(markdown, "```julia")
            @test !contains(markdown, "```@example")
            @test !contains(markdown, "continued = true")
            @test !contains(markdown, "EditURL")

            # codefence
            Literate.markdown(inputfile, outdir, codefence = "```c" => "```")
            markdown = read(joinpath(outdir, "inputfile.md"), String)
            @test contains(markdown, "```c")
            @test !contains(markdown, "```@example")
            @test !contains(markdown, "```julia")

            # name
            Literate.markdown(inputfile, outdir, name = "foobar")
            markdown = read(joinpath(outdir, "foobar.md"), String)
            @test contains(markdown, "```@example foobar")
            @test !contains(markdown, "```@example inputfile")
            @test contains(markdown, "name: foobar")
            @test !contains(markdown, "name: inputfile")
            @test !contains(markdown, "name: @__NAME__")
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
                "Only notebook"
               ]
            """,

            """
               "source": [
                "x + 2\\n",
                "# #' Comment\\n",
                "# another comment"
               ]
            """,

            """
               "source": [
                "for i in 1:10\\n",
                "    print(i)\\n",
                "#' some markdown in a code block\\n",
                "end"
               ]
            """,

            """
               "source": [
                "name: inputfile\\n",
                "Link to repo root: https://github.com/fredrikekre/Literate.jl/blob/master/\\n",
                "Link to nbviewer: https://nbviewer.jupyter.org/github/fredrikekre/Literate.jl/blob/gh-pages/v1.2.0/"
               ]
            """,

            """
               "source": [
                "# name: inputfile\\n",
                "# Link to repo root: https://github.com/fredrikekre/Literate.jl/blob/master/\\n",
                "# Link to nbviewer: https://nbviewer.jupyter.org/github/fredrikekre/Literate.jl/blob/gh-pages/v1.2.0/"
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
                "\\\\begin{equation}\\n",
                "\\\\int f(x) dx\\n",
                "\\\\end{equation}"
               ]
            """))

            notebook = read(joinpath(outdir, "inputfile.ipynb"), String)

            lastidx = 1
            for cell in expected_cells
                idx = Compat.findnext(cell, notebook, lastidx)
                @test idx !== nothing
                lastidx = nextind(notebook, last(idx))
            end
            # test some of the required metadata
            for metadata in (" \"nbformat\": ", " \"nbformat_minor\": ", " \"metadata\": {", "  \"language_info\": {",
                "   \"file_extension\": \".jl\"", "   \"mimetype\": \"application/julia\"",
                "   \"name\": \"julia\"", "   \"version\": ", "  \"kernelspec\": {",
                "   \"name\": \"julia-", "   \"display_name\": \"Julia ", "   \"language\": \"julia\"")
                @test contains(notebook, metadata)
            end

            # no tag -> latest directory
            withenv("TRAVIS_REPO_SLUG" => "fredrikekre/Literate.jl",
                    "TRAVIS_TAG" => "",
                    "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true") do
                Literate.notebook(inputfile, outdir, execute = false)
            end
            notebook = read(joinpath(outdir, "inputfile.ipynb"), String)
            @test contains(notebook, "fredrikekre/Literate.jl/blob/gh-pages/latest/")

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
            Literate.notebook(inputfile, outdir, execute = false,
                preprocess = x -> replace(replace(x, "PLACEHOLDER1" => "1REDLOHECALP"), "PLACEHOLDER3" => "3REDLOHECALP"),
                postprocess = post)
            notebook = read(joinpath(outdir, "inputfile.ipynb"), String)
            @test !contains(notebook, "PLACEHOLDER1")
            @test !contains(notebook, "PLACEHOLDER2")
            @test !contains(notebook, "PLACEHOLDER3")
            @test !contains(notebook, "PLACEHOLDER4")
            @test contains(notebook, "1REDLOHECALP")
            @test contains(notebook, "2REDLOHECALP")
            @test contains(notebook, "3REDLOHECALP")
            @test contains(notebook, "4REDLOHECALP")

            # documenter = false
            Literate.notebook(inputfile, outdir, documenter = false, execute = false)
            notebook = read(joinpath(outdir, "inputfile.ipynb"), String)
            @test contains(notebook, "# [Example](@id example-id")
            @test contains(notebook, "[foo](@ref), [bar](@ref bbaarr)")

            # name
            Literate.notebook(inputfile, outdir, name = "foobar", execute = false)
            notebook = read(joinpath(outdir, "foobar.ipynb"), String)
            @test contains(notebook, "name: foobar")
            @test !contains(notebook, "name: inputfile")
            @test !contains(notebook, "name: @__NAME__")

            # execute = true
            Literate.notebook(inputfile, outdir)
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
                idx = Compat.findnext(out, notebook, lastidx)
                @test idx !== nothing
                lastidx = nextind(notebook, last(idx))
            end
        end
    end
end
