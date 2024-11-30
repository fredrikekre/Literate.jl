# ---
# title: "Quarto Report Demo"
# author: "Zoro"
# date: "1/1/1900"
# format:
#   html:
#     code-fold: true
# engine: julia
# ---

# # Header 1
# For reproducibility, we first activate the project environment and add the necessary packages
# In practice, you can re-use your project environment - see examples with julia.exeflags
using Pkg; Pkg.activate(".", io=devnull)
Pkg.add(["DataFrames", "StatsPlots"])
using DataFrames, StatsPlots

# # Header 2
# I am a text

# There is a plot:
df = DataFrame(a=1:10, b=10 .* rand(10), c=10 .* rand(10))
@df df plot(:a, [:b :c], colour=[:red :blue])

# ## Sub-header

# I am a text explaining the second plot:
@df df scatter(:a, :b, markersize=4 .* log.(:c .+ 0.1))

# # Header 3

# Example of mixing markdown and code
##|echo: false
## We could suppress printing the number by adding semicolon, but echo: false is a quarto way to hide outputs
my_number=5

# Output cell:
##| output: asis
println("I will be formatted as a markdown. My number is: $my_number")

# The following lines will be removed from the report
# They show you how to execute this report
## This is how you convert this report into an HTML file #src
using Literate #src
Literate.markdown("quarto_report.jl", flavor = Literate.QuartoFlavor()) #src
## The open your commandline and run the following command: #src
## quarto render quarto_report.qmd --to html #src
## or #src
run(`quarto render quarto_report.qmd --to html`) #src
