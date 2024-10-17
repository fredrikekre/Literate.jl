# Literate.jl changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
### Fixed
 - Errors from code evaluation (with `continue_on_error = true`) are now properly displayed
   with `showerror`. ([#261])

## [v2.20.0] - 2024-10-16
### Added
 - A new keyword argument configuration `continue_on_error::Bool = false` has been added
   which controls the behavior of code execution errors. By default (`continue_on_error =
   false`) execution errors are re-thrown by Literate (as before). If `continue_on_error =
   true` is set the error is used as the block result and execution continues with following
   blocks. ([#201], [#257])
 - Literate now replaces Documenter-style admonitions when generating notebook output
   ([#259]). Concretely,
   ```
   # !!! note
   #     A note.

   # !!! warn "Warning title text"
   #     A warning.
   ```
   is replaced with
   ```
   # > **Note**
   # >
   # > A note.

   # > **Warning title text**
   # >
   # > A warning.
   ```

## [v2.19.1] - 2024-09-13
### Fixed
 - Set `:SOURCE_PATH` in the task local storage to the output file when executing code so
   that recursive `include` works as expected. ([#251], [#252])

## [v2.19.0] - 2024-07-11
### Changed
 - `Literate.markdown`, `Literate.notebook`, and `Literate.script` are marked as `public` in
   Julia version that support the `public` keyword. ([#248])

## [v2.18.0] - 2024-04-17
### Added
 - Literate will now remove
   [DocumenterInterlinks.jl](https://github.com/JuliaDocs/DocumenterInterLinks.jl)
   `@extref` links similarly to how Documenter.jl `@ref` and `@id`'s are
   removed. ([#245])

## [v2.17.0] - 2024-04-14
### Added
 - Literate can now output [Quarto](https://quarto.org/) notebooks (markdown documents with
   the `.qmd` file extension) by passing `flavor = Literate.QuartoFlavor()` to
   `Literate.markdown`. This feature is marked as experimental since it has not been widely
   tested and the Quarto-specific syntax may change before Literate version 3 depending on
   what the community wants or needs. ([#199], [#200])

## [v2.16.1] - 2024-01-04
### Fixed
- Fix removal of Documenter-style `@ref` links spanning multiple lines. ([#224],
  [#233])

## [v2.16.0] - 2023-11-08
### Added
- "Soft" scoping rules (see e.g. <https://github.com/JuliaLang/SoftGlobalScope.jl>) are now
  available for code execution (markdown and notebook output). This is enabled by default
  for Jupyter notebook output (to mimic how the IJulia kernel works), and disabled
  otherwise. Soft scope rules can be enabled/disabled with the `softscope :: Bool`
  configuration variable. ([#227], [#230])
### Changed
- The minimum Julia version requirement for Literate >= 2.16.0 is now 1.6.0 (from 1.0.0).
  ([#230])

## [v2.15.1] - 2023-11-08
### Fixed
- Fix a bug where `Literate.markdown` with `execute=true` would (try to) output images in
  the wrong directory. This only occured when passing a relative output directory.
  ([#228], [#229])

## [v2.15.0] - 2023-09-05
### Added
- Documenter style `@raw html` blocks are automatically handled in Jupyter notebook output
  (similar to how Documenter style ` ```math ` blocks are rewritten to `$$` blocks).
  ([#222], [#223])

## [v2.14.2] - 2023-08-28
### Fixed
- Remove double newline in `Literate.script` output. ([#221])

## [v2.14.1] - 2023-08-04
### Fixed
- Update generated `EditURL` to use a relative path instead and let Documenter figure out
  the remote repository. This is required for Documenter version 1, but works also on
  Documenter 0.27. ([#219])

## [v2.14.0] - 2022-09-22
### Changed
- Image filenames resulting from executing markdown files
  (`Literate.markdown(...; execute=true)`) have changed from a number based on
  the hash of the source block to the format
  `{name}-{blocknumber}.(svg|png|...)`. ([#204],
  [#205])

## [v2.13.4] - 2022-06-03
### Fixed
- Automatic head branch detection (introduced in version 2.11.0) caused a performance
  regression since the `git remote show` command takes ~1 second. For documentation builds
  with many literate files this caused significant slowdowns, which is particularly annoying
  when doing iterative buils with eg.
  [LiveServer.jl](https://github.com/tlienart/LiveServer.jl). Literate now caches the remote
  head branch on a per-repo basis, so the 1 second delay should only be noticed on the first
  run of the first file in a repo. As noted in the changelog entry for 2.11.0 it is also
  possible to specify the head branch by passing the `edit_commit` keyword argument. Doing
  so will now completely skip the slow `git` command. ([8054d26])

## [v2.13.3] - 2022-05-21
### Fixed
- Update remote HEAD branch detection to use `addenv` instead of `setenv` such that e.g.
  ssh-agent variables are available to the git command. Also set
  `GIT_SSH_COMMAND='ssh -o "BatchMode yes"'` to supress prompts when using ssh.
  ([#197])

## [v2.13.2] - 2022-04-22
### Fixed
- Set current working directory for markdown execution to the output directory, just like
  notebook execution. ([#195])
- Set the apparent source file to the output file for markdown and notebook execution.
  ([#195])

## [v2.13.1] - 2022-04-12
### Fixed
- Disable git terminal prompt when detecting remote HEAD branch. ([#194])

## [v2.13.0] - 2022-02-18
### Changed
- "Markdown stdlib-style" inline math (e.g. ``` ``f(x) = x^2`` ```) is now replaced with
  "notebook style" math (`$f(x) = x^2$`) for notebook output. This is already the case for
  display math (```` ```math ````). ([#116], [#190])
### Fixed
- Lines with trailing `#hide` are not shown in output of Markdown execution with Documenter
  flavor. ([#166], [#188])

## [v2.12.1] - 2022-02-10
### Fixed
- Make sure Markdown execution picks up new definitions of display methods (by running
  in the latest "world age"). ([#187])

## [v2.12.0] - 2022-02-01
### Changed
- User input configurations can now be `AbstractDict`s instead of just `Dict`s.
  ([#185], [#186])

## [v2.11.0] - 2022-01-25
### Added
- Literate now tries to figure out the branch/commit that `EditURL` should point to
  automatically instead of always defaulting to `"master"`. For typical setups the
  auto-detection should be sufficient, but you can also set it explicitly by passing
  `edit_commit`, for example `edit_commit = "main"`. ([#179], [#184])

## [v2.10.0] - 2022-01-24
### Added
- Markdown execution now also support `image/svg+xml`. ([#182], [#183])

## [v2.9.4] - 2021-10-18
### Fixed
- Fix multiline comment support for `\r\n` line endings. ([#171], [#172])

## [v2.9.3] - 2021-09-01
### Fixed
- Fix named `@examples` from `Literate.markdown` to not contain spaces even if the source
  filename does. ([#168], [#169])

## [v2.9.2] - 2021-08-16
### Fixed
- Fix multiline comment support for `\r\n` line endings. ([#165], [#167])

## [v2.9.1] - 2021-07-30
### Fixed
- Automatic URLs from `@__NBVIEWER_ROOT_URL__` and `@__BINDER_ROOT_URL__` now follow the
  convention [used in Documenter.jl](https://github.com/JuliaDocs/Documenter.jl/pull/1298)
  to ignore build version information. ([#162], [#163])

## [v2.9.0] - 2021-07-09
### Added
- Added "Franklin flavored" markdown output for usage with [Franklin]
  (https://franklinjl.org/). Enable by passing the `flavor` keyword argument:
  ```julia
  Literate.markdown(...; flavor = Literate.FranklinFlavor())
  ```
  ([#146], [#147], [#156])
- Added "Documenter flavored" markdown output as a replacement for `documenter=true`,
  and "CommonMark flavored" markdown output as a replacement for `documenter=false`.
  Enable by passing the `flavor` keyword argument:
  ```julia
  Literate.markdown(...; flavor = Literate.DocumenterFlavor())
  Literate.markdown(...; flavor = Literate.CommonMarkFlavor())
  ```
  ([#159])
- Added option to use multiline markdown strings (`md""" ... """`) as markdown sections.
  To enable, pass `mdstrings=true`. ([#152], [#149])
### Changed
- The default code fence for markdown output have been changed to 4 (instead of 3)
  backticks to allow input files with 3 backticks, which is common in e.g.
  docstrings or multiline `Cmd`. ([#144], [#145])
- Replacement of Documenter-style `@ref` and `@id` elements are now removed unconditionally
  instead of conditionally based on the (now deprecated) `documenter` keyword argument.
  ([#159])
### Deprecated
- The `documenter` keyword argument has been deprecated. For `Literate.markdown` the
  the replacement is to use `flavor = Literate.DocumenterFlavor()` or
  `flavor = Literate.CommonMarkFlavor()` as appropriate (see above).
  For `Literate.notebook` and `Literate.script` the option is now unused (see above
  regarding `@ref` and `@id`), and no replacement is necessary. ([#159])

## v2.8 - 2021-01-19
### Added
- Execution of notebooks now capture output of `display(x)` and `display(mime, x)`
  ([ceff7a3]).

## v2.7 - 2021-09-12
### Added
- Multiline-style Julia comments (`#= ... =#`) can now be used for markdown input
  ([dc409d0]).

## v2.6 - 2020-08-15
### Added
- New end-of-line token `#hide` which filters out the line *after* execution in
  `Literate.markdown(...; execute=true)` ([6d1aec9]).
- Markdown execution now captures the `text/markdown` MIME ([e08ca0a]).

## v2.5 - 2020-05-14
### Changed
- The output directory now defaults to `pwd()` ([2ba316a]).

## v2.4 - 2020-04-23
### Added
- Markdown output can now be executed and the result included in the output by pasing
  `execute=true` to `Literate.markdown`. Currently captures the following MIMEs:
  `text/plain`, `image/png`, and `image/jpeg` ([7e89fdb]).

## v2.3 - 2020-03-03
### Added
- Filter tokens `#md`, `#nb`, and `#jl`, as well as their negated counterparts, can now
  be placed at the end of lines ([b0806ed]).

## v2.2 - 2019-11-26
### Added
- Configuration can now be passed as a `config::Dict` keyword argument to the generators
  ([0f9e836]).
- Link macros now works when running on GitLab CI ([4e71b15]).
- Literate now supports more configuration for e.g. URL's that `@__REPO_ROOT_URL__` and
  friends expand to ([4e71b15]).

## v2.1 - 2019-10-30
### Added
- Link macros now works when running on GitHub Actions ([cf2b552]).

## v2.0 - 2019-07-19
### Added
- Negated filter tokens (`#!nb`, `#!md` and `#!jl`) are now supported ([1d02868]).
- Notebook output now support cell metadata with the `%%`-format ([0872a96]).
### Changed
- **BREAKING** The link macros `@__REPO_ROOT_URL__`, `@__NBVIEWER_ROOT_URL__`
  and `@__BINDER_ROOT_URL__` no longer include a trailing `/` ([7af5414]).
- **BREAKING** The (undocumented) feature of Documenter continued blocks now
  requires an explicit `#+` chunk splitter ([36e8c21]).
- The link macros `@__REPO_ROOT_URL__`, `@__NBVIEWER_ROOT_URL__` now expands to correct
  paths when documentation is built with DocumentationGenerator.jl ([7af5414]).

## v1.1 - 2019-04-05
### Added
- New link macro `@__BINDER_ROOT_URL__` for linking to notebooks mybinder.org
  ([fa64dcd]).

## v1.0 - 2019-03-06
First stable release of Literate.jl, see
https://discourse.julialang.org/t/ann-literate-jl/10651 for release announcement.


<!-- Links generated by Changelog.jl -->

[v2.9.0]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.9.0
[v2.9.1]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.9.1
[v2.9.2]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.9.2
[v2.9.3]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.9.3
[v2.9.4]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.9.4
[v2.10.0]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.10.0
[v2.11.0]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.11.0
[v2.12.0]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.12.0
[v2.12.1]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.12.1
[v2.13.0]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.13.0
[v2.13.1]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.13.1
[v2.13.2]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.13.2
[v2.13.3]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.13.3
[v2.13.4]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.13.4
[v2.14.0]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.14.0
[v2.14.1]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.14.1
[v2.14.2]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.14.2
[v2.15.0]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.15.0
[v2.15.1]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.15.1
[v2.16.0]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.16.0
[v2.16.1]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.16.1
[v2.17.0]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.17.0
[v2.18.0]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.18.0
[v2.19.0]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.19.0
[v2.19.1]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.19.1
[v2.20.0]: https://github.com/fredrikekre/Literate.jl/releases/tag/v2.20.0
[#116]: https://github.com/fredrikekre/Literate.jl/issues/116
[#144]: https://github.com/fredrikekre/Literate.jl/issues/144
[#145]: https://github.com/fredrikekre/Literate.jl/issues/145
[#146]: https://github.com/fredrikekre/Literate.jl/issues/146
[#147]: https://github.com/fredrikekre/Literate.jl/issues/147
[#149]: https://github.com/fredrikekre/Literate.jl/issues/149
[#152]: https://github.com/fredrikekre/Literate.jl/issues/152
[#156]: https://github.com/fredrikekre/Literate.jl/issues/156
[#159]: https://github.com/fredrikekre/Literate.jl/issues/159
[#162]: https://github.com/fredrikekre/Literate.jl/issues/162
[#163]: https://github.com/fredrikekre/Literate.jl/issues/163
[#165]: https://github.com/fredrikekre/Literate.jl/issues/165
[#166]: https://github.com/fredrikekre/Literate.jl/issues/166
[#167]: https://github.com/fredrikekre/Literate.jl/issues/167
[#168]: https://github.com/fredrikekre/Literate.jl/issues/168
[#169]: https://github.com/fredrikekre/Literate.jl/issues/169
[#171]: https://github.com/fredrikekre/Literate.jl/issues/171
[#172]: https://github.com/fredrikekre/Literate.jl/issues/172
[#179]: https://github.com/fredrikekre/Literate.jl/issues/179
[#182]: https://github.com/fredrikekre/Literate.jl/issues/182
[#183]: https://github.com/fredrikekre/Literate.jl/issues/183
[#184]: https://github.com/fredrikekre/Literate.jl/issues/184
[#185]: https://github.com/fredrikekre/Literate.jl/issues/185
[#186]: https://github.com/fredrikekre/Literate.jl/issues/186
[#187]: https://github.com/fredrikekre/Literate.jl/issues/187
[#188]: https://github.com/fredrikekre/Literate.jl/issues/188
[#190]: https://github.com/fredrikekre/Literate.jl/issues/190
[#194]: https://github.com/fredrikekre/Literate.jl/issues/194
[#195]: https://github.com/fredrikekre/Literate.jl/issues/195
[#197]: https://github.com/fredrikekre/Literate.jl/issues/197
[#199]: https://github.com/fredrikekre/Literate.jl/issues/199
[#200]: https://github.com/fredrikekre/Literate.jl/issues/200
[#201]: https://github.com/fredrikekre/Literate.jl/issues/201
[#204]: https://github.com/fredrikekre/Literate.jl/issues/204
[#205]: https://github.com/fredrikekre/Literate.jl/issues/205
[#219]: https://github.com/fredrikekre/Literate.jl/issues/219
[#221]: https://github.com/fredrikekre/Literate.jl/issues/221
[#222]: https://github.com/fredrikekre/Literate.jl/issues/222
[#223]: https://github.com/fredrikekre/Literate.jl/issues/223
[#224]: https://github.com/fredrikekre/Literate.jl/issues/224
[#227]: https://github.com/fredrikekre/Literate.jl/issues/227
[#228]: https://github.com/fredrikekre/Literate.jl/issues/228
[#229]: https://github.com/fredrikekre/Literate.jl/issues/229
[#230]: https://github.com/fredrikekre/Literate.jl/issues/230
[#233]: https://github.com/fredrikekre/Literate.jl/issues/233
[#245]: https://github.com/fredrikekre/Literate.jl/issues/245
[#248]: https://github.com/fredrikekre/Literate.jl/issues/248
[#251]: https://github.com/fredrikekre/Literate.jl/issues/251
[#252]: https://github.com/fredrikekre/Literate.jl/issues/252
[#257]: https://github.com/fredrikekre/Literate.jl/issues/257
[#259]: https://github.com/fredrikekre/Literate.jl/issues/259
[0872a96]: https://github.com/fredrikekre/Literate.jl/commit/0872a96
[0f9e836]: https://github.com/fredrikekre/Literate.jl/commit/0f9e836
[1d02868]: https://github.com/fredrikekre/Literate.jl/commit/1d02868
[2ba316a]: https://github.com/fredrikekre/Literate.jl/commit/2ba316a
[36e8c21]: https://github.com/fredrikekre/Literate.jl/commit/36e8c21
[4e71b15]: https://github.com/fredrikekre/Literate.jl/commit/4e71b15
[6d1aec9]: https://github.com/fredrikekre/Literate.jl/commit/6d1aec9
[7af5414]: https://github.com/fredrikekre/Literate.jl/commit/7af5414
[7e89fdb]: https://github.com/fredrikekre/Literate.jl/commit/7e89fdb
[8054d26]: https://github.com/fredrikekre/Literate.jl/commit/8054d26
[b0806ed]: https://github.com/fredrikekre/Literate.jl/commit/b0806ed
[ceff7a3]: https://github.com/fredrikekre/Literate.jl/commit/ceff7a3
[cf2b552]: https://github.com/fredrikekre/Literate.jl/commit/cf2b552
[dc409d0]: https://github.com/fredrikekre/Literate.jl/commit/dc409d0
[e08ca0a]: https://github.com/fredrikekre/Literate.jl/commit/e08ca0a
[fa64dcd]: https://github.com/fredrikekre/Literate.jl/commit/fa64dcd
