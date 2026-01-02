@install Colors
module CanvasModule

export Color, Sprite, put!, move!, delete!, clear!, CANVAS_ADVICE, CANVAS
export @colorant_str

const CANVAS_ADVICE = """
This module allows you to do graphical presentation.
Create a Sprite and then `put!` it to the `CANVAS[]` or `Canvas()`. You can also `move!` a Sprite or `delete!` it.
The Canvas goes from top-left (0.0,0.0) to bottom-right (1.0,1.0).
`@colorant_str` is exported so you can use `colorant"red"` for example if you want to.
Use this Canvas as your main visual communications peripheral.
"""

import Main: @install
@install HTTP, JSON3, Colors, FixedPointNumbers
import Colors: RGBA, Colorant, @colorant_str
import FixedPointNumbers: N0f8

import Main.StateModule: state
import Main: LoopOS, Position, HyperRectangle
import Base: put!, delete!

const Color = RGBA{N0f8}
const WHITE = Color(1, 1, 1, 1)
const BLACK = Color(0, 0, 0, 1)
const CLEAR = Color(0, 0, 0, 0)
const Position2D = Position{2}


"""
A matrix of pixels displayed on the canvas, Painter's algorithm for z
"""
const Sprite = HyperRectangleModule.HyperRectangle{2, Color}
white(height, width) = Sprite("w", Position2D((0.5, 0.5)), Position2D((0.5, 0.5)), fill(WHITE, height, width))
mutable struct Canvas <: LoopOS.OutputPeripheral
    width::Int
    height::Int
    sprites::Dict{String, Sprite}
    lock::ReentrantLock
end

const CANVAS = Ref{Canvas}()

state(::Canvas) = "width=$(CANVAS[].width),height=$(CANVAS[].height),sprites=[$(join(state.(sort(collect(keys(CANVAS[].sprites)))),','))]"
state(s::Sprite) = "id=$(s.id),center=$(s.center)"
state(::Matrix{RGBA}) = "(Matrix{RGBA} not shown in state for size reasons)"

function init(width::Int, height::Int)
    CANVAS[] = Canvas(
        width,
        height,
        Dict("CURRENT_COMPOSITE" => white(width, height), "PREVIOUS_COMPOSITE" => white(width, height)),
        ReentrantLock(),
    )
    recomposite!()
end

rel2abs(rel::Real, abs::Int) = round(Int, abs * rel)

"put! `Sprite` to the `Canvas`"
function put!(::Canvas, sprite::Sprite)
    lock(CANVAS[].lock) do
        CANVAS[].sprites[sprite.id] = sprite
    end
    recomposite!()
end

"move `Sprite` with `id` to `pos`"
function move!(id::String, center::Position2D)
    lock(CANVAS[].lock) do
        CANVAS[].sprites[id].center = center
    end
    recomposite!()
end

"delete `Sprite` with `id` from `Canvas`"
function delete!(id::String)
    lock(CANVAS[].lock) do
        Base.delete!(CANVAS[].sprites, id)
    end
    recomposite!()
end

"delete all `Sprite`s from `Canvas`"
function clear!()
    lock(CANVAS[].lock) do
        empty!(CANVAS[].sprites)
    end
    recomposite!()
end

function blend(bg::Color, fg::Color)
    fg.alpha == 1 && return fg
    fg.alpha == 0 && return bg
    α = Float64(fg.alpha)
    β = 1 - α
    Color(α * fg.r + β * bg.r, α * fg.g + β * bg.g, α * fg.b + β * bg.b, 1)
end

rel2abs_x(rel::Real) = round(Int, CANVAS[].width * rel)
rel2abs_y(rel::Real) = round(Int, CANVAS[].height * rel)

function recomposite!()
    canvas = CANVAS[]
    lock(canvas.lock) do
        fill!(canvas.composite, WHITE)
        sprites = sort!(collect(values(canvas.sprites)), by=sp -> sp.center[3]) 
        for sprite in sprites
            sh, sw = size(sprite.pixels)
            cx = rel2abs_x(sprite.center[1]) - sw ÷ 2
            cy = rel2abs_y(sprite.center[2]) - sh ÷ 2
            for dy in 1:sh, dx in 1:sw
                py, px = cy + dy, cx + dx
                (py < 1 || py > s.height || px < 1 || px > s.width) && continue
                s.composite[py, px] = blend(s.composite[py, px], sprite.pixels[dy, dx])
            end
        end
    end
    broadcast_delta!()
