# [**5.** Custom pre- and post-processing](@id Custom-pre-and-post-processing)

Since all packages are different, and may have different demands on how
to create a nice example for the documentation it is important that
the package maintainer does not feel limited by the by default provided syntax
that this package offers. While you can generally come a long way by utilizing
[line filtering](@ref Filtering-lines) there might be situations where you need
to manually hook into the generation and change things. In `Literate.jl` this
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

As an example, lets say we want to splice the date of generation into the output.
We could of course update our source file before generating the docs, but we could
instead use a `preprocess` function that splices the date into the source for us.
Consider the following source file:
```julia
#' # Example
#' This example was generated DATEOFTODAY

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
