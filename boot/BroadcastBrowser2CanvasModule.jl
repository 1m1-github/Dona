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
import Main: LoopOS
import Main: GraphicsModule
import Main.GraphicsModule: CLEAR, Color, Region, Drawing, Sprite
import Main: BroadcastBrowserModule
import Main.BroadcastBrowserModule: BroadcastBrowser
import Base: put!, delete!
struct BroadcastBrowserCanvas <: LoopOS.OutputPeripheral
    browser_task::Task
    canvas::GraphicsModule.Canvas
end
function put!(::Type{BroadcastBrowserCanvas}, sprite)
    Δ_index = put!(BROADCASTBROWSERCANVAS.canvas, sprite)
    cache = GraphicsModule.collapse(BROADCASTBROWSERCANVAS.canvas, Δ_index, GraphicsModule.blend)
    cache = Canvas("CACHE", cache.pixels[:, :, end, end])
    δ = Δ(cache, CACHE[])
    CACHE[] = cache
    js = "pixels=" * write(δ) * "\n" * setPixels_JS
    put!(BroadcastBrowser, js)
end
function Δ(old, new)
    pixels = fill(CLEAR, size(new))
    for i in eachindex(new)
        old[i] == new[i] && continue
        pixels[i] = new[i]
    end
    Canvas(new.id, pixels)
end
const CACHE = Ref(GraphicsModule.Canvas{2}("CACHE", fill(CLEAR, size(BROADCASTBROWSERCANVAS.canvas))))
const BROADCASTBROWSERCANVASTASK = Threads.@spawn BroadcastBrowserModule.start(root)
const BROADCASTBROWSERCANVAS = BroadcastBrowserCanvas(
    BROADCASTBROWSERCANVASTASK,
    GraphicsModule.Canvas{4}(
        "BroadcastBrowserCanvas",
        fill(CLEAR, (3056, 3152, 100, 10)))) # width, height, depth, time # todo test half and double

function single(pixels)
    depthdim = 3 ; timedim = 4
    depthsize = size(pixels, depthdim) ; timesize = size(pixels, timedim)
    [i for i in CartesianIndices(pixels) if i[depthdim] == depthsize && i[timedim] == timesize]
end
function root(port, bb)
    @info "BroadcastBrowserCanvas HTTP port $port $(bb.stream)"
    δ = Δ(Canvas("root", fill(WHITE, size(CACHE[].pixels))), CACHE[])
    js = "pixels=" * write(δ) * "\n" * setPixels_JS
    put!(BroadcastBrowser, js)
end

write(canvas::Canvas) = JSON3.write(canvas.pixels)

const WHITE = Color(1.0, 1.0, 1.0, 1.0)
const FULL_BOTTOM_LAYER = Region("full", [0.5, 0.5], [0.5, 0.5])
const WHITE_DRAWING = Drawing{2}("white", _ -> WHITE)
const WHITE_SPRITE = Sprite("WHITE_SPRITE", WHITE_DRAWING, FULL_BOTTOM_LAYER)
put!(BroadcastBrowserCanvas, WHITE_SPRITE)

const JS = raw"""
document.body.appendChild(document.createElement('canvas'))
const canvas = document.getElementById('canvas')
const ctx = canvas.getContext('2d')
console.log(`Viewport: ${window.innerWidth}×${window.innerHeight}, DPR: ${window.devicePixelRatio}`);
let imageData
function setPixel(x, y, r, g, b, alpha) {
    const i = (y * canvas.width + x) * 4
    imageData.data[i] = r
    imageData.data[i+1] = g
    imageData.data[i+2] = b
    imageData.data[i+3] = alpha
}
sse.onmessage = (e) => {
    const data = JSON.parse(e.data)
    console.log("first pixel:", data.pixels[0])
    console.log("num pixels:", data.pixels.length)
    if (!imageData) {
        canvas.width = data.width
        canvas.height = data.height
        imageData = ctx.createImageData(data.width, data.height)
    }
    for (const [x,y,r,g,b,a] of data.pixels) setPixel(x,y,r,g,b,a)
    ctx.putImageData(imageData, 0, 0)
}
"""
const setPixels_JS = """
for (const [x,y,r,g,b,a] of pixels) setPixel(x,y,r,g,b,a)
ctx.putImageData(imageData, 0, 0)
"""

# test
# using Colors
# const WHITE = Color(1, 1, 1, 1)
# const WHITE = Color(1.0, 1.0, 1.0, 1.0)
# const BLACK = Color(0, 0, 0, 1)
# const BLUE = Color(0, 0, 1, 1)
# const YELLOW = Color(1, 1, 0, 1)

# sky = Drawing("sky", x -> BLUE)
# circle(id, c, r, color) = Drawing(id, x -> hypot((x .- c)...) < r ? color : CLEAR)
# cloud = circle("cloud", (0.5, 0.8), 0.1, WHITE)
# sun = circle("sun", (0.5, 0.5), 0.5, YELLOW)
# scene = sun ∘ cloud ∘ sky  # sun on top of cloud on top of sky
# drawing = sun
# region = Region("tr", (0.6, 0.5), (0.2, 0.2))
# sprite = Sprite("s1", drawing, region)
# canvas = Canvas(fill(CLEAR, (10,20,10,2))) # x, y, z, t
# Δ_index = put!(canvas, sprite)
# composite_dimension = 3
# new_composite_canvas = composite(canvas, Δ_index, composite_dimension)
# new_composite_canvas = Canvas(new_composite_canvas.pixels[:,:,end,end])
# composite_canvas = Canvas(fill(CLEAR, (size(canvas.pixels, 1), size(canvas.pixels, 2))))
# composite_Δ_index = [CartesianIndex((i[1], i[2])) for i in Δ_index]
# GraphicsModule.put!(composite_canvas, new_composite_canvas, composite_Δ_index)
# size(composite_canvas.pixels)
# size(new_composite_canvas.pixels)
# using Plots
# plot(composite_canvas.pixels[:,:,end,end])
# plot(canvas.pixels[:,:,end,end])

end
