# [**2.** File format](@id File-format)

The source file format for Literate is a regular, commented, julia (`.jl`) scripts.
The idea is that the scripts also serve as documentation on their own and it is also
simple to include them in the test-suite, with e.g. `include`, to make sure the examples
stay up to date with other changes in your package.

## [**2.1.** Syntax](@id Syntax)

The basic syntax is simple:
- lines starting with `# ` are treated as markdown,
- all other lines are treated as julia code.

Leading whitespace is allowed before `#`, but it will be removed when generating the
output. Since `#`-lines are treated as markdown we can not use that for regular julia
comments, for this you can instead use `## `, which will render as `# ` in the output.

Lets look at a simple example:
```julia
# # Rational numbers
#
# In julia rational numbers can be constructed with the `//` operator.
# Lets define two rational numbers, `x` and `y`:

## Define variable x and y
x = 1//3
y = 2//5
z = 3//5 ## z is 3//5 and this is an end of line comment

# When adding `x` and `y` together we obtain a new rational number:

z = x + y
```
In the lines starting with `# ` we can use regular markdown syntax, for example the `#`
used for the heading and the backticks for formatting code. The other lines are regular
julia code. We note a couple of things:
- The script is valid julia, which means that we can `include` it and the example will run
  (for example in the `test/runtests.jl` script, to include the example in the test suite).
- The script is "self-explanatory", i.e. the markdown lines works as comments and
  thus serve as good documentation on its own.

For simple use this is all you need to know. The following additional special syntax can also be used:
- `#md`, `#nb`, `#jl`, `#src`: tags to filter lines, see [Filtering lines](@ref Filtering-lines),
- `#-` (`#+`): tag to manually control chunk-splits, see [Custom control over chunk splits](@ref).

There is also some default convenience replacements that will always be performed, see
[Default replacements](@ref).

### Multiline comments and markdown strings

Literate version 2.7 adds support for Julia multiline comments for markdown input.
All multiline comments in the input are rewritten to regular comments as part of the
preprocessing step, before any other processing is performed. For Literate to recognize
multiline comments it is required that the start token (`#=`) and end token (`=#`) are
placed *on their own lines*. Note also that it is allowed to have more than one `=` in the
tokens, for example
```
#=
This multiline comment
is treated as markdown.
=#

#=====================
This is also markdown.
=====================#
```
is rewritten to
```
# This multiline comment
# is treated as markdown.

# This is also markdown.
```

Similarly, Literate version 2.9 adds support for using literal markdown strings,
`md""" ... """`, for the markdown sections, for example

```julia
md"""
# Title
blah blah blah
"""
```
is rewritten to
```
# # Title
# blah blah blah
```
This is not enabled by default -- it requires passing `mdstrings=true`.
`Literate.markdown`/`Literate.notebook`/`Literate.script`.

## [**2.2.** Filtering lines](@id Filtering-lines)

It is often useful to filter out lines in the source depending on the output format.
For this purpose there are a number of "tokens" that can be used to mark the purpose of
certain lines:
- `#md `: line exclusive to markdown output,
- `#nb `: line exclusive to notebook output,
- `#jl `: line exclusive to script output,
- `#src `: line exclusive to the source code and thus filtered out unconditionally.

Lines *starting* or *ending* with one of these tokens are filtered out in the
[preprocessing step](@ref Pre-processing). In addition, for markdown output, lines
ending with `#hide` are filtered out similar to Documenter.jl.


!!! note "Difference between `#src` and `#hide`"
    `#src` and `#hide` are quite similar. The only difference is that `#src` lines
    are filtered out *before* execution (if `execute=true`) and `#hide` lines
    are filtered out *after* execution.

!!! tip
    The tokens can also be negated, for example a line starting with `#!nb` would
    be included in markdown and script output, but filtered out for notebook output.

Suppose, for example, that we want to include a docstring within a `@docs` block
using Documenter. Obviously we don't want to include this in the notebook,
since `@docs` is Documenter syntax that the notebook will not understand. This
is a case where we can prepend `#md` to those lines:
````julia
#md # ```@docs
#md # Literate.markdown
#md # Literate.notebook
#md # Literate.script
#md # ```
````
The lines in the example above would be filtered out in the preprocessing step, unless we are
generating a markdown file. When generating a markdown file we would simply remove
the leading `#md ` from the lines. Beware that the space after the tag is also removed.

The `#src` token can also be placed at the *end* of a line. This is to make it possible
to have code lines exclusive to the source code, and not just comment lines. For example,
if the source file is included in the test suite we might want to add a `@test` at the end
without this showing up in the outputs:

```julia
using Test                      #src
@test result == expected_result #src
```


## [**2.3.** Default replacements](@id Default-replacements)

The following convenience "macros"/source placeholders are always expanded:

- `@__NAME__`:

  expands to the `name` keyword argument to [`Literate.markdown`](@ref),
  [`Literate.notebook`](@ref) and [`Literate.script`](@ref)
  (defaults to the filename of the input file).

- `@__REPO_ROOT_URL__`:

  Can be used to link to files in the repository.
  For example `@__REPO_ROOT_URL__/src/Literate.jl` would link to the
  [source of the Literate module](https://github.com/fredrikekre/Literate.jl/blob/master/src/Literate.jl).
  This variable is automatically determined on Travis CI, GitHub Actions and GitLab CI,
  but can be configured, see [Configuration](@ref Configuration).

- `@__NBVIEWER_ROOT_URL__`:

  Can be used if you want a link that opens the generated notebook in
  [http://nbviewer.jupyter.org/](http://nbviewer.jupyter.org/).
  This variable is automatically determined on Travis CI, GitHub Actions and GitLab CI,
  but can be configured, see [Configuration](@ref Configuration).

- `@__BINDER_ROOT_URL__`:

  Can be used if you want a link that opens the generated notebook in
  [https://mybinder.org/](https://mybinder.org/). For example,
  to add a binder-badge in e.g. the HTML output you can use:
  ```
  [![Binder](https://mybinder.org/badge_logo.svg)](@__BINDER_ROOT_URL__/path/to/notebook.inpynb)
  ```
  This variable is automatically determined on Travis CI, GitHub Actions and GitLab CI,
  but can be configured, see [Configuration](@ref Configuration).
