# **2.** File Format

The source file format for `Examples.jl` is a regular, commented, julia (`.jl`) scripts.
The idea is that the scripts also serve as documentation on their own and it is also
simple to include them in the test-suite, with e.g. `include`, to make sure the examples
stay up do date with other changes in your package.

## [**2.1.** Syntax](@id Syntax)

The basic syntax is simple:
- lines starting with `#'` is treated as markdown,
- all other lines are treated as julia code.

The reason for using `#'` instead of `#` is that we want to be able to use `#` as comments,
just as in a regular script. Lets look at a simple example:
```julia
#' # Rational numbers
#'
#' In julia rational numbers can be constructed with the `//` operator.
#' Lets define two rational numbers, `x` and `y`:

x = 1//3
y = 2//5

#' When adding `x` and `y` together we obtain a new rational number:

z = x + y
```
In the lines `#'` we can use regular markdown syntax, for example the `#`
used for the heading and the backticks for formatting code. The other lines are regular
julia code. We note a couple of things:
- The script is valid julia, which means that we can `include` it and the example will run
- The script is "self-explanatory", i.e. the markdown lines works as comments and
  thus serve as good documentation on its own.

For simple use this is all you need to know, the script above is valid. Let's take a look
at what the above snippet would generate, with default settings:

- [`Examples.markdown`](@ref): leading `#'` are removed, and code lines are wrapped in
  `@example`-blocks:
  ````markdown
  # Rational numbers

  In julia rational numbers can be constructed with the `//` operator.
  Lets define two rational numbers, `x` and `y`:

  ```@example filename
  x = 1//3
  y = 2//5
  ```

  When adding `x` and `y` together we obtain a new rational number:

  ```@example filename
  z = x + y
  ```
  ````

- [`Examples.notebook`](@ref): leading `#'` are removed, markdown lines are placed in
  `"markdown"` cells, and code lines in `"code"` cells:
  ```
           │ # Rational numbers
           │
           │ In julia rational numbers can be constructed with the `//` operator.
           │ Lets define two rational numbers, `x` and `y`:

  In [1]:  │ x = 1//3
           │ y = 2//5

  Out [1]: │ 2//5

           │ When adding `x` and `y` together we obtain a new rational number:

  In [2]:  │ z = x + y

  Out [2]: │ 11//15
  ```

- [`Examples.script`](@ref): all lines starting with `#'` are removed:
  ```julia
  x = 1//3
  y = 2//5

  z = x + y
  ```

## [**2.2.** Filtering Lines](@id Filtering-lines)

It is possible to filter out lines depending on the output format. For this purpose,
there are three different "tokens" that can be placed on the start of the line:
- `#md`: markdown output only,
- `#nb`: notebook output only,
- `#jl`: script output only.

Lines starting with one of these tokens are filtered out in the
[preprocessing step](@ref Pre-processing).

Suppose, for example, that we want to include a docstring within a `@docs` block
using Documenter. Obviously we don't want to include this in the notebook,
since `@docs` is Documenter syntax that the notebook will not understand. This
is a case where we can prepend `#md` to those lines:
````julia
#md #' ```@docs
#md #' Examples.markdown
#md #' Examples.notebook
#md #' Examples.markdown
#md #' ```
````
The lines in the example above would be filtered out in the preprocessing step, unless we are
generating a markdown file. When generating a markdown file we would simple remove
the leading `#md ` from the lines. Beware that the space after the tag is also removed.
