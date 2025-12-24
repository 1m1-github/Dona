module REPLModule

import Main: @install, LoopOS
@install ReplMaker

struct REPLInput <: LoopOS.InputPeripheral
    c::Channel{String}
end

import Base.take!
take!(::REPLInput) = take!(REPL.c)
export take!

const REPL = REPLInput(Channel{String}(Inf))
LoopOS.listen(REPL)

repl_parse(s) = put!(REPL.c, string(strip("""$s""")))

atreplinit() do _
    ReplMaker.initrepl(
        repl_parse,
        prompt_text="> ",
        prompt_color=:light_cyan,
        start_key="\\C-g",
        mode_name="GOD",
    )
    write(stdin.buffer, "\x07")
end

end
using .REPLModule
