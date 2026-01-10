module BroadcastBrowserCanvasModule

import Main: @install
@install StaticArrays
import StaticArrays: SA

import Main.ColorModule: Color, blend, CLEAR, WHITE, BLACK, RED, GREEN, BLUE, YELLOW
import Main.DrawingModule: Drawing, circle
import Main.RectangleModule: Rectangle
import Main.SpriteModule: Sprite
import Main.CanvasModule: Canvas, collapse!, Δ
import Base.put!

import Main: LoopOS
mutable struct TemporalCanvas
    canvas::Canvas{4}
    time_head::Int
    TemporalCanvas(canvas) = new(canvas, 1)
end
function advance_time!(tc::TemporalCanvas)
    time_size = size(tc.canvas.pixels, 4)
    # old_head = tc.time_head
    tc.time_head = mod1(tc.time_head + 1, time_size)
    # Copy current "now" (index 1) to ring position before it becomes history
    @views tc.canvas.pixels[:, :, :, tc.time_head] .= tc.canvas.pixels[:, :, :, 1]
end
function current_3d_canvas(tc::TemporalCanvas)::Canvas{3}
    # Sprites write to time index 1, so "now" is always physical index 1
    Canvas{3}(
        tc.canvas.id,
        @view(tc.canvas.pixels[:, :, :, 1]),
        tc.canvas.proportional_dimensions
    )
end
struct BroadcastBrowserCanvas <: LoopOS.OutputPeripheral
    broadcastbrowser_task::Task
    canvas::TemporalCanvas
end

function root(port, bb)
    @info "BroadcastBrowserCanvas HTTP port $port $(bb.stream)"
    put!(bb.processor, JS)
    δ = Δ(newcache(), CACHE)
    js = "pixels=" * write(δ) * "\n" * SET_PIXELS_JS
    put!(bb.processor, js)
end

function write(δ::Vector{Tuple{CartesianIndex{N}, Color}}) where N
    result = []
    for (i,color) = δ
        push!(result, (i[1]-1, i[2]-1, 255 * round.(UInt8, color)...))
    end
    bracket(x) = "["*x*"]"
    bracket(join(map(r -> bracket(join(r, ',')), result), ','))
end

# x = {w: window.innerWidth, h: window.innerHeight, dpr: window.devicePixelRatio}
const JS = raw"""
canvas = document.createElement('canvas')
canvas.width = window.innerWidth
canvas.height = window.innerHeight
document.body.appendChild(canvas)
ctx = canvas.getContext('2d')
imageData = ctx.createImageData(canvas.width, canvas.height)
setPixel = (x, y, r, g, b, alpha) => {
    let i = (y * canvas.width + x) * 4
    imageData.data[i] = r
    imageData.data[i+1] = g
    imageData.data[i+2] = b
    imageData.data[i+3] = alpha
}
"""
const SET_PIXELS_JS = """
for (let [x,y,r,g,b,a] of pixels) setPixel(x,y,r,g,b,a)
ctx.putImageData(imageData, 0, 0)
"""

import Main.BroadcastBrowserModule: BroadcastBrowser, start
const BROADCASTBROWSERCANVAS_WIDTH = 200
const BROADCASTBROWSERCANVAS_HEIGHT = 100
const BROADCASTBROWSERCANVAS_DEPTH = 3
const BROADCASTBROWSERCANVAS_TIME = 2
# const BROADCASTBROWSERCANVAS_WIDTH = 3056
# const BROADCASTBROWSERCANVAS_HEIGHT = 3152
const BROADCASTBROWSERCANVAS = BroadcastBrowserCanvas(
    (Threads.@spawn start(root)),
    TemporalCanvas(
        Canvas("BroadcastBrowserCanvas",
        fill(CLEAR, (
            BROADCASTBROWSERCANVAS_WIDTH, 
            BROADCASTBROWSERCANVAS_HEIGHT,
            BROADCASTBROWSERCANVAS_DEPTH,
            BROADCASTBROWSERCANVAS_TIME)),
        Set([1,2])))) # todo test half and double
newcache() = Canvas{3}(
    "CACHE", 
    fill(CLEAR, (BROADCASTBROWSERCANVAS_WIDTH, BROADCASTBROWSERCANVAS_HEIGHT,1)),
    Set([1,2]))
const CACHE = newcache()
export BROADCASTBROWSERCANVAS

"Use this mainly and simply to display any `Sprite` on all browsers"
function put!(sprite::Sprite)
    canvas_3d = current_3d_canvas(BROADCASTBROWSERCANVAS.canvas)
    δ = put!(canvas_3d, sprite)
    isempty(δ) && return
    δ̂ = collapse!(CACHE,canvas_3d, δ, blend,3)
    isempty(δ̂) && return
    js = "pixels=" * write(δ̂) * "\n" * SET_PIXELS_JS
    put!(BroadcastBrowser, js)
end

const WHITE_DRAWING = Drawing{2}("white", _ -> RED)
const FULL_BOTTOM_LAYER = Rectangle("full", SA[0.5, 0.5], SA[0.5, 0.5])
const WHITE_SPRITE = Sprite("WHITE_SPRITE", WHITE_DRAWING, FULL_BOTTOM_LAYER)
put!(WHITE_SPRITE)

import Main.TypstModule: typst
raw"""
Only needs the inner small Typst code.
E.g.: `typst(raw"$ x^2 $")`.
"""
typst(typst_code::String)::Sprite = TypstModule.typst(BROADCASTBROWSERCANVAS[].canvas, typst_code)
export typst

end

sky = rect("half rect", [0.7, 0.75], [0.25, 0.5], TURQUOISE)
sun = circle("sun", [0.75, 0.75], 0.3, YELLOW)
cloud = square("cloud", [0.25, 0.75], 0.2, WHITE)
scene = cloud ∘ sun ∘ sky # cloud ontop of the sun ontop of the sky
put!(Sprite("scene",scene,Rectangle("center",[0.5,0.5,1.0],[0.1,0.1,0.0])))