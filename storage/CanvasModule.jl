module CanvasModule

export RGBA, Sprite, draw_rect, draw_circle
export add_sprite!, move_sprite!, remove_sprite!

using HTTP, JSON3

struct RGBA
    r::UInt8
    g::UInt8
    b::UInt8
    a::UInt8
end
RGBA(r, g, b) = RGBA(UInt8(r), UInt8(g), UInt8(b), 0xff)
Base.:(==)(a::RGBA, b::RGBA) = a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a

mutable struct Sprite
    id::Symbol
    x::Int
    y::Int
    z::Int
    pixels::Matrix{RGBA}
    description::String
end

mutable struct CanvasState
    width::Int
    height::Int
    sprites::Dict{Symbol, Sprite}
    composite::Matrix{RGBA}
    previous::Matrix{RGBA}
    sse_channels::Vector{Channel{String}}
    lock::ReentrantLock
end

const STATE = Ref{CanvasState}()

function init(width::Int, height::Int)
    white = RGBA(255, 255, 255, 255)
    STATE[] = CanvasState(
        width, height,
        Dict{Symbol, Sprite}(),
        fill(white, height, width),
        fill(RGBA(0, 0, 0, 0), height, width),
        Channel{String}[],
        ReentrantLock()
    )
end

draw_rect(w::Int, h::Int, color::RGBA) = fill(color, h, w)

function draw_circle(radius::Int, color::RGBA)
    diameter = 2 * radius + 1
    pixels = fill(RGBA(0, 0, 0, 0), diameter, diameter)
    center = radius + 1
    for y in 1:diameter, x in 1:diameter
        dx, dy = x - center, y - center
        if dx^2 + dy^2 <= radius^2
            pixels[y, x] = color
        end
    end
    pixels
end

function add_sprite!(id::Symbol, x::Int, y::Int, z::Int, pixels::Matrix{RGBA}, desc::String="")
    s = STATE[]
    lock(s.lock) do
        s.sprites[id] = Sprite(id, x, y, z, pixels, desc)
    end
    recomposite!()
end

function move_sprite!(id::Symbol; x=nothing, y=nothing, z=nothing)
    s = STATE[]
    lock(s.lock) do
        sprite = s.sprites[id]
        !isnothing(x) && (sprite.x = x)
        !isnothing(y) && (sprite.y = y)
        !isnothing(z) && (sprite.z = z)
    end
    recomposite!()
end

function remove_sprite!(id::Symbol)
    s = STATE[]
    lock(s.lock) do
        delete!(s.sprites, id)
    end
    recomposite!()
end

function blend(bg::RGBA, fg::RGBA)
    fg.a == 0xff && return fg
    fg.a == 0x00 && return bg
    α = fg.a / 255.0
    β = 1.0 - α
    RGBA(
        round(UInt8, α * fg.r + β * bg.r),
        round(UInt8, α * fg.g + β * bg.g),
        round(UInt8, α * fg.b + β * bg.b),
        0xff
    )
end

function recomposite!()
    s = STATE[]
    lock(s.lock) do
        fill!(s.composite, RGBA(0, 0, 0, 0))
        sorted = sort(collect(values(s.sprites)), by=sp -> sp.z)
        for sprite in sorted
            ph, pw = size(sprite.pixels)
            for dy in 1:ph, dx in 1:pw
                cy, cx = sprite.y + dy - 1, sprite.x + dx - 1
                (cy < 1 || cy > s.height || cx < 1 || cx > s.width) && continue
                s.composite[cy, cx] = blend(s.composite[cy, cx], sprite.pixels[dy, dx])
            end
        end
    end
    broadcast_delta!()
end

function compute_delta!()
    s = STATE[]
    delta = Tuple{Int, Int, RGBA}[]
    lock(s.lock) do
        for y in 1:s.height, x in 1:s.width
            curr, prev = s.composite[y, x], s.previous[y, x]
            if curr != prev
                push!(delta, (x - 1, y - 1, curr))
                s.previous[y, x] = curr
            end
        end
    end
    delta
