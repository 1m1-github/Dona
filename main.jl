# julia --quiet --depwarn=error --threads auto main.jl Dona

const GROUP = ARGS[1]

const ROOT = @__DIR__
const LONG_MEMORY = joinpath(ROOT, "$NAME/long")
const BOOT = joinpath(ROOT, "$NAME/boot")
cd(LONG_MEMORY)

include(joinpath(ROOT, "knowledge/LoopOSPkg.jl"))
LoopOSPkg.@install "https://github.com/1m1-github/LoopOS.git"
include("../LoopOS/src/LoopOS.jl")

const MIN_BOOT = ["Pkg", "State", "Caching", "Learning", "AnthropicIntelligence", "Intelligence", "ZMQ"]

load(BOOT)
LoopOS.awaken(BOOT)
