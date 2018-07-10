using Pkg
Pkg.add("Coverage")
using Coverage
cd(joinpath(@__DIR__, "..")) do
    Codecov.submit(Codecov.process_folder())
end
