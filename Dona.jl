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

import Pkg
"To install Julia `Pkg`s: `@install Pkg1, Pkg2, Pkg3, ...` runs `Pkg.add` and `using` if not already cached."
macro install(pkgs...)
    new_pkgs = Symbol[]
    f = first(pkgs)
    if isa(f, Expr)
        new_pkgs = f.args
    elseif isa(f, Symbol)
        new_pkgs = [f]
    else
        throw("unknown type of first(pkgs): $(typeof(f))")
    end
    caller_module = __module__
    new_pkgs = filter(pkg -> !isdefined(caller_module, pkg), new_pkgs)
    isempty(new_pkgs) && return nothing
    installed = Set(keys(Pkg.project().dependencies))
    not_installed = filter(pkg -> string(pkg) ∉ installed, new_pkgs)
    Pkg.add.(string.(not_installed))
    usings = [:(using $pkg) for pkg = new_pkgs]
    esc(Expr(:block, usings...))
end

@install Revise
for f = sort(readdir(BOOT_KNOWLEDGE, join=true))
    Revise.includet(f)
    m = include(f)
    if m isa Module
        name = nameof(m)
        eval(:(using .$name))
        StateModule.add_module_to_state(m)
    end
end

LoopOS.awaken(startswith(@__FILE__, "REPL") ? "/Users/1m1/Documents/Dona/Dona.jl" : @__FILE__)
