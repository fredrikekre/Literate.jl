import Examples
import Examples: Chunk, MDChunk, CodeChunk
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

@testset "Examples.parse" begin
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
    parsed_chunks = Examples.parse(content)
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

    compare_chunks(Examples.parse(String(take!(io))), Examples.parse(String(take!(iows))))

end # testset parser

content = """
    #' Line 1
    Line 2
    #md #' Line 3
    #md Line 4
    #nb #' Line 5
    #nb Line 6
    #jl #' Line 7
    #jl Line 8
    #' Line 9  #jl
    Line 10    #jl
    # #' Line 11
    # Line 12
    #-
    Line 14
        Line 15
    #' Line 16
    Line 17
    #' @__REPO_ROOT_URL__
    @__REPO_ROOT_URL__
    #' @__NBVIEWER_ROOT_URL__
    @__NBVIEWER_ROOT_URL__
    """

@testset "Examples.script" begin
    mktempdir(@__DIR__) do sandbox
        cd(sandbox) do
            # write content to inputfile
            inputfile = "inputfile.jl"
            write(inputfile, content)
            outdir = mktempdir(pwd())

            # test defaults
            withenv("TRAVIS_REPO_SLUG" => "fredrikekre/Examples.jl",
                    "TRAVIS_TAG" => "v1.2.0",
                    "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true") do
                Examples.script(inputfile, outdir)
            end
            expected_script = """
            Line 2

            Line 8

            Line 10
            # #' Line 11
            # Line 12

            Line 14
                Line 15

            Line 17

            https://github.com/fredrikekre/Examples.jl/blob/master/

            https://nbviewer.jupyter.org/github/fredrikekre/Examples.jl/blob/gh-pages/v1.2.0/

            """
            @test read(joinpath(outdir, "inputfile.jl"), String) == expected_script

            # no tag -> latest directory
            withenv("TRAVIS_REPO_SLUG" => "fredrikekre/Examples.jl",
                    "TRAVIS_TAG" => "",
                    "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true") do
                Examples.script(inputfile, outdir)
            end
            script = read(joinpath(outdir, "inputfile.jl"), String)
            @test contains(script, "fredrikekre/Examples.jl/blob/gh-pages/latest/")

            # pre- and post-processing
            Examples.script(inputfile, outdir,
                preprocess = x -> replace(x, "Line 11" => "Foo"),
                postprocess = x -> replace(x, "Line 12" => "Bar"))
            script = read(joinpath(outdir, "inputfile.jl"), String)
            @test !contains(script, "Line 11")
            @test contains(script, "Foo")
            @test !contains(script, "Line 12")
            @test contains(script, "Bar")

            # name
            Examples.script(inputfile, outdir, name = "foobar")
            namedscript = read(joinpath(outdir, "foobar.jl"), String)
            Examples.script(inputfile, outdir)
            nonamescrip = read(joinpath(outdir, "inputfile.jl"), String)
            @test namedscript == nonamescrip
        end
    end
end

@testset "Examples.markdown" begin
    mktempdir(@__DIR__) do sandbox
        cd(sandbox) do
            # write content to inputfile
            inputfile = "inputfile.jl"
            write(inputfile, content)
            outdir = mktempdir(pwd())

            # test defaults
            withenv("TRAVIS_REPO_SLUG" => "fredrikekre/Examples.jl",
                    "TRAVIS_TAG" => "v1.2.0",
                    "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true") do
                Examples.markdown(inputfile, outdir)
            end
            expected_markdown = """
            ```@meta
            EditURL = "https://github.com/fredrikekre/Examples.jl/blob/master/test/$(basename(sandbox))/inputfile.jl"
            ```

            Line 1

            ```@example inputfile
            Line 2
            ```

            Line 3

            ```@example inputfile
            Line 4
            # #' Line 11
            # Line 12
            ```

            ```@example inputfile; continued = true
            Line 14
                Line 15
            ```

            Line 16

            ```@example inputfile
            Line 17
            ```

            https://github.com/fredrikekre/Examples.jl/blob/master/

            ```@example inputfile
            https://github.com/fredrikekre/Examples.jl/blob/master/
            ```

            https://nbviewer.jupyter.org/github/fredrikekre/Examples.jl/blob/gh-pages/v1.2.0/

            ```@example inputfile
            https://nbviewer.jupyter.org/github/fredrikekre/Examples.jl/blob/gh-pages/v1.2.0/
            ```

            """
            @test read(joinpath(outdir, "inputfile.md"), String) == expected_markdown

            # no tag -> latest directory
            withenv("TRAVIS_REPO_SLUG" => "fredrikekre/Examples.jl",
                    "TRAVIS_TAG" => "",
                    "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true") do
                Examples.markdown(inputfile, outdir)
            end
            markdown = read(joinpath(outdir, "inputfile.md"), String)
            @test contains(markdown, "fredrikekre/Examples.jl/blob/gh-pages/latest/")

            # pre- and post-processing
            Examples.markdown(inputfile, outdir,
                preprocess = x -> replace(x, "Line 11" => "Foo"),
                postprocess = x -> replace(x, "Line 12" => "Bar"))
            markdown = read(joinpath(outdir, "inputfile.md"), String)
            @test !contains(markdown, "Line 11")
            @test contains(markdown, "Foo")
            @test !contains(markdown, "Line 12")
            @test contains(markdown, "Bar")

            # documenter = false
            Examples.markdown(inputfile, outdir, documenter = false)
            markdown = read(joinpath(outdir, "inputfile.md"), String)
            @test contains(markdown, "```julia")
            @test !contains(markdown, "```@example")
            @test !contains(markdown, "continued = true")
            @test !contains(markdown, "EditURL")

            # codefence
            Examples.markdown(inputfile, outdir, codefence = "```c" => "```")
            markdown = read(joinpath(outdir, "inputfile.md"), String)
            @test contains(markdown, "```c")
            @test !contains(markdown, "```@example")
            @test !contains(markdown, "```julia")

            # name
            Examples.markdown(inputfile, outdir, name = "foobar")
            markdown = read(joinpath(outdir, "foobar.md"), String)
            @test contains(markdown, "```@example foobar")
            @test !contains(markdown, "```@example inputfile")
        end
    end
end
