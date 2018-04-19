# **1.** Introduction

Welcome to the documentation for `Literate.jl`. A simplistic package
to help you organize examples for you package documentation.

### What?

`Literate.jl` is a package that, based on a single source file, generates markdown,
for e.g. [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl),
[Jupyter notebooks](http://jupyter.org/) and uncommented scripts for documentation
of your package.

The main design goal is simplicity. It should be simple to use, and the syntax should
be simple. In short all you have to do is to write a commented julia script!

The package consists mainly of three functions, which all takes the same script file
as input, but generates different output:
- [`Literate.markdown`](@ref): generates a markdown file
- [`Literate.notebook`](@ref): generates an (optionally executed) notebook
- [`Literate.script`](@ref): generates a plain script file, removing everything
  that is not code

### Why?

Literate are (probably) the best way to showcase your awesome package, and examples
are often the best way for a new user to learn how to use it. It is therefore important
that the documentation of your package contains examples for users to read and study.
However, people are different, and we all prefer different ways of trying out a new
package. Some people wants to RTFM, others want to explore the package interactively in,
for example, a notebook, and some people wants to study the source code. The aim of
`Literate.jl` is to make it easy to give the user all of these options, while still
keeping maintenance to a minimum.

It is quite common that packages have "example notebooks" to showcase the package.
Notebooks are great for this, but they are not so great with version control, like git.
The reason is that a notebook is a very "rich" format since it contains output and other
metadata. Changes to the notebook thus result in large diffs, which makes it harder to
review the actual changes.

It is also common that packages include examples in the documentation, for example
by using [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) `@example`-blocks.
This is also great, but it is not quite as interactive as a notebook, for the users
who prefer that.

`Literate.jl` tries to solve the problems above by creating the output as a part of the doc
build. `Literate.jl` generates the output from a single source file which makes it easier to
maintain, test, and keep the manual and your example notebooks in sync.

### How?

TBD
