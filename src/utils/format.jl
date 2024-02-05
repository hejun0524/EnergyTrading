using JuliaFormatter

function format()
    basedir = dirname(@__FILE__)
    @show basedir
    JuliaFormatter.format(basedir, verbose = true)
    JuliaFormatter.format("$basedir/../../src", verbose = true)
    return
end
