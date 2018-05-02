# **3.** Processing pipeline

The generation of output follows the same pipeline for all output formats:
1. [Pre-processing](@ref)
2. [Parsing](@ref)
3. [Document generation](@ref)
4. [Post-processing](@ref)
5. [Writing to file](@ref)


## [**3.1.** Pre-processing](@id Pre-processing)

The first step is pre-processing of the input file. The file is read to a `String`.
The first processing step is to apply the user specified pre-processing function,
see [Custom pre- and post-processing](@ref Custom-pre-and-post-processing).

The next step is to perform all of the built-in default replacements.
CRLF style line endings (`"\r\n"`) are replaced with LF line endings (`"\n"`) to simplify
internal processing. Next, line filtering is performed, see [Filtering Lines](@ref),
meaning that lines starting with `#md `, `#nb ` or `#jl ` are handled (either just
the token itself is removed, or the full line, depending on the output target).
The last pre-processing step is to expand the convenience "macros" described
in [Default Replacements](@ref) is expanded.


## [**3.2.** Parsing](@id Parsing)

After the preprocessing the file is parsed. The first step is to categorize each line
and mark them as either markdown or code according to the rules described in the
[Syntax](@ref Syntax) section. Lets consider the example from the previous section
with each line categorized:
```
# # Rational numbers                                                     <- markdown
#                                                                        <- markdown
# In julia rational numbers can be constructed with the `//` operator.   <- markdown
# Lets define two rational numbers, `x` and `y`:                         <- markdown
                                                                         <- code
x = 1 // 3                                                               <- code
y = 2 // 5                                                               <- code
                                                                         <- code
# When adding `x` and `y` together we obtain a new rational number:      <- markdown
                                                                         <- code
z = x + y                                                                <- code
```

In the next step the lines are grouped into "chunks" of markdown and code.
This is done by simply collecting adjacent lines of the same "type" into
chunks:
```
# # Rational numbers                                                     ┐
#                                                                        │
# In julia rational numbers can be constructed with the `//` operator.   │ markdown
# Lets define two rational numbers, `x` and `y`:                         ┘
                                                                         ┐
x = 1 // 3                                                               │
y = 2 // 5                                                               │ code
                                                                         ┘
# When adding `x` and `y` together we obtain a new rational number:      ] markdown
                                                                         ┐
z = x + y                                                                ┘ code
```

In the last parsing step all empty leading and trailing lines for each chunk
are removed, but empty lines *within the same* block are kept. The leading `# `
tokens are also removed from the markdown chunks. Finally we would
end up with the following 4 chunks:

Chunks #1:
```markdown
# Rational numbers

In julia rational numbers can be constructed with the `//` operator.
Lets define two rational numbers, `x` and `y`:
```
Chunk #2:
```julia
x = 1 // 3
y = 2 // 5
```
Chunk #3:
```markdown
When adding `x` and `y` together we obtain a new rational number:
```
Chunk #4:
```julia
z = x + y
```

It is then up to the [Document generation](@ref) step to decide how these chunks should be treated.

### Custom control over chunk splits

Sometimes it is convenient to be able to manually control how the chunks are split.
For example, if you want to split a block of code into two, such that they end up in
two different `@example` blocks or notebook cells. The `#-` token can be used for this
purpose. All lines starting with `#-` are used as "chunk-splitters":
```julia
x = 1 // 3
y = 2 // 5
#-
z = x + y
```
The example above would result in two consecutive code-chunks.

!!! tip
    The rest of the line, after `#-`, is discarded, so it is possible to use e.g.
    `#-------------` as a chunk splitter, which may make the source code more readable.


## [**3.3.** Document generation](@id Document-generation)

After the parsing it is time to generate the output. What is done in this step is
very different depending on the output target, and it is describe in more detail in
the Output format sections: [Markdown Output](@ref), [Notebook Output](@ref) and
[Script Output](@ref). Using the default settings, the following is happening:

* Markdown output: markdown chunks are printed as-is, code chunks are put inside
  a code fence (defaults to `@example`-blocks),
* Notebook output: markdown chunks are printed in markdown cells, code chunks are
  put in code cells,
* Script output: markdown chunks are discarded, code chunks are printed as-is.


## [**3.4.** Post-processing](@id Post-processing)

When the document is generated the user, again, has the option to hook-into the generation
with a custom post-processing function. The reason is that one might want to change
things that are only visible in the rendered document.
See [Custom pre- and post-processing](@ref Custom-pre-and-post-processing).


## [**3.5.** Writing to file](@id Writing-to-file)

The last step of the generation is writing to file. The result is written to
`$(outputdir)/$(name)(.md|.ipynb|.jl)` where `outputdir` is the output directory supplied
by the user (for example `docs/generated`), and `name` is a user supplied filename.
It is recommended to add the output directory to `.gitignore` since the idea is that
the generated documents will be generated as part of the build process rather than
beeing files in the repo.
