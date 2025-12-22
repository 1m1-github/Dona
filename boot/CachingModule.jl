module CachingModule

export cache

import Main.LoopOS: TrackedSymbol

const CACHE = TrackedSymbol[]

function same_but_different(s::TrackedSymbol, _s::TrackedSymbol)
    value = s.value isa Ref ? s.value[] : s.value
    _value = _s.value isa Ref ? _s.value[] : _s.value
    s.m == _s.m && s.sym == _s.sym && value ≠ _value
end

function cache(_state::Vector{TrackedSymbol})
    non_cached = TrackedSymbol[]
    if isempty(CACHE)
        for s in _state
            if s.m == Main.LoopOS && s.sym ≠ :BOOT
                push!(non_cached, s)
            else
                push!(CACHE, s)
            end
        end
    else
        for s in _state
            index = findfirst(_s -> same_but_different(s, _s), CACHE)
            isnothing(index) && continue
            deleteat!(CACHE, index)
            push!(non_cached, s)
        end
    end
    CACHE, non_cached
end

end
using .CachingModule

# cached = STATE_PRE * state(_STATE[1:CACHED_INDEX])
#     volatile = state(_STATE[CACHED_INDEX:end]) * STATE_POST
#     # _state = State()
# # const State = Dict{Tuple{Module, Symbol}, Any}
# const State = TrackedSymbol[]
# # function state(_state::TrackedSymbol[])
# # const _STATE = State((@__MODULE__, :SELF), SELF)

# const CACHED_INDEX = 0
# _cached_index = CACHED_INDEX
#     for _s in jvm()
#         for i in length(_STATE):-1:1
#             s = _STATE[i]
#             _s.m ≠ s.m || _s.sym ≠ s.sym && continue
#             _s.hash == s.hash && continue
#             if i < _cached_index _cached_index = i-1 end
#             deleteat!(_STATE, i)
#             break
#         end
#         push!(_STATE, _s)
#     end
#     # sort!(_STATE, lt = (x, y) -> x.ts < y.ts && x.sym < y.sym)
#     # lowest_expected_energy_cost = 
#     # no new cache
#     ΔT
#     n = ΔT/δT
#     ΔE = _cached_index < CACHED_INDEX ? c*sizeof(_STATE[1:_cached_index]) : 0.0
#     for j = _cached_index+1:n
#         ΔE += p*sizeof(_STATE[1:_cached_index]) + P*(sizeof(_STATE[_cached_index+1:end]) + ΔS)
#     end
#     # check how much would be optimal to cache (index of _STATE, cache write costs c, cache read p, fresh read P, with p<P<c)
#     # ΔT is some time horizon that we want to remove at the end to get a per second answer
#     # δT average loop duration (iteration that causes cost)
#     # we can leave the cache upto where it is currently valid or add more to the cache
#     # ΔS is the average bytes added to state at each future turn
#     # assumption: as long as some state was not changed, we expect it will not change for the same duration
#     # thus, given each state, if we add it to cache, we can calculate the expected cost over some ΔT and then per second
#     # and we cache upto the best cost index
#     for i = _cached_index:length(_STATE)
#         # expected_energy_cost
#         # add to cache
#         s_i = sizeof(_STATE[1:i])
#         s_e = sizeof(_STATE[i+1:end])
#         # ΔE = c*s_i
#         # for j = i+1:n
#         #     ΔE += p*s_i + P*(s_e + ΔS)
#         # end
#         # ΔE += (n-i) * (p*s_i + P*(s_e + ΔS))
#         # ΔE = c*s_i + (n-i) * (p*s_i + P*(s_e + ΔS))
#         # ΔE = c*s_i + n*p*s_i - i*p*s_i + n*P*s_e + n*P*ΔS - i*P*s_e - i*P*ΔS
#         # ΔE = s_i*(c+(n-i)*p) + s_e*(n-i)*P + (n-i)*P*ΔS
#         # ΔE = c*s_i + (ΔT/δT-i) * (p*s_i + P*(s_e + ΔS))
#         ΔE/ΔT = c*s_i/ΔT + (p*s_i + P*(s_e + ΔS))/(δT-i)

#         if expected_energy_cost < lowest_expected_energy_cost
#             lowest_expected_energy_cost = expected_energy_cost
#             _cached_index = i # ok?
#         end
#     end
#     global CACHED_INDEX = _cached_index
#     cached = STATE_PRE * state(_STATE[1:CACHED_INDEX])
#     volatile = state(_STATE[CACHED_INDEX:end]) * STATE_POST
#     cached, volatile