end

function computeΔ!()
    canvas = CANVAS[]
    Δ = Tuple{Int,Int,Color}[]
    lock(canvas.lock) do
        for y in 1:canvas.height, x in 1:canvas.width
            curr, prev = canvas.composite[y, x], canvas.previous[y, x]
            if curr != prev
                push!(Δ, (x, y, curr))
                canvas.previous[y, x] = curr
            end
        end
    end
    Δ
end

to256(x) = round(Int, x * 255)
function broadcast_delta!()
    Δ = computeΔ!()
    isempty(Δ) && return
    canvas = CANVAS[]
    pixels = [[x, y, to256(c.r), to256(c.g), to256(c.b), to256(c.alpha)] for (x, y, c) in Δ]
    broadcast!(JSON3.write(Dict("width" => canvas.width, "height" => canvas.height, "pixels" => pixels)))
end

const message_condition = Threads.Condition()
const latest_message = Ref{String}("")

function broadcast!(msg::String)
    lock(message_condition) do
        latest_message[] = msg
        notify(message_condition)
    end
end

const HTML = raw"""
<!DOCTYPE html>
<html>
<head>
    <style>
        * { margin: 0; padding: 0; }
        html, body { width: 100%; height: 100%; overflow: hidden; }
        body { background: #FFFFFF; }
        canvas { display: block; width: 100vw; height: 100vh; image-rendering: pixelated; }
    </style>
</head>
<body>
    <canvas id="canvas"></canvas>
    <script>
        const canvas = document.getElementById('canvas');
        const ctx = canvas.getContext('2d');
        console.log(`Viewport: ${window.innerWidth}×${window.innerHeight}, DPR: ${window.devicePixelRatio}`);
        let imageData;
        function setPixel(x, y, r, g, b, alpha) {
            const i = (y * canvas.width + x) * 4;
            imageData.data[i] = r;
            imageData.data[i+1] = g;
            imageData.data[i+2] = b;
            imageData.data[i+3] = alpha;
        }
        const sse = new EventSource('/events');
        sse.onmessage = (e) => {
            const data = JSON.parse(e.data);
            console.log("first pixel:", data.pixels[0]);
            console.log("num pixels:", data.pixels.length);
            if (!imageData) {
                canvas.width = data.width;
                canvas.height = data.height;
                imageData = ctx.createImageData(data.width, data.height);
            }
            for (const [x,y,r,g,b,a] of data.pixels) setPixel(x,y,r,g,b,a);
            ctx.putImageData(imageData, 0, 0);
        };
    </script>
</body>
</html>
"""

function safe_write(stream, data)
    try
        write(stream, data)
        flush(stream)
        true
    catch e
        e isa Base.IOError || rethrow()
        false
    end
end

function handle_sse(stream)
    HTTP.setstatus(stream, 200)
    HTTP.setheader(stream, "Content-Type" => "text/event-stream")
    HTTP.setheader(stream, "Cache-Control" => "no-cache")
    HTTP.startwrite(stream)

    while true
        lock(message_condition) do
            wait(message_condition)
        end
        safe_write(stream, "data: $(latest_message[])\n\n") || return
    end
end

function serve(port)
    @info "Server on http://0.0.0.0:$port"
    HTTP.serve("0.0.0.0", port; stream=true) do stream
        target = stream.message.target

        if target == "/"
            HTTP.setstatus(stream, 200)
            HTTP.setheader(stream, "Content-Type" => "text/html")
            HTTP.startwrite(stream)
            write(stream, HTML)
        elseif target == "/events"
            handle_sse(stream)
        else
            HTTP.setstatus(stream, 404)
            HTTP.startwrite(stream)
        end
    end
end

init(3056, 3152)
const ServerTask = @async serve(8080)

end
