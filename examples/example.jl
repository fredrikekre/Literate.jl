#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
# # **8.** Example
#
#md # [![](https://mybinder.org/badge_logo.svg)](@__BINDER_ROOT_URL__/generated/example.ipynb)
#md # [![](https://img.shields.io/badge/show-nbviewer-579ACA.svg)](@__NBVIEWER_ROOT_URL__/generated/example.ipynb)

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
# This is an example generated with Literate based on this
# source file: [`example.jl`](@__REPO_ROOT_URL__/examples/example.jl).
# You are seeing the
#md # HTML-output which Documenter has generated based on a markdown
#md # file generated with Literate. The corresponding notebook
#md # can be viewed in [nbviewer](http://nbviewer.jupyter.org/) here:
#md # [`example.ipynb`](@__NBVIEWER_ROOT_URL__/generated/example.ipynb),
#md # and opened in [binder](https://mybinder.org/) here:
#md # [`example.ipynb`](@__BINDER_ROOT_URL__/generated/example.ipynb),
#nb # generated notebook output. The corresponding markdown (HTML) output
#nb # can be found here: [`example.html`](https://fredrikekre.github.io/Literate.jl/dev/generated/example.html),
# and the plain script output can be found here: [`example.jl`](./example.jl).

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
#nb # To view this notebook as a slideshow, install the [RISE plugin](https://rise.readthedocs.io/en/stable/installation.html)
#nb # and press `alt-r` to start. Use spacebar to advance.

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
# It is recommended to have the [source file](@__REPO_ROOT_URL__/examples/example.jl)
# available when reading this, to better understand how the syntax in the source file
# corresponds to the output you are seeing.

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
# ### Basic syntax
# The basic syntax for Literate is simple, lines starting with `# ` is interpreted
# as markdown, and all the other lines are interpreted as code. Here is some code:

#nb %% A slide [code] {"slideshow": {"slide_type": "fragment"}}
x = 1//3
y = 2//5

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# In markdown sections we can use markdown syntax. For example, we can
# write *text in italic font*, **text in bold font** and use
# [links](https://www.youtube.com/watch?v=dQw4w9WgXcQ).

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
# It is possible to filter out lines depending on the output using the
# `#md`, `#nb`, `#jl` and `#src` tags (see [Filtering lines](@ref)):
#md # - This line starts with `#md` and is thus only visible in the markdown output.
#nb # - This line starts with `#nb` and is thus only visible in the notebook output.
#jl # - This line starts with `#jl` and is thus only visible in the script output.
#src # - This line starts with `#src` and is thus only visible in the source file.

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# The source file is parsed in chunks of markdown and code. Starting a line
# with `#-` manually inserts a chunk break. For example, if we want to
# display the output of the following operations we may insert `#-` in
# between. These two code blocks will now end up in different
# `@example`-blocks in the markdown output, and two different notebook cells
# in the notebook output.

#nb %% A slide [code] {"slideshow": {"slide_type": "subslide"}}
x + y

#-
#nb %% A slide [code] {"slideshow": {"slide_type": "fragment"}}
x * y

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
# ### Output capturing
# Code chunks are by default placed in Documenter `@example` blocks in the generated
# markdown. This means that the output will be captured in a block when Documenter is
# building the docs. In notebooks the output is captured in output cells, if the
# `execute` keyword argument is set to true. Output to `stdout`/`stderr` is also
# captured.

#md # !!! note
#md #     Note that Documenter currently only displays output to `stdout`/`stderr`
#md #     if there is no other result to show. Since the vector `[1, 2, 3, 4]` is
#md #     returned from `foo`, the printing of `"This string is printed to stdout."`
#md #     is hidden.

#nb %% A slide [code] {"slideshow": {"slide_type": "subslide"}}
function foo()
    println("This string is printed to stdout.")
    return [1, 2, 3, 4]
end

foo()

# Just like in the REPL, outputs ending with a semicolon hides the output:
1 + 1;

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# Both Documenter's `@example` block and notebooks can display images. Here is an example
# where we generate a simple plot using the
# [Plots.jl](https://github.com/JuliaPlots/Plots.jl) package

#nb %% A slide [code] {"slideshow": {"slide_type": "subslide"}}
using Plots
x = range(0, stop=6π, length=1000)
y1 = sin.(x)
y2 = cos.(x)
plot(x, [y1, y2])

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
# ### Custom processing
#
# It is possible to give Literate custom pre- and post-processing functions.
# For example, here we insert a placeholder value `x = 123` in the source, and use a
# preprocessing function that replaces it with `y = 321` in the rendered output.

#nb %% A slide [code] {"slideshow": {"slide_type": "subslide"}}
x = 123

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
# In this case the preprocessing function is defined by

#nb %% A slide [code] {"slideshow": {"slide_type": "fragment"}}
function pre(s::String)
    s = replace(s, "x = 123" => "y = 321")
    return s
end

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
# ### [Documenter.jl interaction](@id documenter-interaction)
#
# In the source file it is possible to use Documenter.jl style references,
# such as `@ref` and `@id`. These will be filtered out in the notebook output.
# For example, [here is a link](@ref documenter-interaction), but it is only
# visible as a link if you are reading the markdown output. We can also
# use equations:

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
# ```math
# \int_\Omega \nabla v \cdot \nabla u\ \mathrm{d}\Omega = \int_\Omega v f\ \mathrm{d}\Omega
# ```

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
# using Documenters math syntax. Documenters syntax is automatically changed to
# `\begin{equation} ... \end{equation}` in the notebook output to display correctly.
