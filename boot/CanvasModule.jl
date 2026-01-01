@install Colors
module CanvasModule

export Sprite, put!, mv!, rm!, clear!, scene!
export circle, rect, CANVAS_ADVICE
export @colorant_str

const CANVAS_ADVICE = """
This module allows you to do graphical presentation.
Create a Sprite and then `add!` it. You can also `mv!` a Sprite or `rm!` it.
`circle` and `rect` already exist, but you can create a Sprite with any Matrix of pixels.
All positions are relative and contain first the 2d (x,y) and thirdly the z depth.
The Canvas goes from top-left (0.0,0.0) to bottom-right (1.0,1.0).
`@colorant_str` is exported so you can use `colorant"red"` for example if you want to.
Use this Canvas as your main visual communications peripheral.
"""

import Main.StateModule: state
import Main: LoopOS
import Base.put!

import Main: @install
@install HTTP, JSON3, Colors, FixedPointNumbers
import Colors: RGBA, Colorant, @colorant_str
import FixedPointNumbers: N0f8

const Color = RGBA{N0f8}
const Pixels = Matrix{Color}
const WHITE = Color(1, 1, 1, 1)
const BLACK = Color(0, 0, 0, 1)
const CLEAR = Color(0, 0, 0, 0)

color(c::Colorant) = Color(c)
color(c::Color) = c

"""
A graphical sprite displayed on the canvas.
`position` (x,y,z) such that (x,y) is the top left corner of `pixels` and z the depth (2d screen)
"""
mutable struct Sprite
    position::NTuple{3,Float64}
    pixels::Pixels
end

mutable struct Canvas <: LoopOS.OutputPeripheral
    width::Int
    height::Int
    sprites::Dict{String, Sprite}
    composite::Pixels
    previous::Pixels
    lock::ReentrantLock
end

const CANVAS = Ref{Canvas}()

state(::Canvas) = "width=$(CANVAS[].width),height=$(CANVAS[].height),sprites=[$(join(state.(sort(collect(keys(CANVAS[].sprites)))),','))]"
state(s::Sprite) = "position=$(s.position)"

function init(width::Int, height::Int)
    CANVAS[] = Canvas(
        width, height,
        Dict{String,Sprite}(),
        fill(WHITE, height, width),
        fill(WHITE, height, width),
        ReentrantLock()
    )
    recomposite!()
end

rel2abs(rel::Real, abs::Int) = round(Int, abs * rel)

"0.0 ≤ radius ≤ 1.0"
function circle(radius::Real, c::Colorant)::Pixels
    d = rel2abs(2 * radius, max(CANVAS[].width, CANVAS[].height))
    d < 1 && return fill(color(c), 1, 1)
    pixels = fill(CLEAR, d, d)
    center = d / 2
    r² = center^2
    for y in 1:d, x in 1:d
        (x - center)^2 + (y - center)^2 <= r² && (pixels[y, x] = color(c))
    end
    pixels
end

"0.0 ≤ width,height ≤ 1.0"
function rect(width::Real, height::Real, c::Colorant)::Pixels
    w = rel2abs(width, CANVAS[].width)
    h = rel2abs(height, CANVAS[].height)
    fill(color(c), max(1, h), max(1, w))
end

"add `Sprite` to `Canvas`"
function put!(id::String, sprite::Sprite)
    lock(CANVAS[].lock) do
        CANVAS[].sprites[id] = sprite
    end
    recomposite!()
end

"move `Sprite` with `id` to `pos`"
function mv!(id::String, pos::Tuple)
    p = (Float64(pos[1]), Float64(pos[2]), Float64(get(pos, 3, 0.0)))
    lock(CANVAS[].lock) do
        CANVAS[].sprites[id].position = p
    end
    recomposite!()
end

"remove `Sprite` with `id` from `Canvas`"
function rm!(id::String)
    lock(CANVAS[].lock) do
        delete!(CANVAS[].sprites, id)
    end
    recomposite!()
end

"remove all `Sprite`s from `Canvas`"
function clear!()
    lock(CANVAS[].lock) do
        empty!(CANVAS[].sprites)
    end
    recomposite!()
end

"Scene management - for composing multiple sprites as a unit"
function scene!(id::String, sprites::Vector{Pair{String, Sprite}})
    for (sub_id, sprite) in sprites
        put!("$(id)_$(sub_id)", sprite)
    end
end

function blend(bg::Color, fg::Color)
    fg.alpha == 1 && return fg
    fg.alpha == 0 && return bg
    α = Float64(fg.alpha)
    β = 1 - α
    Color(α * fg.r + β * bg.r, α * fg.g + β * bg.g, α * fg.b + β * bg.b, 1)
end

function recomposite!()
    s = CANVAS[]
    lock(s.lock) do
        fill!(s.composite, WHITE)
        sprites = sort!(collect(values(s.sprites)), by=sp -> sp.position[3])
        for sprite in sprites
            sh, sw = size(sprite.pixels)
            sx = rel2abs(sprite.position[1], s.width)
            sy = rel2abs(sprite.position[2], s.height)
            dx, dy = (1:sw)[1], (1:sh)[1]
            for dy in 1:sh, dx in 1:sw
                cy, cx = sy + dy, sx + dx
                (cy < 1 || cy > s.height || cx < 1 || cx > s.width) && continue
                s.composite[cy, cx] = blend(s.composite[cy, cx], sprite.pixels[dy, dx])
            end
        end
    end
    broadcast_delta!()
end

function computeΔ!()
    s = CANVAS[]
    Δ = Tuple{Int,Int,Color}[]
    lock(s.lock) do
        for y in 1:s.height, x in 1:s.width
            curr, prev = s.composite[y, x], s.previous[y, x]
            if curr != prev
                push!(Δ, (x, y, curr))
                s.previous[y, x] = curr
            end
        end
    end
    Δ
end

to256(x) = round(Int, x * 255)
function broadcast_delta!()
    Δ = computeΔ!()
    isempty(Δ) && return
    s = CANVAS[]
    pixels = [[x, y, to256(c.r), to256(c.g), to256(c.b), to256(c.alpha)] for (x, y, c) in Δ]
    broadcast!(JSON3.write(Dict("width" => s.width, "height" => s.height, "pixels" => pixels)))
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

    # safe_write(stream, "data: $(full_state_json())\n\n") || return
    # safe_write(stream, "data: $(latest_message[])\n\n") || return

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
