module REPLModule

import Main: LoopOS, StateModule
import Base.take!
import Main.StateModule: state
import Main.PkgModule: @install
@install ReplMaker

struct REPLInput <: LoopOS.InputPeripheral
    c::Channel{String}
end

take!(::REPLInput) = take!(REPL.c)
state(::REPLInput) = "REPLModule.REPL"

const REPL = REPLInput(Channel{String}(10))
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
