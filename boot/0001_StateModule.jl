module StateModule

export add_module_to_state, StateModuleAdvice

const StateModuleAdvice = raw"""
The following is how state is made:
state(description::String, value::Any) = description * " === BEGIN" * "\n\n" * state(value) *  "\n\n" * description * " === END"
# `Method`s `state` as `os_time` * `docstring` * signature
cached, volatile = Main.CachingModule.cache!(JVM)
for (i, action) in enumerate(HISTORY)
    push!(volatile, TrackedSymbol(LoopOS, Symbol("HISTORY[][$i].inputs"), action.inputs, action.ts))
    if istaskfailed(action.task)
        push!(volatile, TrackedSymbol(LoopOS, Symbol("HISTORY[][$i].task"), action.task, action.ts))
        push!(volatile, TrackedSymbol(LoopOS, Symbol("HISTORY[][$i].output"), action.output, action.ts))
    end
end
push!(volatile, TrackedSymbol(LoopOS, :LOOP, LOOP, Inf))
cached_sections = [STATE_PRE, SELF, state("LoopOS.jvm()", cached)]
volatile_section = [state("LoopOS.HISTORY[] ∪ LoopOS.jvm()", volatile), state("OUTPUT_PERIPHERALS", OUTPUT_PERIPHERALS), state("INPUTS", INPUT), STATE_POST]
join(cached_sections, "\n\n"), join(volatile_section, "\n\n")
"""

import Main: LoopOS
import Main.LoopOS: TrackedSymbol, Input, Action, LOOP, Loop, InputPeripheral, OutputPeripheral

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
    LONG_MEMORY::Vector{String},
    SHORT_MEMORY::Vector{TrackedSymbol},
    INPUT::Vector{Input},
    OUTPUT_PERIPHERAL::Vector{OutputPeripheral},
    LOOP::Loop,
    STATE_POST::String,
)
    cached, volatile = Main.CachingModule.cache!(SHORT_MEMORY)
    cached = filter(c -> !(c.m === Main && c.sym == :Main && c.value === Main), cached)
    for (i, action) in enumerate(HISTORY)
        push!(volatile, TrackedSymbol(LoopOS, Symbol("HISTORY[][$i].input"), action.input, action.ts))
        if istaskfailed(action.task)
            push!(volatile, TrackedSymbol(LoopOS, Symbol("HISTORY[][$i].task"), action.task, action.ts))
            push!(volatile, TrackedSymbol(LoopOS, Symbol("HISTORY[][$i].output"), action.output, action.ts))
        end
    end
    push!(volatile, TrackedSymbol(LoopOS, :LOOP, LOOP, Inf))
    cached_sections = [STATE_PRE, SELF, state("SHORT MEMORY", cached)]
    volatile_section = [state("LONG_MEMORY", LONG_MEMORY), state("HISTORY ∪ SHORT MEMORY", volatile), state("OUTPUT PERIPHERALS", OUTPUT_PERIPHERAL), state("INPUTS", INPUT), STATE_POST]
    join(cached_sections, "\n\n"), join(volatile_section, "\n\n")
end
state(x) = string(x) # Use `dump` if you need to see more of anything but careful, it could be a lot
state(description::String, value::Any) = description * " === BEGIN" * "\n\n" * state(value) *  "\n\n" * description * " === END"
state(T::DataType) = strip(sprint(dump, T)) * " end"
state(r::Ref) = state(r[])
function state(ts::Float64, m::Module)
    name = string(nameof(m))
    if m ∉ MODULES
        m ∈ [Base, Core] && return ""
        return os_time(ts) * name * "::Module (`export`ed symbols not shown, use `add_module_to_state` if you need to)"
    end
    _state = String[]
    for name in names(m)
        f = getfield(m, name)
        f isa Module && continue
        push!(_state, state(TrackedSymbol(m, name, f, ts)))
    end
    join(_state, '\n')
end
state(s::String) = "\"$s\""
state(v::Vector) = "[" * join(state.(v), ",\n") * "]"
state(v::Vector{T}) where T <: Number = "[" * join(string.(v), ", ") * "]"
state(i::Input) = "LoopOS.Input($(os_time(i.ts)), $(state(i.source)), $(state(i.input)))"
state(i::InputPeripheral) = state(typeof(i))
state(o::OutputPeripheral) = state(typeof(o))
function state(a::Action)
    _state = "inputs=$(state(a.inputs))"
    # istaskfailed(a.task) && ( _state *= "\noutput=$(a.output)$(state(a.task))" )
    _state *= "\n$(state(a.task))"
    istaskfailed(a.task) && ( _state *= "\noutput=$(a.output)" )
    _state
end
state(::Loop) = "LoopOS.LOOP"
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
    elseif T <: Method
        return os_time(v.ts) * state(value)
    end
    T_str = T ∈ [DataType, Method] ? "" : string(T)
    _sizeofvalue = sizeof(value)
    sizeofvalue = iszero(_sizeofvalue) ? "" : "(sizeof=" * string(sizeof(value)) * ")"
    if T == Module
        state(v.ts, value)
    else
        _state = if value === LOOP && isinf(v.ts)
            _s = strip(sprint(dump, value))
            replace(_s, r": (\w+) " => s"::\1=") * " end"
        else
            state(value)
        end
        os_time(v.ts) * m * string(v.sym) * ref * "::" * T_str * sizeofvalue * "=" * _state
    end
end
function state(_state::Vector{TrackedSymbol})
    sort!(_state, lt = (s, _s) -> s.ts == _s.ts ? s.value isa Action : s.ts < _s.ts)
    replace(join(filter(!isempty, state.(_state)), '\n'), "Main." => "")
end

end
