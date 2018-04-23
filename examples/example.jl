#' # **7.** Example
#'
#' This is an example generated with Literate based on this
#' source file: [`example.jl`](@__REPO_ROOT_URL__examples/example.jl).
#' You are seeing the
#md #' html-output which Documenter have generated based on a markdown
#md #' file generated with Literate. The corresponding notebook
#md #' can be found here: [`example.ipynb`](@__NBVIEWER_ROOT_URL__generated/example.ipynb),
#nb #' generated notebook output. The corresponding markdown (html) output The generated markdown can be found here: [`example.md`](./example.md), the
#nb #' can be found here: [`example.md`](./example.md),
#' and the plain script output can be found here: [`example.jl`](./example.jl).

#' It is recommended to have the [source file](@__REPO_ROOT_URL__examples/example.jl)
#' available when reading this, to better understand how the syntax in the source file
#' corresponds to the output you are seeing.

#' ### Basic syntax
#' The basic syntax for Literate is simple, lines starting with `#'` is interpreted
#' as markdown, and all the other lines are interpreted as code. Here is some code:

x = 1//3
y = 2//5

#' In markdown sections we can use markdown syntax. For example, we can
#' write *text in italic font*, **text in bold font** and use
#' [links](https://www.youtube.com/watch?v=dQw4w9WgXcQ).

#' It is possible to filter lines by starting it with `#md`, `#nb` or `#jl`
#' for markdown, notebook and script output only, respectively.
#md #' This line is filtered out for notebook and script output.
#nb #' This line is filtered out for markdown and script output.
#jl #' This line is filtered out for markdown and notebook output.

#' The source file is parsed in chunks of markdown and code. Starting a line
#' with `#-` manually inserts a chunk break. For example, if we want to
#' display the output of the following operations we may insert `#-` in
#' between. These two code blocks will now end up in different
#' `@example`-blocks in the markdown output, and two different notebook cells
#' in the notebook output.

x + y

#-

x * y

#' ### Output Capturing
#' Code chunks are by default placed in Documenter `@example` blocks in the generated
#' markdown. This means that the output will be captured in a block when Documenter is
#' building the docs. In notebooks the output is captured in output cells, if the
#' `execute` keyword argument is set to true. Output to `stdout`/`stderr` is also
#' captured.

function foo()
    println("This string is printed to stdout.")
    return [1, 2, 3, 4]
end

foo()

#' ### Custom processing
#'
#' It is possible to give Literate custom pre- and post-processing functions.
#' For example, here we insert two placeholders, which we will replace with
#' something else at time of generation. We have here replaced our placeholders
#' with `z` and `1.0 + 2.0im`:

MYVARIABLE = MYVALUE

#' ### [Documenter.jl interaction](@id documenter-interaction)
#'
#' In the source file it is possible to use Documenter.jl style references,
#' such as `@ref` and `@id`. These will be filtered out in the notebook output.
#' For example, [here is a link](@ref documenter-interaction), but it is only
#' visible as a link if you are reading the markdown output. We can also
#' use equations:
#'
#' ```math
#' \int_\Omega \nabla v \cdot \nabla u\ \mathrm{d}\Omega = \int_\Omega v f\ \mathrm{d}\Omega
#' ```
#'
#' using Documenters math syntax. Documenters syntax is automatically changed to
#' `\begin{equation} ... \end{equation}` in the notebook output to display correctly.
