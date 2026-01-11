# julia --quiet --interactive --threads 24 Dona.jl
# todo: speak (tts+speaker) with interupting logic, seeing (screenshot, camera with minimal default attention)
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


# subtitles_size::Float64=0.5
# center = SA[0.5, 0.1]
# speech="l"
# sprite = typst_sprite(speech, center, subtitles_size)
# put!(Sprite(sprite.drawing, sprite.rectangle), 1.0)
# put!(Sprite(opacue ∘ black ∘ invert ∘ sprite.drawing, sprite.rectangle), 1.0)
put!(Speaker,"l")

# sprite
# sprite.rectangle
# canvas=TypstModule.CACHE[speech]
# size(canvas)