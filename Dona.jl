# julia --quiet --interactive --threads 24 Dona.jl
# todo: speak (tts+speaker) with interupting logic, see canvas (screenshot), see world (cam) [seeing latest frame only, drop old to save data]
# todo: too many input tokens => state too big => recover

const ROOT = @__DIR__
const LONG_MEMORY = joinpath(ROOT, "long")
const BOOT_KNOWLEDGE = joinpath(ROOT, "boot")
cd(LONG_MEMORY)

include("/Users/1m1/Documents/LoopOS.jl/src/LoopOS.jl")
using .LoopOS

for f = sort(readdir(BOOT_KNOWLEDGE, join=true))
    m = include(f)
    if m isa Module
        name = nameof(m)
        eval(:(using .$name))
        StateModule.add_module_to_state(m)
    end
end

LoopOS.awaken(startswith(@__FILE__, "REPL") ? "/Users/1m1/Documents/Dona/Dona.jl" : @__FILE__)

# sun = circle([0.5, 0.5], 0.2, YELLOW)
# upper_half = Rectangle([0.5, 0.75], [0.5, 0.25])
# put!(Sprite(sun, upper_half))
# typst_code=raw"""$x^2$"""
# d=Drawing{2}(coordinates -> TypstModule.typst_drawing(typst_code, coordinates))
# center = Rectangle([0.5, 0.5], [0.05, 0.05])
# put!(Sprite(d, center))

@time put!(Sprite(Drawing{2}(x->CLEAR), Rectangle([0.5,0.5],[0.5,0.5])))
@time put!(Sprite(Drawing{2}(x->CLEAR), Rectangle([0.5,0.5,0.5],[0.5,0.5,0.5])))

put!(Sprite(Drawing{2}(x->Color(1,0,0,0.5)), Rectangle([0.4,0.5],[0.3,0.1])), 0.4)
put!(Sprite(Drawing{2}(x->Color(0,1,0,0.5)), Rectangle([0.6,0.5],[0.3,0.1])), 0.2)