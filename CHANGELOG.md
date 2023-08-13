# Literate.jl changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- ## [Unreleased] -->

## [2.14.1] - 2023-08-04
### Fixed
- Update generated `EditURL` to use a relative path instead and let Documenter figure out
  the remote repository. This is required for Documenter version 1, but works also on
  Documenter 0.27. ([#219][github-219])

## [2.14.0] - 2022-09-22
### Changed
- Image filenames resulting from executing markdown files
  (`Literate.markdown(...; execute=true)`) have changed from a number based on
  the hash of the source block to the format
  `{name}-{blocknumber}.(svg|png|...)`. ([#204][github-204],
  [#205][github-205])

## [2.13.4] - 2022-06-03
### Fixed
- Automatic head branch detection (introduced in version 2.11.0) caused a performance
  regression since the `git remote show` command takes ~1 second. For documentation builds
  with many literate files this caused significant slowdowns, which is particularly annoying
  when doing iterative buils with eg.
  [LiveServer.jl](https://github.com/tlienart/LiveServer.jl). Literate now caches the remote
  head branch on a per-repo basis, so the 1 second delay should only be noticed on the first
  run of the first file in a repo. As noted in the changelog entry for 2.11.0 it is also
  possible to specify the head branch by passing the `edit_commit` keyword argument. Doing
  so will now completely skip the slow `git` command. ([8054d26][8054d26])

## [2.13.3] - 2022-05-21
### Fixed
- Update remote HEAD branch detection to use `addenv` instead of `setenv` such that e.g.
  ssh-agent variables are available to the git command. Also set
  `GIT_SSH_COMMAND='ssh -o "BatchMode yes"'` to supress prompts when using ssh.
  ([#197][github-197])

## [2.13.2] - 2022-04-22
### Fixed
- Set current working directory for markdown execution to the output directory, just like
  notebook execution. ([#195][github-195])
- Set the apparent source file to the output file for markdown and notebook execution.
  ([#195][github-195])

## [2.13.1] - 2022-04-12
### Fixed
- Disable git terminal prompt when detecting remote HEAD branch. ([#194][github-194])

## [2.13.0] - 2022-02-18
### Changed
- "Markdown stdlib-style" inline math (e.g. ``` ``f(x) = x^2`` ```) is now replaced with
  "notebook style" math (`$f(x) = x^2$`) for notebook output. This is already the case for
  display math (```` ```math ````). ([#116][github-116], [#190][github-190])
### Fixed
- Lines with trailing `#hide` are not shown in output of Markdown execution with Documenter
  flavor. ([#166][github-166], [#188][github-188])

## [2.12.1] - 2022-02-10
### Fixed
- Make sure Markdown execution picks up new definitions of display methods (by running
  in the latest "world age"). ([#187][github-187])

## [2.12.0] - 2022-02-01
### Changed
- User input configurations can now be `AbstractDict`s instead of just `Dict`s.
  ([#185][github-185], [#186][github-186])

## [2.11.0] - 2022-01-25
### Added
- Literate now tries to figure out the branch/commit that `EditURL` should point to
  automatically instead of always defaulting to `"master"`. For typical setups the
  auto-detection should be sufficient, but you can also set it explicitly by passing
  `edit_commit`, for example `edit_commit = "main"`. ([#179][github-179], [#184][github-184])

## [2.10.0] - 2022-01-24
### Added
- Markdown execution now also support `image/svg+xml`. ([#182][github-182], [#183][github-183])

## [2.9.4] - 2021-10-18
### Fixed
- Fix multiline comment support for `\r\n` line endings. ([#171][github-171], [#172][github-172])

## [2.9.3] - 2021-09-01
### Fixed
- Fix named `@examples` from `Literate.markdown` to not contain spaces even if the source
  filename does. ([#168][github-168], [#169][github-169])

## [2.9.2] - 2021-08-16
### Fixed
- Fix multiline comment support for `\r\n` line endings. ([#165][github-165], [#167][github-167])

## [2.9.1] - 2021-07-30
### Fixed
- Automatic URLs from `@__NBVIEWER_ROOT_URL__` and `@__BINDER_ROOT_URL__` now follow the
  convention [used in Documenter.jl](https://github.com/JuliaDocs/Documenter.jl/pull/1298)
  to ignore build version information. ([#162][github-162], [#163][github-163])

## [2.9.0] - 2021-07-09
### Added
- Added "Franklin flavored" markdown output for usage with [Franklin]
  (https://franklinjl.org/). Enable by passing the `flavor` keyword argument:
  ```julia
  Literate.markdown(...; flavor = Literate.FranklinFlavor())
  ```
  ([#146][github-146], [#147][github-147], [#156][github-156])
- Added "Documenter flavored" markdown output as a replacement for `documenter=true`,
  and "CommonMark flavored" markdown output as a replacement for `documenter=false`.
  Enable by passing the `flavor` keyword argument:
  ```julia
  Literate.markdown(...; flavor = Literate.DocumenterFlavor())
  Literate.markdown(...; flavor = Literate.CommonMarkFlavor())
  ```
  ([#159][github-159])
- Added option to use multiline markdown strings (`md""" ... """`) as markdown sections.
  To enable, pass `mdstrings=true`. ([#152][github-152], [#149][github-149])
### Changed
- The default code fence for markdown output have been changed to 4 (instead of 3)
  backticks to allow input files with 3 backticks, which is common in e.g.
  docstrings or multiline `Cmd`. ([#144][github-144], [#145][github-145])
- Replacement of Documenter-style `@ref` and `@id` elements are now removed unconditionally
  instead of conditionally based on the (now deprecated) `documenter` keyword argument.
  ([#159][github-159])
### Deprecated
- The `documenter` keyword argument has been deprecated. For `Literate.markdown` the
  the replacement is to use `flavor = Literate.DocumenterFlavor()` or
  `flavor = Literate.CommonMarkFlavor()` as appropriate (see above).
  For `Literate.notebook` and `Literate.script` the option is now unused (see above
  regarding `@ref` and `@id`), and no replacement is necessary. ([#159][github-159])

## [2.8] - 2021-01-19
### Added
- Execution of notebooks now capture output of `display(x)` and `display(mime, x)`
  ([ceff7a3][ceff7a3]).

## [2.7] - 2021-09-12
### Added
- Multiline-style Julia comments (`#= ... =#`) can now be used for markdown input
  ([dc409d0][dc409d0]).

## [2.6] - 2020-08-15
### Added
- New end-of-line token `#hide` which filters out the line *after* execution in
  `Literate.markdown(...; execute=true)` ([6d1aec9][6d1aec9]).
- Markdown execution now captures the `text/markdown` MIME ([e08ca0a][e08ca0a]).

## [2.5] - 2020-05-14
### Changed
- The output directory now defaults to `pwd()` ([2ba316a][2ba316a]).

## [2.4] - 2020-04-23
### Added
- Markdown output can now be executed and the result included in the output by pasing
  `execute=true` to `Literate.markdown`. Currently captures the following MIMEs:
  `text/plain`, `image/png`, and `image/jpeg` ([7e89fdb][7e89fdb]).

## [2.3] - 2020-03-03
### Added
- Filter tokens `#md`, `#nb`, and `#jl`, as well as their negated counterparts, can now
  be placed at the end of lines ([b0806ed][b0806ed]).

## [2.2] - 2019-11-26
### Added
- Configuration can now be passed as a `config::Dict` keyword argument to the generators
  ([0f9e836][0f9e836]).
- Link macros now works when running on GitLab CI ([4e71b15][4e71b15]).
- Literate now supports more configuration for e.g. URL's that `@__REPO_ROOT_URL__` and
  friends expand to ([4e71b15][4e71b15]).

## [2.1] - 2019-10-30
### Added
- Link macros now works when running on GitHub Actions ([cf2b552][cf2b552]).

## [2.0] - 2019-07-19
### Added
- Negated filter tokens (`#!nb`, `#!md` and `#!jl`) are now supported ([1d02868][1d02868]).
- Notebook output now support cell metadata with the `%%`-format ([0872a96][0872a96]).
### Changed
- **BREAKING** The link macros `@__REPO_ROOT_URL__`, `@__NBVIEWER_ROOT_URL__`
  and `@__BINDER_ROOT_URL__` no longer include a trailing `/` ([7af5414][7af5414]).
- **BREAKING** The (undocumented) feature of Documenter continued blocks now
  requires an explicit `#+` chunk splitter ([36e8c21][36e8c21]).
- The link macros `@__REPO_ROOT_URL__`, `@__NBVIEWER_ROOT_URL__` now expands to correct
  paths when documentation is built with DocumentationGenerator.jl ([7af5414][7af5414]).

## [1.1] - 2019-04-05
### Added
- New link macro `@__BINDER_ROOT_URL__` for linking to notebooks mybinder.org
  ([fa64dcd][fa64dcd]).

## [1.0] - 2019-03-06
First stable release of Literate.jl, see
https://discourse.julialang.org/t/ann-literate-jl/10651 for release announcement.


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
[2ba316a]: https://github.com/fredrikekre/Literate.jl/commit/2ba316ac90713cc6bdeaeaefd357bb3d847373cb
[e08ca0a]: https://github.com/fredrikekre/Literate.jl/commit/e08ca0a19bd5e61dac778ddf4aaf6cef37532e48
[6d1aec9]: https://github.com/fredrikekre/Literate.jl/commit/6d1aec90b13c6ad888be0fdc77583e9c525b5dc1
[dc409d0]: https://github.com/fredrikekre/Literate.jl/commit/dc409d0f43a6282bee4e28e8e12bb6309942e5d5
[ceff7a3]: https://github.com/fredrikekre/Literate.jl/commit/ceff7a36be2a9152d853257bac97be00d915ba8e
[8054d26]: https://github.com/fredrikekre/Literate.jl/commit/8054d2630b72bc190913b9b92cdb16e367b1ea51

[github-116]: https://github.com/fredrikekre/Literate.jl/issues/116
[github-144]: https://github.com/fredrikekre/Literate.jl/issues/144
[github-145]: https://github.com/fredrikekre/Literate.jl/pull/145
[github-146]: https://github.com/fredrikekre/Literate.jl/pull/146
[github-147]: https://github.com/fredrikekre/Literate.jl/pull/147
[github-149]: https://github.com/fredrikekre/Literate.jl/issues/149
[github-152]: https://github.com/fredrikekre/Literate.jl/pull/152
[github-156]: https://github.com/fredrikekre/Literate.jl/pull/156
[github-159]: https://github.com/fredrikekre/Literate.jl/pull/159
[github-162]: https://github.com/fredrikekre/Literate.jl/issues/162
[github-163]: https://github.com/fredrikekre/Literate.jl/pull/163
[github-165]: https://github.com/fredrikekre/Literate.jl/issues/165
[github-166]: https://github.com/fredrikekre/Literate.jl/issues/166
[github-167]: https://github.com/fredrikekre/Literate.jl/pull/167
[github-168]: https://github.com/fredrikekre/Literate.jl/issues/168
[github-169]: https://github.com/fredrikekre/Literate.jl/pull/169
[github-171]: https://github.com/fredrikekre/Literate.jl/issues/171
[github-172]: https://github.com/fredrikekre/Literate.jl/pull/172
[github-179]: https://github.com/fredrikekre/Literate.jl/issues/179
[github-182]: https://github.com/fredrikekre/Literate.jl/issues/182
[github-183]: https://github.com/fredrikekre/Literate.jl/pull/183
[github-184]: https://github.com/fredrikekre/Literate.jl/pull/184
[github-185]: https://github.com/fredrikekre/Literate.jl/issues/185
[github-186]: https://github.com/fredrikekre/Literate.jl/pull/186
[github-187]: https://github.com/fredrikekre/Literate.jl/pull/187
[github-188]: https://github.com/fredrikekre/Literate.jl/pull/188
[github-190]: https://github.com/fredrikekre/Literate.jl/pull/190
[github-194]: https://github.com/fredrikekre/Literate.jl/pull/194
[github-195]: https://github.com/fredrikekre/Literate.jl/pull/195
[github-197]: https://github.com/fredrikekre/Literate.jl/issues/197
[github-204]: https://github.com/fredrikekre/Literate.jl/issues/204
[github-205]: https://github.com/fredrikekre/Literate.jl/pull/205
[github-219]: https://github.com/fredrikekre/Literate.jl/pull/219

[Unreleased]: https://github.com/fredrikekre/Literate.jl/compare/v2.14.1...HEAD
[2.14.1]: https://github.com/fredrikekre/Literate.jl/compare/v2.14.0...v2.14.1
[2.14.0]: https://github.com/fredrikekre/Literate.jl/compare/v2.13.3...v2.14.0
[2.13.4]: https://github.com/fredrikekre/Literate.jl/compare/v2.13.3...v2.13.4
[2.13.3]: https://github.com/fredrikekre/Literate.jl/compare/v2.13.2...v2.13.3
[2.13.2]: https://github.com/fredrikekre/Literate.jl/compare/v2.13.1...v2.13.2
[2.13.1]: https://github.com/fredrikekre/Literate.jl/compare/v2.13.0...v2.13.1
[2.13.0]: https://github.com/fredrikekre/Literate.jl/compare/v2.12.1...v2.13.0
[2.12.1]: https://github.com/fredrikekre/Literate.jl/compare/v2.12.0...v2.12.1
[2.12.0]: https://github.com/fredrikekre/Literate.jl/compare/v2.11.0...v2.12.0
[2.11.0]: https://github.com/fredrikekre/Literate.jl/compare/v2.10.0...v2.11.0
[2.10.0]: https://github.com/fredrikekre/Literate.jl/compare/v2.9.4...v2.10.0
[2.9.4]: https://github.com/fredrikekre/Literate.jl/compare/v2.9.3...v2.9.4
[2.9.3]: https://github.com/fredrikekre/Literate.jl/compare/v2.9.2...v2.9.3
[2.9.2]: https://github.com/fredrikekre/Literate.jl/compare/v2.9.1...v2.9.2
[2.9.1]: https://github.com/fredrikekre/Literate.jl/compare/v2.9.0...v2.9.1
[2.9.0]: https://github.com/fredrikekre/Literate.jl/compare/v2.8.1...v2.9.0
[2.8]: https://github.com/fredrikekre/Literate.jl/compare/v2.7.0...v2.8.1
[2.7]: https://github.com/fredrikekre/Literate.jl/compare/v2.6.0...v2.7.0
[2.6]: https://github.com/fredrikekre/Literate.jl/compare/v2.5.1...v2.6.0
[2.5]: https://github.com/fredrikekre/Literate.jl/compare/v2.4.0...v2.5.1
[2.4]: https://github.com/fredrikekre/Literate.jl/compare/v2.3.1...v2.4.0
[2.3]: https://github.com/fredrikekre/Literate.jl/compare/v2.2.1...v2.3.1
[2.2]: https://github.com/fredrikekre/Literate.jl/compare/v2.1.1...v2.2.1
[2.1]: https://github.com/fredrikekre/Literate.jl/compare/v2.0.4...v2.1.1
[2.0]: https://github.com/fredrikekre/Literate.jl/compare/v1.1.0...v2.0.4
[1.1]: https://github.com/fredrikekre/Literate.jl/compare/v1.0.5...v1.1.0
[1.0]: https://github.com/fredrikekre/Literate.jl/tree/v1.0.5
