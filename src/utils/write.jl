using JSON

function write(filename::AbstractString, solution::AbstractDict)::Nothing
    @info "Writing solution to $(filename)..."
    open(filename, "w") do file
        JSON.print(file, solution, 2)
    end
    return
end