end

function delta_to_json(delta)
    pixels = [[d[1], d[2], d[3].r, d[3].g, d[3].b, d[3].a] for d in delta]
    JSON3.write(Dict("pixels" => pixels))
end

function full_frame_json()
    s = STATE[]
    pixels = Tuple{Int, Int, UInt8, UInt8, UInt8, UInt8}[]
    lock(s.lock) do
        for y in 1:s.height, x in 1:s.width
            c = s.composite[y, x]
            c.a == 0 && continue
            push!(pixels, (x - 1, y - 1, c.r, c.g, c.b, c.a))
        end
    end
    JSON3.write(Dict("width" => s.width, "height" => s.height, "pixels" => pixels))
end

function broadcast_delta!()
    s = STATE[]
    delta = compute_delta!()
    isempty(delta) && return
    msg = delta_to_json(delta)
    lock(s.lock) do
        filter!(s.sse_channels) do ch
            isopen(ch) && (put!(ch, msg); true)
        end
    end
end

const HTML = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Canvas</title>
    <style>
        * { margin: 0; padding: 0; }
        body { background: #111; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
        canvas { image-rendering: pixelated; }
    </style>
</head>
<body>
    <canvas id="c"></canvas>
    <script>
        const canvas = document.getElementById('c');
        const ctx = canvas.getContext('2d');
        let imageData;
        
        function setPixel(x, y, r, g, b, a) {
            const i = (y * canvas.width + x) * 4;
            imageData.data[i] = r;
            imageData.data[i+1] = g;
            imageData.data[i+2] = b;
            imageData.data[i+3] = a;
        }
        
        fetch('/frame').then(r => r.json()).then(frame => {
            canvas.width = frame.width;
            canvas.height = frame.height;
            canvas.style.width = frame.width * 2 + 'px';
            canvas.style.height = frame.height * 2 + 'px';
            imageData = ctx.createImageData(frame.width, frame.height);
            for (const [x,y,r,g,b,a] of frame.pixels) setPixel(x,y,r,g,b,a);
            ctx.putImageData(imageData, 0, 0);
            const sse = new EventSource('/events');
            sse.onmessage = (e) => {
                const delta = JSON.parse(e.data);
                for (const [x,y,r,g,b,a] of delta.pixels) setPixel(x,y,r,g,b,a);
                ctx.putImageData(imageData, 0, 0);
            };
        });
    </script>
</body>
</html>
"""

function serve(port::Int=8080)
    @info "Canvas server on http://localhost:$port"
    HTTP.serve("0.0.0.0", port; stream=true) do stream
        req = stream.message
        if req.target == "/"
            HTTP.setstatus(stream, 200)
            HTTP.setheader(stream, "Content-Type" => "text/html")
            HTTP.startwrite(stream)
            write(stream, HTML)
        elseif req.target == "/frame"
            HTTP.setstatus(stream, 200)
            HTTP.setheader(stream, "Content-Type" => "application/json")
            HTTP.startwrite(stream)
            write(stream, full_frame_json())
        elseif req.target == "/events"
            HTTP.setstatus(stream, 200)
            HTTP.setheader(stream, "Content-Type" => "text/event-stream")
            HTTP.setheader(stream, "Cache-Control" => "no-cache")
            HTTP.startwrite(stream)
            
            ch = Channel{String}(32)
            s = STATE[]
            lock(s.lock) do
                push!(s.sse_channels, ch)
            end
            try
                while isopen(ch) && isopen(stream)
                    msg = take!(ch)
                    write(stream, "data: $msg\n\n")
                    flush(stream)
                end
            catch e
                e isa InvalidStateException || e isa Base.IOError || @warn "SSE error" e
            finally
                close(ch)
            end
        else
            HTTP.setstatus(stream, 404)
            HTTP.startwrite(stream)
        end
    end
end

# CanvasModule.init(3840, 2160)
init(200, 200)
const CanvasModuleTask = @async serve(8080)

end
