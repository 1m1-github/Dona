module BroadcastBrowserModule

import Main: @install
@install HTTP

import Main: LoopOS
import Main.LoopOS: BatchProcessor, start!
import Base.put!

"Serve and execute JavaScript on an HTTP client using SSE"
struct BroadcastBrowser <: LoopOS.OutputPeripheral
    stream::HTTP.Streams.Stream
    processor::BatchProcessor{String}
    x::String
    BroadcastBrowser(stream, x="") = new(stream, BatchProcessor{String}(), x)
end
const CLIENTS = Ref(Set{BroadcastBrowser}())
"`put!(BroadcastBrowser, js)` runs the js on all connected browsers"
put!(::Type{BroadcastBrowser}, js) = [put!(client.processor, js) for client in CLIENTS[]]

const HTML = raw"""
<!DOCTYPE html>
<html>
<body>
<script>
let x
let url = `/events`
if(x) { url *= `?x=${x}` }
const sse = new EventSource(url)
sse.onmessage = (e) => eval(JSON.parse(e.data))
</script>
</body>
</html>
"""
const JS = """document.body.appendChild(Object.assign(document.createElement("div"), {textContent: "LoopOS"}))"""

function safe_write(stream, js)
    try
        write(stream, js)
        flush(stream)
        true
    catch e
        e isa Base.IOError || rethrow()
        false
    end
end

function handle_sse(a)
    HTTP.setstatus(a.stream, 200)
    HTTP.setheader(a.stream, "Content-Type" => "text/event-stream")
    HTTP.setheader(a.stream, "Cache-Control" => "no-cache")
    HTTP.startwrite(a.stream)
    start!(a.processor) do input
        for js in input
            safe_write(a.stream, "data: $js\n\n") || return
        end
    end
end

using Sockets
function freeport(hint)
    port, server = listenany(hint)
    close(server)
    Int(port)
end

function start(root::Function, port = freeport(8888))
    HTTP.serve("0.0.0.0", port; stream=true) do stream
        target = stream.message.target
        if target == "/"
            HTTP.setstatus(stream, 200)
            HTTP.setheader(stream, "Content-Type" => "text/html")
            HTTP.startwrite(stream)
            write(stream, HTML)
        elseif target == "/events"
            query = HTTP.URIs.queryparams(a.stream.message.target)
            bb = BroadcastBrowser(stream, query["x"])
            push!(CLIENTS[], bb)
            root(port, bb)
            handle_sse(bb)
            delete!(CLIENTS[], bb)
        else
            HTTP.setstatus(stream, 404)
            HTTP.startwrite(stream)
        end
        bb
    end
end

end
