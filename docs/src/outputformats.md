# [**4.** Output Formats](@id Output-Formats)

When the source is parsed, and have been processed it is time to render the output.
We will consider the following source snippet:

```@eval
import Markdown
Markdown.parse("```julia\n" * rstrip(read("outputformats.jl", String)) * "\n```")
```

and see how this is rendered in each of the output formats.

## [**4.1.** Markdown Output](@id Markdown-Output)

The (default) markdown output of the source snippet above is as follows

```@eval
import Markdown
file = joinpath(@__DIR__, "../src/generated/name.md")
str = "````markdown\n" * rstrip(read(file, String)) * "\n````"
rm(file)
Markdown.parse(str)
```

We note that lines starting with `# ` are printed as regular markdown,
and the code lines have been wrapped in `@example` blocks. We also note that
an `@meta` block have been added, that sets the `EditURL` variable. This is used
by Documenter to redirect the "Edit on GitHub" link for the page,
see [Interaction with Documenter](@ref).

Some of the output rendering can be controlled with keyword arguments to
[`Literate.markdown`](@ref):

```@docs
Literate.markdown
```

## [**4.2.** Notebook Output](@id Notebook-Output)

The (default) notebook output of the source snippet can be seen here:
[notebook.ipynb](generated/notebook.ipynb).

We note that lines starting with `# ` are placed in markdown cells,
and the code lines have been placed in code cells. By default the notebook
is also executed and output cells populated. The current working directory
is set to the specified output directory the notebook is executed.
Some of the output rendering can be controlled with keyword
arguments to [`Literate.notebook`](@ref):

```@docs
Literate.notebook
```

### Notebook metadata

Jupyter notebook cells (both code cells and markdown cells) can contain metadata. This is enabled
in Literate by the `%%` token, similar to
[Jupytext](https://jupytext.readthedocs.io/en/latest/formats.html#the-percent-format).
The format is as follows

```
%% optional ignored text [type] {optional metadata JSON}
```

Cell metadata can, for example, be used for
[nbgrader](https://nbgrader.readthedocs.io/en/stable/contributor_guide/metadata.html)
and the [reveal.js](https://github.com/hakimel/reveal.js) notebook extension
[RISE](https://github.com/damianavila/RISE).


## [**4.3.** Script Output](@id Script-Output)

The (default) script output of the source snippet above is as follows

```@eval
import Markdown
file = joinpath(@__DIR__,  "../src/generated/outputformats.jl")
str = "```julia\n" * rstrip(read(file, String)) * "\n```"
rm(file)
Markdown.parse(str)
```

We note that lines starting with `# ` are removed and only the
code lines have been kept. Some of the output rendering can be controlled
with keyword arguments to [`Literate.script`](@ref):

```@docs
Literate.script
```
