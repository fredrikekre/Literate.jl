# # Literate
#
# | **Documentation**                       | **Build Status**                                                                                |
# |:--------------------------------------- |:----------------------------------------------------------------------------------------------- |
# | [![][docs-stable-img]][docs-stable-url] | [![][travis-img]][travis-url] [![][appveyor-img]][appveyor-url] [![][codecov-img]][codecov-url] |
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
Literate.markdown("examples/README.jl", "."; documenter=false)

# [docs-stable-img]: https://img.shields.io/badge/docs-stable%20release-blue.svg
# [docs-stable-url]: https://fredrikekre.github.io/Literate.jl/stable/
#
# [travis-img]: https://travis-ci.org/fredrikekre/Literate.jl.svg?branch=master
# [travis-url]: https://travis-ci.org/fredrikekre/Literate.jl
#
# [appveyor-img]: https://ci.appveyor.com/api/projects/status/xe0ghtyas12wv555/branch/master?svg=true
# [appveyor-url]: https://ci.appveyor.com/project/fredrikekre/Literate-jl/branch/master
#
# [codecov-img]: https://codecov.io/gh/fredrikekre/Literate.jl/branch/master/graph/badge.svg
# [codecov-url]: https://codecov.io/gh/fredrikekre/Literate.jl
#
