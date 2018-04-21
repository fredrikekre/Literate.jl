# [**4.** Output Formats](@id Output-Formats)

When the source is parsed, and have been processed it is time to render the output.
We will consider the following source snippet:

```julia
#' # Rational numbers
#'
#' In julia rational numbers can be constructed with the `//` operator.
#' Lets define two rational numbers, `x` and `y`:

x = 1//3
#-
y = 2//5

#' When adding `x` and `y` together we obtain a new rational number:

z = x + y
```

and see how this is rendered in each of the output formats.

## [**4.1.** Markdown Output](@id Markdown-Output)

The (default) markdown output of the source snippet above is as follows

````markdown
# Rational numbers

In julia rational numbers can be constructed with the `//` operator.
Lets define two rational numbers, `x` and `y`:

```@example name
x = 1//3
```

```@example name
y = 2//5
```

When adding `x` and `y` together we obtain a new rational number:

```@example name
z = x + y
```
````

We note that lines starting with `#'` is printed as regular markdown,
and the code lines have been wrapped in `@example` blocks.

Some of the output rendering can be controlled with keyword arguments to
[`Literate.markdown`](@ref):

```@docs
Literate.markdown
```

## [**4.2.** Notebook Output](@id Notebook-Output)

The (default) notebook output of the source snippet above is as follows

```
        │ # Rational numbers
        │
        │ In julia rational numbers can be constructed with the `//` operator.
        │ Lets define two rational numbers, `x` and `y`:

In[1]:  │ x = 1//3
Out[1]: │ 1//3

In[2]:  │ y = 2//5
Out[2]: │ 2//5

        │ When adding `x` and `y` together we obtain a new rational number:

In[3]:  │ z = x + y
Out[3]: │ 11/15
```

We note that lines starting with `#'` is put in markdown cells,
and the code lines have been put in code cells. By default the notebook
is also executed and output cells populated. The current working directory
is set to the specified output directory the notebook is executed.
Some of the output rendering can be controlled with keyword
arguments to [`Literate.notebook`](@ref):

```@docs
Literate.notebook
```


## [**4.3.** Script Output](@id Script-Output)

The (default) script output of the source snippet above is as follows

```julia
x = 1//3

y = 2//5

z = x + y
```

We note that lines starting with `#'` are removed and only the
code lines have been kept. Some of the output rendering can be controlled
with keyword arguments to [`Literate.script`](@ref):

```@docs
Literate.script
```
