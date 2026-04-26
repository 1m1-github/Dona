module Dona
using LoopOSMainAgent
using LoopOSLogging # DEBUG
LoopOSMainAgent.start(name="Dona")
LoopOSMainAgent.LoopOSAgentManagement.createagent(name="i")
LoopOSMainAgent.LoopOSAgentManagement.createagent(name="Janet", pkgs=["LoopOSAgentAdvice"])
end
