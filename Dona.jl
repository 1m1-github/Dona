# julia --quiet --interactive --threads 24 Dona.jl

const ROOT = @__DIR__
const STORAGE = joinpath(ROOT, "storage")
const BOOT_KNOWLEDGE = joinpath(ROOT, "boot")

include("/Users/1m1/Documents/LoopOS.jl/src/LoopOS.jl")
using .LoopOS

for f in sort(readdir(BOOT_KNOWLEDGE, join=true))
    m = include(f)
    if m isa Module
        name = nameof(m)
        eval(:(using .$name))
        StateModule.add_module_to_state(m)
    end
end

LoopOS.awaken(startswith(@__FILE__, "REPL") ? "/Users/1m1/Documents/Dona/Dona.jl" : @__FILE__)
