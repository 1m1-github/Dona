module IntelligenceModule

export intelligence
export DEFAULT_MAX_OUTPUT_TOKENS_INTELLIGENCE, DEFAULT_MAX_INPUT_TOKENS_INTELLIGENCE, DEFAULT_COMPLEXITY_INTELLIGENCE, DEFAULT_TEMPERATURE_INTELLIGENCE

import Main: @install
@install HTTP, JSON3, Serialization

DEFAULT_COMPLEXITY_INTELLIGENCE = 0.5
DEFAULT_MAX_INPUT_TOKENS_INTELLIGENCE = 2^20
DEFAULT_MAX_OUTPUT_TOKENS_INTELLIGENCE = 2^12
DEFAULT_TEMPERATURE_INTELLIGENCE = 0.5
const MAX_CUMULATIVE_CACHED_READ_TOKENS = 10 / 0.5 * 1e6
const MAX_CUMULATIVE_CACHED_WRITE_TOKENS = 10 / 6.25 * 1e6
const MAX_CUMULATIVE_READ_TOKENS = 10 / 5 * 1e6
const MAX_CUMULATIVE_WRITE_TOKENS = 10 / 25 * 1e6

"""
intelligence connects to Anthropic Claude
you can use `intelligence` directly if you ever need to
the current mapping is
if complexity < 0.3
    complexity = "claude-haiku-4-5-20251001"
elseif complexity < 0.7
    complexity = "claude-sonnet-4-5-20250929"
else
    complexity = "claude-opus-4-5-20251101"
end
"""
function intelligence(input_system, input_user, complexity=DEFAULT_COMPLEXITY_INTELLIGENCE, max_output_tokens=DEFAULT_MAX_OUTPUT_TOKENS_INTELLIGENCE, temperature=DEFAULT_TEMPERATURE_INTELLIGENCE)
    url = "https://api.anthropic.com/v1/messages"

    headers = [
        "x-api-key" => ENV["ANTHROPIC_API_KEY"],
        "anthropic-version" => "2023-06-01",
        "Content-Type" => "application/json"
    ]

    if isa(complexity, Number)
        if complexity < 0.3
            complexity = "claude-haiku-4-5-20251001"
        elseif complexity < 0.7
            complexity = "claude-sonnet-4-5-20250929"
        else
            complexity = "claude-opus-4-5-20251101"
        end
    end

    system = [Dict("type" => "text", "text" => input_system, "cache_control" => Dict("type" => "ephemeral"))]
    messages = [Dict("role" => "user", "content" => input_user)]

    body = Dict(
        "model" => complexity,
        "system" => system,
        "messages" => messages,
        "temperature" => temperature,
        "max_tokens" => max_output_tokens,
    )
    body_string = JSON3.write(body)

    #DEBUG
    # ts=time()
    LOGS=Main.LOGS
    write(joinpath(LOGS, "latest-input.json"), replace(body_string, r"\\n" => "\n"))
    # write(joinpath(LOGS, "$ts-input.json"), replace(body_string, r"\\n" => "\n"))
    # cp(joinpath(LOGS, "$ts-input.json"), joinpath(LOGS, "latest-input.json"), force=true)
    #DEBUG

    t1 = time() #DEBUG
    response = HTTP.post(url, headers, body_string)
    t2 = time()#DEBUG
    # serialize(joinpath(LOGS, "$ts-response"), response) # DEBUG
    response_body = String(response.body)
    result = JSON3.parse(response_body)
    output = result["content"][1]["text"]

    #DEBUG
    write(joinpath(LOGS, "latest-output.jl"), output)
    # write(joinpath(LOGS, "$ts-output.jl"), output)
    # cp(joinpath(LOGS, "$ts-output.jl"), joinpath(LOGS, "latest-output.jl"), force=true)
    # _now = time()
    # write(joinpath(LOGS, "stats"),
    #     """
    #     now: $_now
    #     ts: $ts
    #     Δ(now-ts): $(_now - ts)
    #     ΔT: $(t2-t1)
    #     in size: $(length(body_string))
    #     out size: $(length(output))
    #     """
    # )
    #DEBUG

    ΔE = result["usage"]["cache_read_input_tokens"] / MAX_CUMULATIVE_CACHED_READ_TOKENS
    ΔE += result["usage"]["cache_creation_input_tokens"] / MAX_CUMULATIVE_CACHED_WRITE_TOKENS
    # result["usage"]["ephemeral_5m_input_tokens"] / MAX_CUMULATIVE_CACHED_READ_BITS
    # result["usage"]["ephemeral_1h_input_tokens"] / MAX_CUMULATIVE_CACHED_READ_BITS
    ΔE += result["usage"]["input_tokens"] / MAX_CUMULATIVE_READ_TOKENS
    ΔE += result["usage"]["output_tokens"] / MAX_CUMULATIVE_WRITE_TOKENS

    extract_julia_blocks(output), ΔE
end


const JULIA_PREPEND = "```julia"
const JULIA_POSTPEND = "```"
function extract_julia_blocks(text)
    pattern = r"```julia\n(.*?)\n```"s
    combined_julia_blocks = join([m.captures[1] for m in eachmatch(pattern, text)], '\n')
    !isempty(combined_julia_blocks) && return combined_julia_blocks
    text = strip(text)
    """$text""" # assume all is Julia
end

end
using .IntelligenceModule
