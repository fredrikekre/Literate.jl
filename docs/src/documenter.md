# [**6.** Interaction with Documenter.jl](@id Interaction-with-Documenter)

Literate can be used for any purpose, it spits out regular markdown files,
and notebooks. Typically, though, these files will be used to render documentation
for your package. The generators ([`Literate.markdown`](@ref), [`Literate.notebook`](@ref)
and [`Literate.script`](@ref)) supports a keyword argument `documenter` that lets
the generator perform some extra things, keeping in mind that the source code have been
written with Documenter.jl in mind. So let's take a look at what will happen
if we set `documenter = true`:

### [`Literate.markdown`](@ref):
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

### [`Literate.notebook`](@ref):
- Documenter style `@ref`s, `@extref`s and `@id` will be removed. This means that you can use
  `@ref`, `@extref` and `@id` in the source file without them leaking to the notebook.
- Documenter style markdown math
  ````
  ```math
  \int f dx
  ```
  ````
  is replaced with notebook compatible
  ```
  $$
  \int f dx
  $$
  ```
- Documenter style admonitions
  ```
  !!! note
      An interesting note.

  !!! warning "Warning title text"
      An important warning.
  ```
  are replaced with notebook compatible quote blocks
  ```
  > **Note**
  >
  > An interesting note.

  > **Warning title text**
  >
  > An important warning.
  ```
- Whereas Documenter requires HTML blocks to be escaped
  ````
  ```@raw html
  <tag>...</tag>
  ```
  ````
  the output to a notebook markdown cell will be raw HTML
  ```
  <tag>...</tag>
  ```

### [`Literate.script`](@ref):
- Documenter style `@ref`s, `@extref`s and `@id` will be removed. This means that you can use
  `@ref`, `@extref` and `@id` in the source file without them leaking to the script.
