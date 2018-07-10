x = 1//3
y = 2//5

x + y

x * y

function foo()
    println("This string is printed to stdout.")
    return [1, 2, 3, 4]
end

foo()

using Plots
x = range(0, stop=6π, length=1000)
y1 = sin.(x)
y2 = cos.(x)
plot(x, [y1, y2])

z = 1.0 + 2.0im

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

