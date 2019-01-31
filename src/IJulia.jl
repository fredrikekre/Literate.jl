# this file contains some utilities copied from the IJulia.jl package
# (https://github.com/JuliaLang/IJulia.jl), see LICENSE.md for license
module IJulia
import JSON
using Base64

const text_plain = MIME("text/plain")
const image_svg = MIME("image/svg+xml")
const image_png = MIME("image/png")
const image_jpeg = MIME("image/jpeg")
const text_markdown = MIME("text/markdown")
const text_html = MIME("text/html")
const text_latex = MIME("text/latex") # Jupyter expects this
const text_latex2 = MIME("application/x-latex") # but this is more standard?
const application_vnd_vegalite_v2 = MIME("application/vnd.vegalite.v2+json")

# return a String=>String dictionary of mimetype=>data
# for passing to Jupyter display_data and execute_result messages.
function display_dict(x)
    data = Dict{String,Any}("text/plain" => limitstringmime(text_plain, x))
    if showable(application_vnd_vegalite_v2, x)
        data[string(application_vnd_vegalite_v2)] = JSON.parse(limitstringmime(application_vnd_vegalite_v2, x))
    end
    if showable(image_svg, x)
        data[string(image_svg)] = limitstringmime(image_svg, x)
    end
    if showable(image_png, x)
        data[string(image_png)] = limitstringmime(image_png, x)
    elseif showable(image_jpeg, x) # don't send jpeg if we have png
        data[string(image_jpeg)] = limitstringmime(image_jpeg, x)
    end
    if showable(text_markdown, x)
        data[string(text_markdown)] = limitstringmime(text_markdown, x)
    elseif showable(text_html, x)
        data[string(text_html)] = limitstringmime(text_html, x)
    elseif showable(text_latex, x)
        data[string(text_latex)] = limitstringmime(text_latex, x)
    elseif showable(text_latex2, x)
        data[string(text_latex)] = limitstringmime(text_latex2, x)
    end
    return data
end

# need special handling for showing a string as a textmime
# type, since in that case the string is assumed to be
# raw data unless it is text/plain
israwtext(::MIME, x::AbstractString) = true
israwtext(::MIME"text/plain", x::AbstractString) = false
israwtext(::MIME, x) = false

# convert x to a string of type mime, making sure to use an
# IOContext that tells the underlying show function to limit output
function limitstringmime(mime::MIME, x)
    buf = IOBuffer()
    if istextmime(mime)
        if israwtext(mime, x)
            return String(x)
        else
            show(IOContext(buf, :limit=>true, :color=>true), mime, x)
        end
    else
        b64 = Base64EncodePipe(buf)
        if isa(x, Vector{UInt8})
            write(b64, x) # x assumed to be raw binary data
        else
            show(IOContext(b64, :limit=>true, :color=>true), mime, x)
        end
        close(b64)
    end
    return String(take!(buf))
end

end # module
