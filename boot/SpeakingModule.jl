module SpeakingModule

import Main.LoopOS: OutputPeripheral
import Base.put!
export put!

struct SpeakingModuleStruct <: OutputPeripheral end
"Use this to speak out loud"
put!(::SpeakingModuleStruct, text::String; voice="Samantha", rate=200) = run(`say -v $voice -r $rate $text`)

end
