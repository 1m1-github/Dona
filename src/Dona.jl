module Dona

using LoopOS
using LoopOSMainAgent
using LoopOSLogging # DEBUG

function (@main)(ARGS) 
    LoopOS.awaken(@__FILE__)
end

end
