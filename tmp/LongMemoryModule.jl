# module LongMemoryModule

# export to_long_memory, from_long_memory, Serialization, LONG_MEMORY_ADVICE

# const LONG_MEMORY_ADVICE = """
# `to_long_memory` saves to long memory (STORAGE):
# + String values → `write` as text
# + Other values → `serialize`
# + No value → snapshot entire JVM state
# + No filename → save to `state.jls`

# `from_long_memory` loads from long memory (STORAGE) and restore to Module Main:
# + .txt/.md/.jl files → `read` as `String`
# + .jls files → `deserialize`
# + No filename → load from `state.jls`
# """

# import Main.PkgModule: @install
# @install Serialization
# import Main.LoopOS: TrackedSymbol, Action, HISTORY, jvm

# struct SerializableAction
#     ts::Float64
#     source_type::Symbol
#     input::String
#     output::String
# end

# SerializableAction(a::Action) = SerializableAction(a.ts, nameof(typeof(a.source)), a.input, a.output)

# function serializable(s::TrackedSymbol)
#     value = s.value
#     T = typeof(value)
#     if T == Action
#         value = SerializableAction(value)
#     elseif T == Vector{Action}
#         value = SerializableAction.(value)
#     elseif T ∈ [Task, Function, Method]
#         return nothing
#     end
#     TrackedSymbol(s.m, s.sym, value, s.ts)
# end

# function to_long_memory(filename::String="state.jls", value=nothing)
#     path = joinpath(Main.STORAGE, filename)
#     if isnothing(value)
#         state = jvm()
#         serializable_state = filter(!isnothing, [serializable(s) for s in state])
#         Serialization.serialize(path, serializable_state)
#     elseif value isa String
#         write(path, value)
#     else
#         Serialization.serialize(path, value)
#     end
# end

# function from_long_memory(filename::String="state.jls")
#     path = joinpath(Main.STORAGE, filename)
#     ext = splitext(filename)[2]
    
#     data = if ext in [".txt", ".md", ".jl", ".json"]
#         read(path, String)
#     else
#         Serialization.deserialize(path)
#     end
    
#     if data isa Vector{TrackedSymbol}
#         for s in data
#             try
#                 Base.eval(s.m, :($(s.sym) = $(s.value)))
#             catch e
#                 @warn "Failed to restore" s.m s.sym e
#             end
#         end
#     end
# end

# end
