```@meta
EditURL = "https://github.com/TRAVIS_REPO_SLUG/blob/master/"
```

# Literate

| **Documentation**                       | **Build Status**                                                                                |
|:--------------------------------------- |:----------------------------------------------------------------------------------------------- |
| [![][docs-latest-img]][docs-latest-url] | [![][travis-img]][travis-url] [![][appveyor-img]][appveyor-url] [![][codecov-img]][codecov-url] |

Literate is a package for [Literate Programming](https://en.wikipedia.org/wiki/Literate_programming).
The main purpose is to facilitate writing Julia examples/tutorials that can be included in
your package documentation.

Literate can generate markdown pages
(for e.g. [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)), and
[Jupyter notebooks](http://jupyter.org/), from the same source file. There is also
an option to "clean" the source from all metadata, and produce a pure Julia script.
Using a single source file for multiple purposes reduces maintenance, and makes sure
your different output formats are synced with each other.

This readme is generated directly from this [source file](https://github.com/fredrikekre/Literate.jl) with these two commands:

```@example README
using Literate
Literate.markdown("README.jl", ".")
```

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://fredrikekre.github.io/Literate.jl/stable/

[travis-img]: https://travis-ci.org/fredrikekre/Literate.jl.svg?branch=master
[travis-url]: https://travis-ci.org/fredrikekre/Literate.jl

[appveyor-img]: https://ci.appveyor.com/api/projects/status/xe0ghtyas12wv555/branch/master?svg=true
[appveyor-url]: https://ci.appveyor.com/project/fredrikekre/Literate-jl/branch/master

[codecov-img]: https://codecov.io/gh/fredrikekre/Literate.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/fredrikekre/Literate.jl
#-
*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

