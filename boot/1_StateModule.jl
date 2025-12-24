module StateModule

import Main.LoopOS: TrackedSymbol, Input, Action, LOOP

os_time(ts) = "[$(round(Int, ts-LOOP.boot_time))s]"

state(x) = string(x) # Use `dump` if you need to see more of anything but careful, it could be a lot
state(T::DataType) = strip(sprint(dump, T)) * " end"
state(r::Ref) = state(r[])
state(v::Vector) = "[" * join(state.(v), "; ") * "]"
state(i::Input) = "$(os_time(i.ts))|$(i.source)>$(i.input)"
state(a::Action) = "Action(\ninputs=$(state(a.inputs))\noutput=$(a.output)\n$(os_time(a.ts))|$(state(a.task))"
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
    doc_str = haskey(Docs.meta(m), binding) ? strip(string(Docs.doc(f, sig))) * "\n" : ""
    doc_str * sig_str * "::$(Union{ret_types...})"
end
function state(_state::Vector{TrackedSymbol}, T::Type)
    lines = String[string(T)]
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
