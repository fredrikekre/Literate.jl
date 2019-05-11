# [**5.** Custom pre- and post-processing](@id Custom-pre-and-post-processing)

Since all packages are different, and may have different demands on how
to create a nice example for the documentation it is important that
the package maintainer does not feel limited by the by default provided syntax
that this package offers. While you can generally come a long way by utilizing
[line filtering](@ref Filtering-Lines) there might be situations where you need
to manually hook into the generation and change things. In Literate this
is done by letting the user supply custom pre- and post-processing functions
that may do transformation of the content.

All of the generators ([`Literate.markdown`](@ref), [`Literate.notebook`](@ref)
and [`Literate.script`](@ref)) accepts `preprocess` and `postprocess` keyword
arguments. The default "transformation" is the `identity` function. The input
to the transformation functions is a `String`, and the output should be the
transformed `String`.

`preprocess` is sent the raw input that is read from the source file ([modulo the
default line ending transformation](@ref Pre-processing)). `postprocess` is given
different things depending on the output: For markdown and script output `postprocess`
is given the content `String` just before writing it to the output file, but for
notebook output `postprocess` is given the dictionary representing the notebook,
since, in general, this is more useful.

### Example: Adding current date
As an example, lets say we want to splice the date of generation into the output.
We could of course update our source file before generating the docs, but we could
instead use a `preprocess` function that splices the date into the source for us.
Consider the following source file:
```julia
# # Example
# This example was generated DATEOFTODAY

x = 1 // 3
```
where `DATEOFTODAY` is a placeholder, to make it easier for our `preprocess` function
to find the location. Now, lets define the `preprocess` function, for example
```julia
function update_date(content)
    content = replace(content, "DATEOFTODAY" => Date(now()))
    return content
end
```
which would replace every occurrence of `"DATEOFTODAY"` with the current date. We would
now simply give this function to the generator, for example:
```julia
Literate.markdown("input.jl", "outputdir"; preprocess = update_date)
```

### Example: Replacing `include` calls with included code
Let's say that we have some individual example files `file1, file2, ...` etc.
that are _runnable_ and also following the style of Literate. These files could be for example used in the test suite of your package.

We want to group them all into a single page in our documentation, but we
do not want to copy paste the content of `file1, ...` for robustness: the files are included in the test suite and some changes may occur to them. We want these changes to also be reflected in the documentation.

A very easy way to do this is using `preprocess` to interchange `include` statements with file content. First, create a runnable `.jl` following the format of Literate
```julia
# # Replace includes
# This is an example to replace `include` calls with the actual file content.

include("file1.jl")

# Cool, we just saw the result of the above code snippet. Here is one more:

include("file2.jl")
```

Let's say we have saved this file as `examples.jl`.
Then, you want to properly define a pre-processing function:

```julia
function replace_includes(str)

    included = ["file1.jl", "file2.jl"]

    # Here the path loads the files from their proper directory,
    # which may not be the directory of the `examples.jl` file!
    path = "directory/to/example/files/"

    for ex in included
        content = read(path*ex, String)
        str = replace(str, "include(\"$(ex)\")" => content)
    end
    return str
end
```
(of course replace `included` with your respective files)

Finally, you simply pass this function to e.g. [`Literate.markdown`](@ref) as
```julia
Literate.markdown("examples.jl", "path/to/save/markdown";
                  name = "markdown_file_name", preprocess = replace_includes)
```
and you will see that in the final output file (here `markdown_file_name.md`) the `include`
statements are replaced with the actual code to be included!

This approach is used for generating [the examples](https://juliadynamics.github.io/TimeseriesPrediction.jl/latest/stexamples/)
in the documentation of the [TimeseriesPrediction.jl](https://github.com/JuliaDynamics/TimeseriesPrediction.jl) package.
The 
[example files](https://github.com/JuliaDynamics/TimeseriesPrediction.jl/tree/dcb080376a7861716147c04e45c473f55bb9a078/examples),
included together in the 
[stexamples.jl](https://github.com/JuliaDynamics/TimeseriesPrediction.jl/blob/dcb080376a7861716147c04e45c473f55bb9a078/docs/src/stexamples.jl) file,
are processed by literate via this
[make.jl](https://github.com/JuliaDynamics/TimeseriesPrediction.jl/blob/dcb080376a7861716147c04e45c473f55bb9a078/docs/make.jl) 
file to generate the markdown and code cells of the documentation.





