#' # **7.** Example
#'
#' *Output generated with Examples.jl based on
#' [this](../../../examples/example.jl) source file.*
#'
#' This is an example source file for input to Examples.jl.
#'
#md #' If you are reading this you are seeing the markdown output
#md #' generated from the source file, here you can see the corresponding
#md #' notebook output: [example.ipynb](./example.ipynb)
#nb #' If you are reading this you are seeing the notebook output
#nb #' generated from the source file, here you can see the corresponding
#nb #' markdown output: [example.md](./example.md)

#' ## Rational numbers in Julia
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
