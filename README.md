# Literate

| **Documentation**         | **Build Status**                                                      |
|:------------------------- |:--------------------------------------------------------------------- |
| [![][docs-img]][docs-url] | [![][gh-actions-img]][gh-actions-url] [![][codecov-img]][codecov-url] |

Literate is a package for [Literate Programming](https://en.wikipedia.org/wiki/Literate_programming).
The main purpose is to facilitate writing Julia examples/tutorials that can be included in
your package documentation.

Literate can generate markdown pages
(for e.g. [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)), and
[Jupyter notebooks](http://jupyter.org/), from the same source file. There is also
an option to "clean" the source from all metadata, and produce a pure Julia script.
Using a single source file for multiple purposes reduces maintenance, and makes sure
your different output formats are synced with each other.

This README was generated directly from
[this source file](https://github.com/fredrikekre/Literate.jl/blob/master/examples/README.jl)
running these commands from the package root of Literate.jl:

````julia
using Literate
Literate.markdown("examples/README.jl", "."; flavor = Literate.CommonMarkFlavor())
````

### Related packages

- [Weave.jl](https://github.com/JunoLab/Weave.jl) can generate Jupyter notebooks, HTML, or
  PDF directly from a Markdown format containing Julia code blocks.
- [Quarto](https://quarto.org) can generate Jupyter notebooks, HTML, or PDF directly from a
  Markdown format containing Julia code blocks, and also works with R and Python. (Note that
  Literate.jl can produce Quarto input markdown files (`.qmd`) as well.)

[docs-img]: https://img.shields.io/badge/docs-latest%20release-blue.svg
[docs-url]: https://fredrikekre.github.io/Literate.jl/

[gh-actions-img]: https://github.com/fredrikekre/Literate.jl/workflows/CI/badge.svg
[gh-actions-url]: https://github.com/fredrikekre/Literate.jl/actions?query=workflow%3ACI

[codecov-img]: https://codecov.io/gh/fredrikekre/Literate.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/fredrikekre/Literate.jl

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

