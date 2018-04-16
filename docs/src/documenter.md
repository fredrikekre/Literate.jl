# [**6.** Interaction with Documenter.jl](@id Interaction-with-Documenter)

`Examples.jl` can be used for any purpose, it spits out regular markdown files,
and notebooks. Typically, though, these files will be used to render documentation
for your package. The generators ([`Examples.markdown`](@ref), [`Examples.notebook`](@ref)
and [`Examples.script`](@ref)) supports a keyword argument `documenter` that lets
the generator perform some extra things, keeping in mind that the generated files will,
eventually, be used with Documenter.jl. So lets take a look at what will happen
if we set `documenter = true`:

[`Examples.markdown`](@ref):
- The default code fence will change from
  ````
  ```julia
  # code
  ```
  ````
  to Documenters `@example` blocks:
  ````
  ```@examples $(name)
  # code
  ```
  ````
- The following `@meta` block will be added to the top of the markdown page,
  which redirects the "Edit on GitHub" link on the top of the page to the
  *source file* rather than the generated `.md` file:
  ````
  ```@meta
  EditURL = "$(relpath(inputfile, outputdir))"
  ```
  ````

[`Examples.notebook`](@ref):
- Documenter style `@ref`s and `@id` will be removed. This means that you can use
  `@ref` and `@id` in the source file without them leaking to the notebook.
- Documenter style markdown math
  ````
  ```math
  \int f dx
  ```
  ````
  is replaced with notebook compatible
  ```
  \begin{equation}
  \int f dx
  \end{equation}
  ```
