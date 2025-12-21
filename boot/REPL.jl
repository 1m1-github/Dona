module REPLModule

export REPL
import Main: @install, LoopOS
@install ReplMaker

struct REPLInput <: LoopOS.InputPeripheral 
    c::Channel{String}
end

import Base.take!
take!(::REPLInput) = take!(REPL.c)
export take!

const REPL = REPLInput(Channel{String}())
export REPL

repl_parse(s) = put!(REPL.c, string(strip("""$s""")))

using Logging
atreplinit() do _
    with_logger(NullLogger()) do
        ReplMaker.initrepl(
            repl_parse,
            prompt_text="> ",
            prompt_color=:light_cyan,
            start_key="\\C-g",
            mode_name="GOD",
        )
    end
    write(stdin.buffer, "\x07")
end

end
using .REPLModule
