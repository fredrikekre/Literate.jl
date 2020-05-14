# Literate.jl changelog

## Version `v2.5`

* ![Feature][badge-feature] The output directory now defaults to `pwd()` ([TBD][TBD]).

## Version `v2.4`

* ![Feature][badge-feature] Markdown output can now be executed and the result included
  in the output by pasing `execute=true` to `Literate.markdown.` ([7e89fdb][7e89fdb]).

## Version `v2.3`

* ![Feature][badge-feature] Filter tokens `#md`, `#nb`, and `#jl`, as well as their negated
  counterparts, can now be placed at the end of lines ([b0806ed][b0806ed]).

## Version `v2.2`

* ![Feature][badge-feature] Configuration can now be passed as a `config::Dict`
  keyword argument to the generators ([0f9e836][0f9e836]).

* ![Feature][badge-feature] Link macros now works when running on GitLab CI
  ([4e71b15][4e71b15]).

* ![Feature][badge-feature] Literate now supports more configuration for
  e.g. URL's that `@__REPO_ROOT_URL__` and friends expand to ([4e71b15][4e71b15]).

## Version `v2.1`

* ![Feature][badge-feature] Link macros now works when running on GitHub Actions
  ([cf2b552][cf2b552]).

## Version `v2.0`

* ![BREAKING][badge-breaking] The link macros `@__REPO_ROOT_URL__`, `@__NBVIEWER_ROOT_URL__`
  and `@__BINDER_ROOT_URL__` no longer include a trailing `/` ([7af5414][7af5414]).

* ![BREAKING][badge-breaking] The (undocumented) feature of Documenter continued blocks now
  requires an explicit `#+` chunk splitter ([36e8c21][36e8c21]).

* ![Feature][badge-feature] Negated filter tokens (`#!nb`, `#!md` and `#!jl`) are now
  supported ([1d02868][1d02868]).

* ![Feature][badge-feature] Notebook output now support cell metadata with the `%%`-format
   ([0872a96][0872a96]).

* ![Feature][badge-feature] The link macros `@__REPO_ROOT_URL__`, `@__NBVIEWER_ROOT_URL__`
  now expands to correct paths when documentation is built with DocumentationGenerator.jl
  ([7af5414][7af5414]).

## Version `v1.1`

* ![Feature][badge-feature] New link macro `@__BINDER_ROOT_URL__` for linking to notebooks
  mybinder.org ([fa64dcd][fa64dcd]).

## Version `v1.0`

* First stable release of Literate.jl, see https://discourse.julialang.org/t/ann-literate-jl/10651
  for release announcement.


[7af5414]: https://github.com/fredrikekre/Literate.jl/commit/7af541461672c3098cc99c471377f0d379839fe8
[36e8c21]: https://github.com/fredrikekre/Literate.jl/commit/36e8c210478a8be83ce0b2ce961ecd5c1abc8b45
[1d02868]: https://github.com/fredrikekre/Literate.jl/commit/1d0286818f4946caf84420736cd64608a776d294
[0872a96]: https://github.com/fredrikekre/Literate.jl/commit/0872a96a88dbf3d7647e6e78612cb9b7ed300428
[fa64dcd]: https://github.com/fredrikekre/Literate.jl/commit/fa64dcd796543b2ea8f7e036f397f42549bd87f5
[cf2b552]: https://github.com/fredrikekre/Literate.jl/commit/cf2b5525507217b6552e9c36f63419eddb5df58f
[0f9e836]: https://github.com/fredrikekre/Literate.jl/commit/0f9e836d68f238becd3e193b22ebdad06e4d7ffa
[4e71b15]: https://github.com/fredrikekre/Literate.jl/commit/4e71b159e5ce392c23e6f18116f96803191354c3
[b0806ed]: https://github.com/fredrikekre/Literate.jl/commit/b0806edb6707d03c73bcb0829e96be336229bbeb
[7e89fdb]: https://github.com/fredrikekre/Literate.jl/commit/7e89fdbffdfc56a08caee47287429b4611f85684

[badge-breaking]: https://img.shields.io/badge/BREAKING-red.svg
[badge-deprecation]: https://img.shields.io/badge/deprecation-orange.svg
[badge-feature]: https://img.shields.io/badge/feature-green.svg
[badge-enhancement]: https://img.shields.io/badge/enhancement-blue.svg
[badge-bugfix]: https://img.shields.io/badge/bugfix-purple.svg
[badge-security]: https://img.shields.io/badge/security-black.svg
[badge-experimental]: https://img.shields.io/badge/experimental-lightgrey.svg
[badge-maintenance]: https://img.shields.io/badge/maintenance-gray.svg

<!--
# Badges

![BREAKING][badge-breaking]
![Deprecation][badge-deprecation]
![Feature][badge-feature]
![Enhancement][badge-enhancement]
![Bugfix][badge-bugfix]
![Security][badge-security]
![Experimental][badge-experimental]
![Maintenance][badge-maintenance]
-->
