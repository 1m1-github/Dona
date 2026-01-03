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
# import Main.HyperRectangleModule: HyperRectangle

const Color = RGBA{N0f8}
const WHITE = Color(1, 1, 1, 1)
const BLACK = Color(0, 0, 0, 1)
const CLEAR = Color(0, 0, 0, 0)

# hypercube with 0 = bottom left, 1 = top right
struct Sprite f::Function end
function (s::Sprite)(x::NTuple{N,Float64} where N)::Color
    any(x .< 0.0 .|| 1.0 .< x) && error("Sprites assume a unit hypercube")
    s.f(x)
end
# hypercube with 0 = bottom left, 1 = top right
struct Region{N}
    center::NTuple{N, Float64}
    radius::NTuple{N, Float64}
end
struct Canvas{N}
    pixels::Array{Color, N}
end
function index(canvas::Canvas{N}, region::Region{M}) where {N, M}
    N < M && error("region dims cannot exceed canvas dims")
    # hypercube with 0 = bottom left, 1 = top right
    sz_swapped = size(canvas.pixels)
    sz = (sz_swapped[2], sz_swapped[1], sz_swapped[3:end]...)
    # dim ext
    center = ntuple(i -> i <= M ? region.center[i] : 1.0, N)
    radius = ntuple(i -> i <= M ? region.radius[i] : 0.0, N)
    available = ntuple(i -> 2 * radius[i] * sz[i], M)
    scale = minimum(available ./ region.radius)
    used = region.radius .* scale
    center = ntuple(i -> center[i] * sz[i], M)
    index_begin = ntuple(i -> max(round(Int, center[i] - used[i] / 2), 1), M)
    index_end = ntuple(i -> min(round(Int, center[i] + used[i] / 2), sz[i]), M)
    fixed_dimension = ntuple(i -> sz[M + i], N - M)
    unit_hypercube_coordinates = NTuple{M, Float64}[]
    hyperrectangle_index = CartesianIndex{N}[]
    for i in CartesianIndices(UnitRange.(index_begin, index_end))
        push!(unit_hypercube_coordinates, ntuple(M) do j
            (i[j] - index_begin[j] + 0.5) / max(1, index_end[j] - index_begin[j] + 1)
        end)
        push!(hyperrectangle_index, CartesianIndex(sz[2] + 1 - i[2], i[1], i.I[3:end]..., fixed_dimension...))
    end
    unit_hypercube_coordinates, hyperrectangle_index
end
# function put!(canvas::Canvas{N}, sprite::Sprite, region::Region{M}) where {N, M}
#     _index = index(canvas, region)
#     [canvas.pixels[i[2]] = sprite(i[1]) for i in _index]
#     _index
# end
# function composite(canvas::Canvas{4}, region::Region{2}, index::Vector)
# delta_index = Set{Tuple{Int, Int}}()
# for i in index(canvas, region)
#     push!(delta_index, (i[2][1], i[2][2]))
# end
# N = length(size(canvas.pixels))
# for (x, y) in delta_index
function composite(canvas::Canvas{N}, hyperrectangle_index::CartesianIndices, composite_dimension::Int)::Canvas{M} where {N, M}
    pixels = fill(CLEAR, ntuple(_ -> 1, M))
    size(pixels) = length(compositing_dimensions)
    non_constant_dimensions = [!allequal(j[i] for j in hyperrectangle_index) for i in 1:M]
    constant_dimensions = [allequal(j[i] for j in hyperrectangle_index) for i in 1:M]
    for i in hyperrectangle_index
        for composite_index in 1:size(canvas.pixels, composite_dimension)
            # fixed = ntuple(i -> sz[3 + i], 1)
            i = CartesianIndex(x, y, z, fixed...)
            color = blend(pixels[], canvas.pixels[i])
            1.0 ≤ color.alpha && break
        end
        pixels[i] = color
    end
    Canvas(pixels)
end
function fair(a::Color, b::Color)::Color
    total = a.alpha + b.alpha
    total == 0 && return CLEAR
    wa, wb = a.alpha / total, b.alpha / total
    Color(
        a.r * wa + b.r * wb,
        a.g * wa + b.g * wb,
        a.b * wa + b.b * wb,
        a.alpha + b.alpha - a.alpha * b.alpha
    )
end
import Base.∘
∘(a::Sprite, b::Sprite) = Sprite(x -> fair(a(x), b(x)))

# test
sky = Sprite(x -> BLUE)
circle(c, r, color) = Sprite(x -> hypot((x .- c)...) < r ? color : CLEAR)
cloud = circle((0.5, 0.8), 0.1, WHITE)
sun = circle((0.5, 0.8), 0.1, YELLOW)
scene = sun ∘ cloud ∘ sky  # sun on top of cloud on top of sky
sprite = circle((0.5, 0.5), 0.5)
region = Region((0.7, 0.9), (0.1, 0.1))
put!(canvas, sprite, region)


canvas = Canvas(fill(WHITE, (1000,2000,100,10))) # x, y, z, t
unit_hypercube_coordinates, hyperrectangle_index = index(canvas, region)
i = put!(canvas, sprite, region)
plot(canvas.pixels[:,:,end,end])
using Plots

"""
A matrix of pixels displayed on the canvas, Painter's algorithm for z
"""
struct Sprite{N}
    id::String
    region::HyperRectangle{N}
    value::Array{Color,N}
end
state(s::Sprite) = "id=$(s.id),region=$(state(s.region))"
Canvas(width, height) = Sprite{4}(
    "CANVAS",
    HyperRectangle(
        "CANVAS",
        (0.5, 0.5, 0.5, 0.5),
        (0.5, 0.5, 0.5, 0.5)),
    fill(WHITE, (width, height, 100, 100))) # width, height, depth, time

"put! `Sprite` to the `Canvas`"
put!(old::Sprite, new::Sprite) = setindex!(old.value, new.value, index(old.region, size(new.value)))

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

function blend(a::Color, b::Color)
    b.alpha == 1 && return b
    b.alpha == 0 && return a
    α = Float64(b.alpha)
    β = 1 - α
    Color(α * b.r + β * a.r, α * b.g + β * a.g, α * b.b + β * a.b, 1)
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

const CANVAS = Ref(Canvas(3056, 3152)) # todo test half and double
recomposite!()
const ServerTask = @async serve(8080) # todo move to own module

end
