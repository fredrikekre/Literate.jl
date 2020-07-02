# [**7.** Tips and Tricks](@id tips-and-tricks)

This section lists some tips and tricks that might be useful for using
Literate.

### [Filesize of generated notebooks](@id notebook-filesize)

When Literate executes a notebook the return value, i.e. the result of the
last Julia expression in each cell is captured. By default Literate generates
multiple renderings of the result in different output formats or
[MIME](https://en.wikipedia.org/wiki/MIME)s, just like
[IJulia.jl](https://github.com/JuliaLang/IJulia.jl) does. All of these renderings
are embedded in the notebook and it is up to the notebook frontend viewer to select
the most appropriate format to show to the user.

A common example is images, which can often be displayed in multiple formats, e.g. PNG
(`image/png`), SVG (`image/svg+xml`) and HTML (`text/html`). As a result, the filesize of
the generated notebook can become large.

In order to remedy this you can use the clever Julia package
[`DisplayAs`](https://github.com/tkf/DisplayAs.jl) to limit the output capabilities of
and object. For example, to "force" an image to be captures as `image/png` only,
you can use

```julia
import DisplayAs
img = plot(...)
img = DisplayAs.PNG(img)
```

This can save some memory, since the image is never captured in e.g. SVG or
HTML formats.

!!! note
    It is best to always let the object be showable as `text/plain`. This can be achieved
    by nested calls to `DisplayAs` output types. For example, to limit an image `img` to
    be showable as just `image/png` and `text/plain` you can use
    ```julia
    img = plot(...)
    img = DisplayAs.Text(DisplayAs.PNG(img))
    ```

### [Adding admonitions using compound line filtering](@id admonitions-md)

Admonitions are a useful feature for drawing attention to particular elements of 
documentation. They are [documented in Documenter.jl](https://juliadocs.github.io/Documenter.jl/stable/showcase/#Basic-Markdown-1) and an example of their use can be seen above in the blue 'note' box.
They are parsed by Documenter.jl from markdown but their syntax is not parsed
by Julia scripts or notebooks so we need to use the `#md` line filter when
constructing admonitions from `.jl` source files sent to Literate.jl. For example:

```julia
#md # !!! note "Be aware!"
#md #     This a note style admonition!
```

It is important to note that both `#md` and the second `#` are required. Literate.jl
interprets the first `#md` as a markdown exclusive line, and then strips it out. The 
second `#` tells Literate.jl that the line should be parsed as markdown and not a 
Julia code block. If you only include `#md` and not the second `#` then it will 
be parsed into Julia example block in the final documentation and not an actual 
admonition.

### [Custom parsing for markdown and notebook compatible admonitions](@id admonitions-compatibility)

As mentioned above, admonitions are not compatible with Jupyter notebooks.
(Though at time of writing this documentation,
[this is an open issue in Jupyter](https://github.com/jupyter/notebook/issues/1292)
 so may change in the future.) For now, we can write a custom preprocessor function
 so that admonitions are interpreted as quotes (with their own special formatting)
 in notebooks and proper admonitions in markdown. For the case of note admonitions,
 this can be written as follows:

```julia
function md_note(str)
           str = replace(str, r"^#note # (.*)$"m => s"""
           # !!! note
           #     \1""")
           return str
       end

function nb_note(str)
           str = replace(str, r"^#note # (.*)$"m => s"""
           # > *Note*
           # > \1""")
           return str
       end

using Literate

Literate.markdown("example.jl", "tmp/"; preprocess = md_note)

Literate.notebook("example.jl", "tmp/"; preprocess = nb_note)
```

This will allow us to turn the following source code in `example.jl`:

```julia
#note # This is a useful note.
```

into the correct admonition syntax in the markdown file generated:

```julia
!!! note
    This is a useful note.
```

and a quotation style formatting in the generated notebook cell:

```julia
> *Note*
> This is a useful note.
```

which, in an actual notebook cell, will look similar to:

> *Note*\
> This is a useful note.