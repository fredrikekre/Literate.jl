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

## Example: Adding current date
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

## Example: Replacing `include` calls with included code
Let's say that we have some individual example files `file1, file2, ...` etc.
that are _runnable_ and also following the style of Literate. These files could be for example used in the test suite of your package.

We want to group them all into a single page in our documentation, but we
do not want to copy paste the content of `file1, ...` for robustness: the files are included in the test suite and some changes may occur to them. We want these changes to also be reflected in the documentation.

A very easy way to do this is using `preprocess` to interchange `include` statements with file content. First, create a runnable `.jl` following the format of Literate (the following example comes from the documentation of the Julia package [`TimeseriesPrediction`](https://github.com/JuliaDynamics/TimeseriesPrediction.jl), which uses this approach to create some pages)
```julia
# # Spatio-Temporal Prediction Examples
# In this page we are simply running files from the
# `examples` folder of the `TimeseriesPrediction` package.

# ## Temporal Prediction: Kuramoto-Sivashinsky
# *(this requires `FFTW` to be installed)*

include("1Dfield_temporalprediction.jl")

# ## Cross Prediction: Barkley Model

include("2Dfield_crossprediction.jl")

# ## Temporal Prediction: Periodic Nonlinear Barkley Model

include("2Dfield_temporalprediction.jl")
```
Let's say we have saved this file as `stexamples.jl`.
Then, you want to properly define a pre-processing function:
```julia
function replace_includes(str)

    included = ["1Dfield_temporalprediction.jl",
    "2Dfield_crossprediction.jl", "2Dfield_temporalprediction.jl"]

    # Here path loads the files from their proper directory,
    # which may not be the directory of the `stexamples.jl` file!
    path = dirname(dirname(pathof(TimeseriesPrediction)))*"/examples/"

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
Literate.markdown("src/tsprediction/stexamples.jl", "src/tsprediction/";
                  name = "stexamples", preprocess = replace_includes)
```
and you will see that in the final output file (here `stexamples.md`) the `include`
statements are replaced with the actual code to be included!
