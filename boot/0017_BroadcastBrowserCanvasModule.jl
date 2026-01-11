module BroadcastBrowserCanvasModule

import StaticArrays: SA

import Main.ColorModule: Color, blend, CLEAR, WHITE, BLACK, RED, GREEN, BLUE, YELLOW
import Main.DrawingModule: Drawing, circle
import Main.RectangleModule: Rectangle
import Main.SpriteModule: Sprite
import Main.CanvasModule: Canvas, collapse!, Δ
import Base.put!

import Main: LoopOS

mutable struct BroadcastBrowserCanvas <: LoopOS.OutputPeripheral
    broadcastbrowser_task::Task
    canvas::Canvas
    # timehead::Int
end

function root(port, bb)
    @info "BroadcastBrowserCanvas HTTP port $port $(bb.stream)"
    put!(bb.processor, JS)
    δ = Δ(newcache(), CACHE)
    js = "pixels=" * write(δ) * "\n" * SET_PIXELS_JS
    put!(bb.processor, js)
end

function write(δ::Vector{Tuple{CartesianIndex{N},Color}}) where N
    result = []
    for (i, color) = δ
        push!(result, (i[1] - 1, BROADCASTBROWSERCANVAS_HEIGHT - 1 - (i[2] - 1), round.(UInt8, 255 * color)...))
    end
    bracket(x) = "[" * x * "]"
    bracket(join(map(r -> bracket(join(r, ',')), result), ','))
end

import Main.BroadcastBrowserModule: BroadcastBrowser, start
const BROADCASTBROWSERCANVAS_WIDTH_720p = 1280
const BROADCASTBROWSERCANVAS_HEIGHT_720p = 720
const BROADCASTBROWSERCANVAS_WIDTH_1080p = 1920
const BROADCASTBROWSERCANVAS_HEIGHT_1080p = 1080
const BROADCASTBROWSERCANVAS_WIDTH = BROADCASTBROWSERCANVAS_WIDTH_1080p
const BROADCASTBROWSERCANVAS_HEIGHT = BROADCASTBROWSERCANVAS_HEIGHT_1080p
const BROADCASTBROWSERCANVAS_DEPTH = 10
const BROADCASTBROWSERCANVAS_TIME = 1 # todo
const BROADCASTBROWSERCANVAS = BroadcastBrowserCanvas(
    (Threads.@spawn start(root)),
    Canvas(
            fill(CLEAR, (
                BROADCASTBROWSERCANVAS_WIDTH,
                BROADCASTBROWSERCANVAS_HEIGHT,
                BROADCASTBROWSERCANVAS_DEPTH,
                BROADCASTBROWSERCANVAS_TIME)),
            Set([1, 2])))
newcache() = Canvas{3}(
    fill(CLEAR, (BROADCASTBROWSERCANVAS_WIDTH, BROADCASTBROWSERCANVAS_HEIGHT, 1)),
    Set([1, 2]))
const CACHE = newcache()
export BROADCASTBROWSERCANVAS

# x = {w: window.innerWidth, h: window.innerHeight, dpr: window.devicePixelRatio}
const JS = """
canvas = document.createElement('canvas')
canvas.width = $(BROADCASTBROWSERCANVAS_WIDTH)
canvas.height = $(BROADCASTBROWSERCANVAS_HEIGHT)
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

# function advance_time!()
#     timesize = size(BROADCASTBROWSERCANVAS.canvas.pixels, 4)
#     # old_head = canvas.timehead
#     BROADCASTBROWSERCANVAS.timehead = mod1(BROADCASTBROWSERCANVAS.timehead + 1, timesize)
#     # Copy current "now" (index 1) to ring position before it becomes history
#     @views BROADCASTBROWSERCANVAS.canvas.pixels[:, :, :, BROADCASTBROWSERCANVAS.timehead] .= BROADCASTBROWSERCANVAS.canvas.pixels[:, :, :, 1]
# end
function current_3d_canvas(canvas::Canvas)::Canvas{3}
    # Sprites write to time index 1, so "now" is always physical index 1
    Canvas{3}(
        @view(canvas.pixels[:, :, :, 1]),
        canvas.proportional_dimensions
    )
end

add_depth(rectangle::Rectangle{2}, depth) = Rectangle{3}(SVector{3}(rectangle.center...,depth),SVector{3}(rectangle.radius...,0.0))
add_depth(sprite::Sprite{2,2}, depth) = Sprite{2,3}(sprite.drawing, add_depth(sprite.rectangle, depth))

put!(sprite::Sprite{2,2}) = put!(sprite, 0.0)
"Use this mainly and simply to display any `Sprite` on all browsers, depth=1.0 is highest"
put!(sprite::Sprite{2,2}, depth) = put!(add_depth(sprite, depth))
function put!(sprite::Sprite{2,3})
    canvas_3d = current_3d_canvas(BROADCASTBROWSERCANVAS.canvas)
    δ = put!(canvas_3d, sprite)
    isempty(δ) && return
    δ̂ = collapse!(CACHE, canvas_3d, δ, blend, 3)
    isempty(δ̂) && return
    js = "pixels=" * write(δ̂) * "\n" * SET_PIXELS_JS
    put!(BroadcastBrowser, js)
end

clear!(rectangle::Rectangle{2}, depth = 0.0) = clear!(add_depth(rectangle, depth))
clear!(rectangle::Rectangle{3}) = put!(Sprite(Drawing(_->CLEAR),rectangle))
clear!(sprite::Sprite) = clear!(sprite.rectangle)
export clear!

end
