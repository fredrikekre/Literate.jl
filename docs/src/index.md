# **1.** Introduction

Welcome to the documentation for Literate -- a simplistic package
for [Literate Programming](https://en.wikipedia.org/wiki/Literate_programming).

### What?

Literate is a package that generates markdown pages
(for e.g. [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)), and
[Jupyter notebooks](http://jupyter.org/), from the same source file. There is also
an option to "clean" the source from all metadata, and produce a pure Julia script.

The main design goal is simplicity. It should be simple to use, and the syntax should
be simple. In short, all you have to do is to write a commented julia script!

The public interface consists mainly of three functions, all of which take the same script file
as input, but generate different output:
- [`Literate.markdown`](@ref): generates a markdown file
- [`Literate.notebook`](@ref): generates an (optionally executed) notebook
- [`Literate.script`](@ref): generates a plain script file, removing all metadata
  and special syntax.

### Why?

Examples are (probably) the best way to showcase your awesome package, and examples
are often the best way for a new user to learn how to use it. It is therefore important
that the documentation of your package contains examples for users to read and study.
However, people are different, and we all prefer different ways of trying out a new
package. Some people wants to RTFM, others want to explore the package interactively in,
for example, a notebook, and some people wants to study the source code. The aim of
Literate is to make it easy to give the user all of these options, while still
keeping maintenance to a minimum.

It is quite common that packages have "example notebooks" to showcase the package.
Notebooks are great for showcasing a package, but they are not so great with version
control, like git. The reason being that a notebook is a very "rich" format since it
contains output and other metadata. Changes to the notebook thus result in large diffs,
which makes it harder to review the actual changes.

It is also common that packages include examples in the documentation, for example
by using [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) `@example`-blocks.
This is also great, but it is not quite as interactive as a notebook, for the users
who prefer that.

Literate tries to solve the problems above by creating the output as a part of the doc
build. Literate generates the output based on a single source file which makes it
easier to maintain, test, and keep the manual and your example notebooks in sync.

