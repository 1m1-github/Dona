module BroadcastBrowserCanvasModule

# export Color, Sprite, put!, move!, delete!, clear!, CANVAS_ADVICE, CANVAS
# export @colorant_str

# const CANVAS_ADVICE = """
# This module allows you to do graphical presentation.
# Create a Sprite and then `put!` it to the `CANVAS[]` or `Canvas()`. You can also `move!` a Sprite or `delete!` it.
# The Canvas goes from top-left (0.0,0.0) to bottom-right (1.0,1.0).
# `@colorant_str` is exported so you can use `colorant"red"` for example if you want to.
# Use this Canvas as your main visual communications peripheral.
# """

# import Main.StateModule: state
# import Main: LoopOS
# import Base: put!, delete!
# import Main: JSHTTPSSEModule
# import Main: GraphicsModule
# import Main.GraphicsModule: Color

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
# function composite(canvas::Canvas{N}, hyperrectangle_index::CartesianIndices, composite_dimension::Int)::Canvas{M} where {N, M}
#     pixels = fill(CLEAR, ntuple(_ -> 1, M))
#     size(pixels) = length(compositing_dimensions)
#     non_constant_dimensions = [!allequal(j[i] for j in hyperrectangle_index) for i in 1:M]
#     constant_dimensions = [allequal(j[i] for j in hyperrectangle_index) for i in 1:M]
#     for i in hyperrectangle_index
#         for composite_index in 1:size(canvas.pixels, composite_dimension)
#             # fixed = ntuple(i -> sz[3 + i], 1)
#             i = CartesianIndex(x, y, z, fixed...)
#             color = blend(pixels[], canvas.pixels[i])
#             1.0 ≤ color.alpha && break
#         end
#         pixels[i] = color
#     end
#     Canvas(pixels)
# end

# test
# using Colors
const WHITE = Color(1, 1, 1, 1)
const WHITE = Color(1.0, 1.0, 1.0, 1.0)
const BLACK = Color(0, 0, 0, 1)
const BLUE = Color(0, 0, 1, 1)
const YELLOW = Color(1, 1, 0, 1)

sky = Drawing("sky", x -> BLUE)
circle(id, c, r, color) = Drawing(id, x -> hypot((x .- c)...) < r ? color : CLEAR)
cloud = circle("cloud", (0.5, 0.8), 0.1, WHITE)
sun = circle("sun", (0.5, 0.5), 0.5, YELLOW)
scene = sun ∘ cloud ∘ sky  # sun on top of cloud on top of sky
drawing = sun
region = Region("tr", (0.6, 0.5), (0.2, 0.2))
sprite = Sprite("s1", drawing, region)
canvas = Canvas(fill(CLEAR, (10,20,10,2))) # x, y, z, t
Δ_index = put!(canvas, sprite)
composite_dimension = 3
new_composite_canvas = composite(canvas, Δ_index, composite_dimension)
new_composite_canvas = Canvas(new_composite_canvas.pixels[:,:,end,end])
composite_canvas = Canvas(fill(CLEAR, (size(canvas.pixels, 1), size(canvas.pixels, 2))))
composite_Δ_index = [CartesianIndex((i[1], i[2])) for i in Δ_index]
GraphicsModule.put!(composite_canvas, new_composite_canvas, composite_Δ_index)
size(composite_canvas.pixels)
size(new_composite_canvas.pixels)
using Plots
plot(composite_canvas.pixels[:,:,end,end])
plot(canvas.pixels[:,:,end,end])

# "move `Sprite` with `id` to `pos`"
# function move!(id::String, center::Position2D)
#     lock(CANVAS[].lock) do
#         CANVAS[].sprites[id].center = center
#     end
#     recomposite!()
# end

# "delete `Sprite` with `id` from `Canvas`"
# function delete!(id::String)
#     lock(CANVAS[].lock) do
#         Base.delete!(CANVAS[].sprites, id)
#     end
#     recomposite!()
# end

# "delete all `Sprite`s from `Canvas`"
# function clear!()
#     lock(CANVAS[].lock) do
#         empty!(CANVAS[].sprites)
#     end
#     recomposite!()
# end

# rel2abs_x(rel::Real) = round(Int, CANVAS[].width * rel)
# rel2abs_y(rel::Real) = round(Int, CANVAS[].height * rel)

# function recomposite!()
#     canvas = CANVAS[]
#     lock(canvas.lock) do
#         fill!(canvas.composite, WHITE)
#         sprites = sort!(collect(values(canvas.sprites)), by=sp -> sp.center[3])
#         for sprite in sprites
#             sh, sw = size(sprite.pixels)
#             cx = rel2abs_x(sprite.center[1]) - sw ÷ 2
#             cy = rel2abs_y(sprite.center[2]) - sh ÷ 2
#             for dy in 1:sh, dx in 1:sw
#                 py, px = cy + dy, cx + dx
#                 (py < 1 || py > s.height || px < 1 || px > s.width) && continue
#                 s.composite[py, px] = blend(s.composite[py, px], sprite.pixels[dy, dx])
#             end
#         end
#     end
#     broadcast_delta!()
# end

# function computeΔ!()
#     canvas = CANVAS[]
#     Δ = Tuple{Int,Int,Color}[]
#     lock(canvas.lock) do
#         for y in 1:canvas.height, x in 1:canvas.width
#             curr, prev = canvas.composite[y, x], canvas.previous[y, x]
#             if curr != prev
#                 push!(Δ, (x, y, curr))
#                 canvas.previous[y, x] = curr
#             end
#         end
#     end
#     Δ
# end

# to256(x) = round(Int, x * 255)
# function broadcast_delta!()
#     Δ = computeΔ!()
#     isempty(Δ) && return
#     canvas = CANVAS[]
#     pixels = [[x, y, to256(c.r), to256(c.g), to256(c.b), to256(c.alpha)] for (x, y, c) in Δ]
#     broadcast!(JSON3.write(Dict("width" => canvas.width, "height" => canvas.height, "pixels" => pixels)))
# end

# const CANVAS = Ref(Canvas(3056, 3152)) # todo test half and double
# recomposite!()

end
