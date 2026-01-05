module ActionUtilsModule

export stop_action

# "will cause an InterruptException in the `task` given the `input_summary` of an `Action`"
#  function stop_action(input_summary::String)
#     action = find_action(input_summary)
#     isnothing(action) && return
#     stop_action(action.ts)
# end

"will cause an InterruptException for the `task` given the `ts` of an `Action`"
 function stop_action(ts::Float64)
    !haskey(HISTORY, ts) && return
    schedule(HISTORY[ts].task, InterruptException(), error=true)
end

# "will find the `Action` given `input_summary`, `nothing` if not existing"
#  function find_action(input_summary::String)
#     possible_action_times = sort(filter(ts -> HISTORY[ts].input_summary == input_summary, collect(keys(HISTORY))))
#     isempty(possible_action_times) && return nothing
#     HISTORY[first(possible_action_times)]
# end

# """
# ONLY run this ts explicity asked, else it removes important context
# Will `delete!` `HISTORY` older than `cutoff`
# """
#  function clear_history(cutoff::Float64)
#     keys_to_delete = filter(ts -> ts < cutoff, collect(keys(HISTORY)))
#     for ts in keys_to_delete
#         delete!(HISTORY, ts)
#     end
# end

end
