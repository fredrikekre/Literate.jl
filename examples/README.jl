# # Literate
#
# [![Documentation](https://img.shields.io/badge/docs-latest%20release-blue.svg)](https://fredrikekre.github.io/Literate.jl/)
# [![CI](https://github.com/fredrikekre/Literate.jl/actions/workflows/Test.yml/badge.svg?branch=master&event=push)](https://github.com/fredrikekre/Literate.jl/actions/workflows/Test.yml)
# [![Codecov](https://codecov.io/github/fredrikekre/Literate.jl/graph/badge.svg)](https://codecov.io/github/fredrikekre/Literate.jl)
# [![code style: runic](https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black)](https://github.com/fredrikekre/Runic.jl)
#
# Literate is a package for [Literate Programming](https://en.wikipedia.org/wiki/Literate_programming).
# The main purpose is to facilitate writing Julia examples/tutorials that can be included in
# your package documentation.

# Literate can generate markdown pages
# (for e.g. [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)), and
# [Jupyter notebooks](http://jupyter.org/), from the same source file. There is also
# an option to "clean" the source from all metadata, and produce a pure Julia script.
# Using a single source file for multiple purposes reduces maintenance, and makes sure
# your different output formats are synced with each other.
#
# This README was generated directly from
# [this source file](https://github.com/fredrikekre/Literate.jl/blob/master/examples/README.jl)
# running these commands from the package root of Literate.jl:

using Literate
Literate.markdown("examples/README.jl", "."; flavor = Literate.CommonMarkFlavor())


# ### Related packages
#
# - [Weave.jl](https://github.com/JunoLab/Weave.jl) can generate Jupyter notebooks, HTML, or
#   PDF directly from a Markdown format containing Julia code blocks.
# - [Quarto](https://quarto.org) can generate Jupyter notebooks, HTML, or PDF directly from a
#   Markdown format containing Julia code blocks, and also works with R and Python. (Note that
#   Literate.jl can produce Quarto input markdown files (`.qmd`) as well.)
