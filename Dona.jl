# julia --quiet --interactive --threads 24 Dona.jl
# using Debugger
const BOOT = startswith(@__FILE__, "REPL") ? "/Users/1m1/Documents/Dona/Dona.jl" : @__FILE__
const ROOT = dirname(BOOT) ; cd(ROOT)
const STORAGE = joinpath(ROOT, "storage")
const BOOT_KNOWLEDGE = joinpath(ROOT, "boot")

include("/Users/1m1/Documents/LoopOS.jl/src/LoopOS.jl")
using .LoopOS

[include(f) for f in sort(readdir(BOOT_KNOWLEDGE, join=true))]

LoopOS.awaken(BOOT)

# setfield!()
# q(x)=begin
#     @show length(x)
# for s in x
#     @show "$(s.m)::$(s.sym)"
# end
# end
# _state=LoopOS.jvm()
# cached, volatile=CachingModule.cache!(_state)
# q(cached)
# q(volatile)
# c=1
# b=2
# const BOOT="B"

# _state=LoopOS.jvm();
# cached, volatile = CachingModule.cache!(LoopOS.jvm());
# q(CachingModule.CACHE)
# q(cached)
# q(volatile)
# q(_state)
# LoopOS.state(cached)
# LoopOS.state(volatile)
# sort(Base.invokelatest(names, Main, all=true))
# _state=cached
# types = map(s -> typeof(s.value), _state)
# unique(types)
# i=1
# i+=1
# T = unique(types)[i]
# LoopOS.state(_state, T)
# lines = [state(_state, T) for T in unique(types)]
# replace(join(lines, '\n'), "Main." => "")
# lines = String[string(T)]
# j=1
# j+=1
# s = _state[j]
# for s in _state
#     typeof(s.value) ≠ T && continue
#     pre = T ∈ [DataType, Method] ? "" : state(s.sym) * "="
#     push!(lines, pre * state(s.value))
# end
# LoopOS.state(s.value)
# method=s.value
# sig = method.sig
# sig isa UnionAll && (sig = Base.unwrap_unionall(sig))
# params = sig.parameters[2:end]
# m = method.module
# f = getfield(m, method.name)
# ret_types = Base.return_types(f, Tuple{params...})
# sig_str = split(string(method), " @")[1]
# sig_str = replace(sig_str, "__source__::LineNumberNode, __module__::Module, " => "")
# binding = Docs.Binding(m, method.name)
# doc_str = haskey(Docs.meta(method), binding) ? strip(string(Docs.doc(f, sig))) * "\n" : ""
# doc_str * sig_str * "::$(Union{ret_types...})"

# _state=nothing
# cached=nothing
# volatile=nothing
# GC.gc()
