#' # **7.** Example
#'
#' This is an example for Examples.jl.
#' The source file can be found [here](@__REPO_ROOT_URL__examples/example.jl).
#' The generated markdown can be found here: [`example.md`](./example.md), the
#' generated notebook can be found here:
#' [`example.ipynb`](@__NBVIEWER_ROOT_URL__generated/example.ipynb), and the
#' plain script output can be found here: [`example.jl`](./example.jl).

#' ### Rational numbers in Julia
#' Rational number in julia can be constructed with the `//` operator:

x = 1//3
y = 2//5

#' Operations with rational number returns a new rational number

x + y

#-

x * y

#' Everytime a rational number is constructed, it will be simplified
#' using the `gcd` function, for example `2//4` simplifies to `1//2`:

2//4

#' and `2//4 + 2//4` simplifies to `1//1`:

2//4 + 2//4
