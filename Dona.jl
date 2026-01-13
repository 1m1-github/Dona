# julia --quiet --interactive --depwarn=error --threads 24 Dona.jl
# todo: speak (tts+speaker) with interupting logic, seeing (screenshot, camera with minimal default attention)
# todo: too many input tokens => state too big => recover
# todo: move tests out to improve startup speed

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

put!(SpeakingModule.Speaker, "hi i imi. how is you day going?")
put!(SpeakingModule.Speaker, "hi i imi")

d=Drawing(_->RED)
r=Rectangle([0.5,0.5],[0.1,0.1])
s=Sprite(d,r)
put!(s)
r2=Rectangle([0.7,0.5],[0.1,0.1])
move!(s, r2)
r3=Rectangle([0.1,0.1],[0.05,0.05])
move!(s, r2)
clear!(s)
clear!(rectangle::Rectangle{T,2}, depth = 0.0)
clear!(sprite::Sprite)
remove!(sprite::Sprite)
move!(sprite::Sprite, rectangle::Rectangle)
scale!(rectangle::Rectangle)
