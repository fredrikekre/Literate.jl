# [**4.** Output formats](@id Output-formats)


## [**4.1.** Markdown output](@id Markdown-output)

````
#' # Markdown                                                  ┐
#'                                                             │
#' This line is treated as markdown, since it starts with #'   │
#' The leading #' (including the space) is removed             ┘

#' Here is an example with some code                           ]

x = sin.(cos.([1, 2, 3]))                                      ┐
y = x.^2 - x                                                   ┘
````

By default, `CodeChunks` written to Documenter `@example` blocks. For example,
the code above would result in the following markdown:

````markdown
# Markdown

This line is treated as markdown, since it starts with #'
The leading #' (including the space) is removed

Here is an example with some code

```@example
x = sin.(cos.([1, 2, 3]))
y = x.^2 - x
```
````

```@docs
Literate.markdown
```

## [**4.2.** Notebook output](@id Notebook-output)

```@docs
Literate.notebook
```


## [**4.3.** Script output](@id Script-output)

```@docs
Literate.script
```
