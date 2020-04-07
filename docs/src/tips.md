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
and object. For example, to "force" and image to be captures as `image/png` only,
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
