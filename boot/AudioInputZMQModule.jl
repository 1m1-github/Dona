module AudioInputModule

export AUDIO_INPUT, AUDIO_CALLING_INTELLIGENCE, AUDIO_LISTENING, AUDIO_INPUT_TASK

import Main: @install, LoopOS, TranscriptionModule
import Main.Base: take!, put!
@install PortAudio, SampledSignals, ZMQ, Serialization

struct AudioInput <: LoopOS.InputPeripheral
    speaker::String
    channel::Channel{String}
end
take!(a::AudioInput) = take!(a.channel)
put!(a::AudioInput, value) = put!(a.channel, value)

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
        @sync for (_, audio_data) in audios_data
            isnothing(audio_data.buffer) && continue
            @async audio_data.value = TranscriptionModule.transcribe(audio_data.buffer.data)
        end
        turn = []
        for (_, audio_data) in audios_data
            value = TranscriptionModule.clean_whisper_text(audio_data.value)
            isempty(value) && continue
            ts = audio_data.ts
            speaker = audio_data.speaker
            push!(turn, "<$ts>$speaker:$value")
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

const AUDIO_INPUT = AudioInput("imi", Channel{String}())
const AUDIO_INPUT_TASK = @async begin 
    while !Main.LoopOS.awake() yield() end
    start_listening()
end

end
using .AudioInputModule
