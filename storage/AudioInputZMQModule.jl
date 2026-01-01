module AudioInputModule

export AudioInput

using Serialization
import Main: LoopOS, TranscriptionModule, StateModule
import Main.StateModule: state
import Main.Base: take!, put!
import Main.PkgModule: @install
@install PortAudio, SampledSignals, ZMQ, Serialization
import Main.LoggingModule: LOGS # DEBUG

"Be aware that the transcription via Whisper can contain mistakes"
struct AudioInput <: LoopOS.InputPeripheral
    channel::Channel{String}
end
take!(a::AudioInput) = take!(a.channel)
put!(a::AudioInput, value) = put!(a.channel, value)
state(a::AudioInput) = "AudioInput"

function clear_zmq(socket)
    while true
        yield()
        try
            recv(socket, nowait=true)
        catch _
            break
        end
    end
end

mutable struct AudioData
    speaker::String
    buffer::Union{SampleBuf{Float32,2}, Nothing}
    value::String
    ts::Float64
end

function get_audios_from_zmq(socket)
    value = ZMQ.recv(socket)
    deserialize(IOBuffer(value))
end

function start_listening()
    @info "Listening to Audio on ZMQ port 8888"
    @async while AUDIO_LISTENING[]
        yield()
        audios_data = get_audios_from_zmq(ZMQ_SOCKET)
        # serialize(joinpath(LOGS,"$(time())-audios_data"), audios_data) # DEBUG
        @sync for (_, audio_data) in audios_data
            isnothing(audio_data.buffer) && continue
            @async audio_data.value = TranscriptionModule.transcribe(audio_data.buffer.data)
        end
        turn = []
        for (_, audio_data) in audios_data
            @info audio_data.value # DEBUG
            value = TranscriptionModule.clean_whisper_text(audio_data.value)
            isempty(value) && continue
            speaker = audio_data.speaker
            push!(turn, "$(StateModule.os_time(audio_data.ts))$speaker>$value")
        end
        isempty(turn) && continue
        conversation = join(turn, '\n')
        if AUDIO_CALLING_INTELLIGENCE[]
            # @info "got conversation", conversation
            @async put!(AUDIO_INPUT, conversation)
        end
    end
end
const ZMQ_CONTEXT = ZMQ.context()
const ZMQ_SOCKET = Socket(ZMQ_CONTEXT, PULL)
bind(ZMQ_SOCKET, "tcp://*:8888")
clear_zmq(ZMQ_SOCKET)
const AUDIO_LISTENING = Ref(true)
const AUDIO_CALLING_INTELLIGENCE = Ref(true)

const AUDIO_INPUT = AudioInput(Channel{String}(Inf))
LoopOS.listen(AUDIO_INPUT)
start_listening()

end
