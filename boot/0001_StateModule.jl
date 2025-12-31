module StateModule

export add_module_to_state, StateModuleAdvice

const StateModuleAdvice = raw"""
The following is how state is made:
# state(sym::Symbol, value::Any) adds "$sym === BEGIN" and "$sym === END"
cached, volatile = cache!(JVM)
for (i, action) in enumerate(HISTORY)
    push!(volatile, TrackedSymbol(LoopOS, Symbol("HISTORY[][$i].inputs"), action.inputs, action.ts))
    if istaskfailed(action.task)
        push!(volatile, TrackedSymbol(LoopOS, Symbol("HISTORY[][$i].task"), action.task, action.ts))
        push!(volatile, TrackedSymbol(LoopOS, Symbol("HISTORY[][$i].output"), action.output, action.ts))
    end
end
push!(volatile, TrackedSymbol(LoopOS, :LOOP, LOOP, Inf))
INPUT = join(StateModule.state.(INPUTS), '\n')
cached_sections = [STATE_PRE, SELF, state(:JVM, cached)]
volatile_section = [state(Symbol(:HISTORY,:+,:JVM), volatile), state(:INPUT, INPUT), STATE_POST]
join(cached_sections, "\n\n"), join(volatile_section, "\n\n")
"""

import Main: LoopOS
import Main.LoopOS: TrackedSymbol, Input, Action, LOOP, Loop

const MODULES = Module[Main, LoopOS, @__MODULE__]
"Will add the exported symbols of this module to your short memory"
add_module_to_state(m::Module) = push!(MODULES, m)

function os_time(ts)
    ΔT = ts - LOOP.boot_time
    isinf(ΔT) && return "[∞s]"
    "[$(round(Int, ΔT))s]"
end

function state(
    STATE_PRE::String,
    SELF::String,
    HISTORY::Vector{Action},
    JVM::Vector{TrackedSymbol},
    INPUTS::Vector{Input},
    LOOP::Loop,
    STATE_POST::String,
)
    cached, volatile = Main.CachingModule.cache!(JVM)
    cached = filter(c -> !(c.m === Main && c.sym == :Main && c.value === Main), cached)
    for (i, action) in enumerate(HISTORY)
        push!(volatile, TrackedSymbol(LoopOS, Symbol("HISTORY[][$i].inputs"), action.inputs, action.ts))
        if istaskfailed(action.task)
            push!(volatile, TrackedSymbol(LoopOS, Symbol("HISTORY[][$i].task"), action.task, action.ts))
            push!(volatile, TrackedSymbol(LoopOS, Symbol("HISTORY[][$i].output"), action.output, action.ts))
        end
    end
    push!(volatile, TrackedSymbol(LoopOS, :LOOP, LOOP, Inf))
    INPUT = join(StateModule.state.(INPUTS), '\n')
    cached_sections = [STATE_PRE, SELF, state(:JVM, cached)]
    volatile_section = [state(Symbol(:HISTORY,:+,:JVM), volatile), state(:INPUT, INPUT), STATE_POST]
    join(cached_sections, "\n\n"), join(volatile_section, "\n\n")
end
state(x) = string(x) # Use `dump` if you need to see more of anything but careful, it could be a lot
function state(sym::Symbol, value::Any)
    str = string(sym)
    str * " === BEGIN" * "\n\n" * state(value) *  "\n\n" * str * " === END"
end
state(T::DataType) = strip(sprint(dump, T)) * " end"
state(r::Ref) = state(r[])
function state(ts::Float64, m::Module)
    name = string(nameof(m))
    m ∉ MODULES && return os_time(ts) * name * "::Module (`export`ed symbols not shown, use `add_module_to_state` if you need to)"
    _state = String[]
    for name in names(m)
        f = getfield(m, name)
        f isa Module && continue
        push!(_state, state(TrackedSymbol(m, name, f, ts)))
    end
    join(_state, '\n')
end
state(s::String) = "\"$s\""
state(l::Loop) = "Loop(duration=$(round(l.duration, digits=0))s, energy=$(round(l.energy, digits=4)), boot_time=$(l.boot_time), boot=$(l.boot))"
state(v::Vector) = "[" * join(state.(v), ",\n") * "]"
state(v::Vector{T}) where T <: Number = "[" * join(string.(v), ", ") * "]"
state(i::Input) = "Input($(os_time(i.ts)), $(state(i.source)), $(state(i.input)))"
function state(a::Action)
    _state = "inputs=$(state(a.inputs))"
    istaskfailed(a.task) && ( _state *= "\noutput=$(a.output)$(state(a.task))" )
    _state
end
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
    doc_str = haskey(Docs.meta(m), binding) ? "\"" * strip(string(Docs.doc(f, sig))) * "\" " : ""
    doc_str * sig_str * "::$(Union{ret_types...})"
end
function state(v::TrackedSymbol)
    v.m ∉ MODULES && return ""
    m = v.m == Main ? "" : string(v.m) * "."
    value = v.value
    T = typeof(value)
    ref = ""
    if T <: Ref
        ref = "[]"
        value = v.value[]
        T = typeof(value)
    end
    if T <: Function
        return join(state.([TrackedSymbol(v.m, v.sym, method, v.ts) for method in methods(value, v.m)]), '\n')
    end
    T_str = T ∈ [DataType, Method] ? "" : string(T)
    _sizeofvalue = sizeof(value)
    sizeofvalue = iszero(_sizeofvalue) ? "" : "(sizeof=" * string(sizeof(value)) * ")"
    # _state = T == Module ? state(v.ts, value) : state(value)
    if T == Module
        state(v.ts, value)
    else
        os_time(v.ts) * m * string(v.sym) * ref * "::" * T_str * sizeofvalue * "==" * state(value)
    end
end
function state(_state::Vector{TrackedSymbol})
    sort!(_state, lt = (s, _s) -> s.ts == _s.ts ? s.value isa Action : s.ts < _s.ts)
    replace(join(filter(!isempty, state.(_state)), '\n'), "Main." => "")
end

end
