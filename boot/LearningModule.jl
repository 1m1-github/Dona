module LearningModule

export learn

"`learn` will wrap the code into a Module and save it to long memory, even add to boot if set. This should only be used for reliable, tested code and usually only when explicitly agreed to by all relevant parties."
function learn(name::Symbol, exports::Vector{Symbol}, pkgs::Vector{Symbol}, code::String, boot=false)
    mname = "$(name)Module"
    m = """
    module $mname
    export $(join(exports,','))
    import Main: @install
    @install $(join(pkgs,','))
    $code
    end
    using .$mname
    """
    expr = Meta.parseall(m)
    expr.head == :incomplete && throw(expr.args[1])
    Base.eval(Main, expr)
    # todo maybe check that @test used in `code`
    write(joinpath(Main.STORAGE, "$mname.jl"), m)
    boot && write(joinpath(Main.BOOTDIR, "$mname.jl"), m)
end

end
using .LearningModule
