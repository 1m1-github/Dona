module TranscriptionModule

import Main.PkgModule: @install
@install Whisper, Suppressor

const SILENCE_THRESHOLD = 1e-6
# const WHISPER_FILENAME = "transcription/ggml-large-v3.bin"
const WHISPER_FILENAME = "transcription/ggml-base.en.bin"
# WHISPER_FILENAME = "transcription/ggml-small.en.bin"
# WHISPER_FILENAME = "transcription/ggml-tiny.en.bin"
const WHISPER_CONTEXT = @suppress Whisper.whisper_init_from_file(WHISPER_FILENAME)
const WHISPER_PARAMS = @suppress Whisper.whisper_full_default_params(Whisper.LibWhisper.WHISPER_SAMPLING_GREEDY)
const RM_WHISPER_COMMENTS_PATTERN = r"\[.*?\]|\(.*?\)"

function transcribe(data)
    @suppress begin
        result = ""
        all(abs.(data) .< SILENCE_THRESHOLD) && return result
        Whisper.whisper_full_parallel(WHISPER_CONTEXT, WHISPER_PARAMS, data, length(data), 1)
        n_segments = Whisper.whisper_full_n_segments(WHISPER_CONTEXT)
        for i in 0:n_segments-1
            txt = Whisper.whisper_full_get_segment_text(WHISPER_CONTEXT, i)
            result *= unsafe_string(txt)
        end
        result
    end
end
function clean_whisper_text(x)
    x = replace(x, RM_WHISPER_COMMENTS_PATTERN => "")
    x = replace(x, r"\s+" => " ")
    strip(x)
end
function raw_text_to_conversation!(speaker, raw_text, text_buffer)
    text = clean_whisper_text(raw_text)
    isempty(text) && return ""
    push!(text_buffer, text)
    full_buffer = strip(join(text_buffer, ' '))
    turn = Float64StampedString(time(), full_buffer)
    empty!(text_buffer)
    "<$(turn.when)>$speaker:$(turn.what)"
end

end
