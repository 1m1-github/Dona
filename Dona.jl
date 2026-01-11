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
# typst_code=raw"""i"""
# d=Drawing{2}(coordinates -> TypstModule.typst_drawing(typst_code, coordinates))
# center = Rectangle([0.5, 0.5], [0.05, 0.05])
# sprite = Sprite(d, center)
# put!(sprite)

# cmd = `typst compile - --format png -`
# using PNGFiles
# import StaticArrays: SVector
# rgba_pixels = pipeline(IOBuffer(TypstModule.TEMPLATE(typst_code)), cmd) |> read |> IOBuffer |> PNGFiles.load
# pixels = map(rgba_pixels) do p
#     Color(SVector{4,Float64}(
#         Float64(p.r),
#         Float64(p.g),
#         Float64(p.b),
#         Float64(p.alpha)))
# end
# pixels[pixels .== Ref(WHITE)] .= Ref(CLEAR)
# a=CanvasModule.Canvas(pixels, Set([1,2]))
# put!(sprite)

# put!(Sprite(Drawing{2}(x->Color(1,0,0,0.5)), Rectangle([0.4,0.5],[0.3,0.1])), 0.4)
# put!(Sprite(Drawing{2}(x->Color(0,1,0,0.5)), Rectangle([0.6,0.5],[0.3,0.1])), 0.2)
# put!(Sprite(Drawing{2}(x->Color(0,0,1,0.5)), Rectangle([0.5,0.2],[0.05,0.1])), 0.5)
# put!(Sprite(Drawing{2}(x->Color(1,0,0,1)), Rectangle([0.9,0.9],[0.05,0.1])), 0.0)
# put!(Sprite(Drawing{2}(x->Color(0,1,0,1)), Rectangle([0.7,0.7],[0.05,0.1])), 0.0)
# put!(Sprite(Drawing{2}(x->Color(0,0,1,1)), Rectangle([0.3,0.3],[0.05,0.1])), 0.0)
# put!(Sprite(Drawing{2}(x->Color(0,1,0,1)), Rectangle([0.1,0.1],[0.05,0.1])), 0.2)
put!(Sprite(Drawing{2}(x->Color(0,0,1,0.2)), Rectangle([0.5,0.5],[0.5,0.5])), 0.0)
# put!(Sprite(Drawing{2}(x->Color(0,0,1,1)), Rectangle([0.9,0.9],[0.01,0.01])), 1.0)

# for i = 0.1:0.1:0.9
#     @show i
#     put!(Sprite(circle([0.5,0.5], 0.5, YELLOW),Rectangle([i,i],[0.01,0.01])), 1.0)
# end

clear!(Rectangle([0.5,0.5],[0.5,0.5]))
# put!(canvas, Sprite(Drawing{N}(_->CLEAR),rectangle))

# @time put!(Sprite(Drawing{2}(x->CLEAR), Rectangle([0.5,0.5],[0.5,0.5])))
# @time put!(Sprite(Drawing{2}(x->CLEAR), Rectangle([0.5,0.5,0.5],[0.5,0.5,0.5])))
