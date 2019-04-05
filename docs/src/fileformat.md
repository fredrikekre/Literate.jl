# **2.** File Format

The source file format for Literate is a regular, commented, julia (`.jl`) scripts.
The idea is that the scripts also serve as documentation on their own and it is also
simple to include them in the test-suite, with e.g. `include`, to make sure the examples
stay up do date with other changes in your package.

## [**2.1.** Syntax](@id Syntax)

The basic syntax is simple:
- lines starting with `# ` are treated as markdown,
- all other lines are treated as julia code.

Leading whitespace is allowed before `#`, but it will be removed when generating the
output. Since `#`-lines is treated as markdown we can not use that for regular julia
comments, for this you can instead use `##`, which will render as `#` in the output.

Lets look at a simple example:
```julia
# # Rational numbers
#
# In julia rational numbers can be constructed with the `//` operator.
# Lets define two rational numbers, `x` and `y`:

x = 1//3
y = 2//5

# When adding `x` and `y` together we obtain a new rational number:

z = x + y
```
In the lines starting with `#` we can use regular markdown syntax, for example the `#`
used for the heading and the backticks for formatting code. The other lines are regular
julia code. We note a couple of things:
- The script is valid julia, which means that we can `include` it and the example will run
  (for example in the `test/runtests.jl` script, to include the example in the test suite).
- The script is "self-explanatory", i.e. the markdown lines works as comments and
  thus serve as good documentation on its own.

For simple use this is all you need to know. The following additional special syntax can also be used:
- `#md`, `#nb`, `#jl`, `#src`: tags to filter lines, see [Filtering Lines](@ref Filtering-Lines),
- `#-`: tag to manually control chunk-splits, see [Custom control over chunk splits](@ref).

There is also some default convenience replacements that will always be performed, see
[Default Replacements](@ref).


## [**2.2.** Filtering Lines](@id Filtering-Lines)

It is often useful to filter out lines in the source depending on the output format.
For this purpose there are a number of "tokens" that can be used to mark the purpose of
certain lines:
- `#md `: line exclusive to markdown output,
- `#nb `: line exclusive to notebook output,
- `#jl `: line exclusive to script output,
- `#src `: line exclusive to the source code and thus filtered out unconditionally.

Lines *starting* with one of these tokens are filtered out in the
[preprocessing step](@ref Pre-processing).

Suppose, for example, that we want to include a docstring within a `@docs` block
using Documenter. Obviously we don't want to include this in the notebook,
since `@docs` is Documenter syntax that the notebook will not understand. This
is a case where we can prepend `#md` to those lines:
````julia
#md # ```@docs
#md # Literate.markdown
#md # Literate.notebook
#md # Literate.markdown
#md # ```
````
The lines in the example above would be filtered out in the preprocessing step, unless we are
generating a markdown file. When generating a markdown file we would simple remove
the leading `#md ` from the lines. Beware that the space after the tag is also removed.

The `#src` token can also be placed at the *end* of a line. This is to make it possible
to have code lines exclusive to the source code, and not just comment lines. For example,
if the source file is included in the test suite we might want to add a `@test` at the end
without this showing up in the outputs:

```julia
using Test                      #src
@test result == expected_result #src
```


## [**2.3.** Default Replacements](@id Default-Replacements)

The following convenience "macros" are always expanded:

- `@__NAME__`

  expands to the `name` keyword argument to [`Literate.markdown`](@ref),
  [`Literate.notebook`](@ref) and [`Literate.script`](@ref)
  (defaults to the filename of the input file).

- `@__REPO__ROOT_URL__`

  expands to `https://github.com/$(ENV["TRAVIS_REPO_SLUG"])/blob/master/`
  and is a convenient way to use when you want to link to files outside the
  doc-build directory. For example `@__REPO__ROOT_URL__src/Literate.jl` would link
  to the source of the Literate module.

- `@__NBVIEWER_ROOT_URL__`

  expands to
  `https://nbviewer.jupyter.org/github/$(ENV["TRAVIS_REPO_SLUG"])/blob/gh-pages/$(folder)/`
  where `folder` is the folder that `Documenter.deploydocs` deploys too.
  This can be used if you want a link that opens the generated notebook in
  [http://nbviewer.jupyter.org/](http://nbviewer.jupyter.org/).

- `@__BINDER_ROOT_URL__`

  expands to
  `https://mybinder.org/v2/gh/$(ENV["TRAVIS_REPO_SLUG"])/$(branch)?filepath=$(folder)/`
  where `branch`/`folder` is the branch and folder where `Documenter.deploydocs`
  deploys too. This can be used if you want a link that opens the generated notebook in
  [https://mybinder.org/](https://mybinder.org/).
  To add a binder-badge in e.g. the HTML output you can use:
  ```
  [![Binder](https://mybinder.org/badge_logo.svg)](@__BINDER_ROOT_URL__path/to/notebook.inpynb)
  ```
