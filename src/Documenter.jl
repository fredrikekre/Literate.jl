# copied from Documenter.jl
module Documenter

@static if VERSION < v"0.7.0-DEV.3951"
    link_pipe!(pipe; reader_supports_async = true, writer_supports_async = true) =
        Base.link_pipe(pipe, julia_only_read = reader_supports_async, julia_only_write = writer_supports_async)
else
    import Base: link_pipe!
end
@static if isdefined(Base, :with_logger)
    using Logging
else # make things a no-op since warnings/info already print to stdout
    struct ConsoleLogger end
    ConsoleLogger(io) = ConsoleLogger()
    with_logger(f, logger) = f()
end

function withoutput(f)
    # Save the default output streams.
    default_stdout = stdout
    default_stderr = stderr

    # Redirect both the `stdout` and `stderr` streams to a single `Pipe` object.
    pipe = Pipe()
    link_pipe!(pipe; reader_supports_async = true, writer_supports_async = true)
    redirect_stdout(pipe.in)
    redirect_stderr(pipe.in)
    # Also redirect logging stream to the same pipe
    logger = ConsoleLogger(pipe.in)

    # Bytes written to the `pipe` are captured in `output` and converted to a `String`.
    output = UInt8[]

    # Run the function `f`, capturing all output that it might have generated.
    # Success signals whether the function `f` did or did not throw an exception.
    result, success, backtrace = with_logger(logger) do
        try
            f(), true, Vector{Ptr{Cvoid}}()
        catch err
            err, false, catch_backtrace()
        finally
            # Force at least a single write to `pipe`, otherwise `readavailable` blocks.
            println()
            # Restore the original output streams.
            redirect_stdout(default_stdout)
            redirect_stderr(default_stderr)
            # NOTE: `close` must always be called *after* `readavailable`.
            append!(output, readavailable(pipe))
            close(pipe)
        end
    end
    return result, success, backtrace, chomp(String(output))
end

end
