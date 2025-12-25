module StateModule

import Main.LoopOS: TrackedSymbol, Input, Action, LOOP, Loop
import Main.CachingModule: cache!

os_time(ts) = "[$(round(Int, ts-LOOP.boot_time))s]"

function state(
    STATE_PRE::String,
    SELF::String,
    inputs::Vector{Input},
    jvm::Vector{TrackedSymbol},
    loop::Loop,
    history::Vector{Action},
    STATE_POST::String,
)
    ts = time()
    cache, volatile = cache!(jvm)
    push!(volatile, TrackedSymbol(Main.LoopOS, :loop, loop, ts))
    push!(volatile, TrackedSymbol(Main.LoopOS, :history, history, ts))
    input = join(StateModule.state.(inputs), '\n')
    STATE_PRE * SELF * StateModule.state(cache), StateModule.state(volatile) * STATE_POST * input
end
state(x) = string(x) # Use `dump` if you need to see more of anything but careful, it could be a lot
state(T::DataType) = strip(sprint(dump, T)) * " end"
state(r::Ref) = state(r[])
state(s::String) = "\"$s\""
state(l::Loop) = "Loop([$(round(Int, l.duration))]s, $(round(l.energy, digits=4)), $(l.boot))"
state(v::Vector) = "[" * join(state.(v), "; ") * "]"
state(i::Input) = "Input($(os_time(i.ts)), $(i.source), $(i.input))"
state(a::Action) = "Action(\ninputs=$(state(a.inputs))\noutput=$(a.output)\n$(os_time(a.ts))$(state(a.task))"
function state(t::Task)
    _state = ["$(repr(f)):$(f(t))" for f in [istaskstarted, istaskdone, istaskfailed]]
    exception = istaskfailed(t) ? ",exception:$(state(t.exception))" : ""
    "Task(" * join(_state, ",") * exception * ")"
end
function state(x::Exception)
    x isa TaskFailedException && return state(x.task.exception)
    sprint(showerror, x)
end
function state(method::Method)
    sig = method.sig
    sig isa UnionAll && (sig = Base.unwrap_unionall(sig))
    params = sig.parameters[2:end]
    m = method.module
    f = getfield(m, method.name)
    ret_types = Base.return_types(f, Tuple{params...})
    sig_str = split(string(method), " @")[1]
    sig_str = replace(sig_str, "__source__::LineNumberNode, __module__::Module, " => "")
    binding = Docs.Binding(m, method.name)
    doc_str = haskey(Docs.meta(m), binding) ? strip(string(Docs.doc(f, sig))) : ""
    doc_str * sig_str * "::$(Union{ret_types...})"
end
function state(_state::Vector{TrackedSymbol}, T::Type)
    lines = String["::$T"]
    for s in _state
        typeof(s.value) ≠ T && continue
        pre = ""
        if T ∉ [DataType, Method]
            pre *= state(s.sym)
            T <: Ref && ( pre *= "[]" )
            pre *= "="
        end
        push!(lines, pre * state(s.value))
    end
    join(lines, '\n')
end
function state(_state::Vector{TrackedSymbol})
    types = map(s -> typeof(s.value), _state)
    lines = [state(_state, T) for T in unique(types)]
    replace(join(lines, '\n'), "Main." => "")
end

end
using .StateModule
