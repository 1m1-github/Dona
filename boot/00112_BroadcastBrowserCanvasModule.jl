module BroadcastBrowserCanvasModule

import StaticArrays: SVector, SA

import Main.ColorModule: Color, blend, CLEAR, WHITE, BLACK, RED, GREEN, BLUE, YELLOW
import Main.CanvasModule: Canvas, Δ
import Main.LoopOS: OutputPeripheral
mutable struct BroadcastBrowserCanvas <: OutputPeripheral
    broadcastbrowser_task::Task
    canvas::Canvas
end

function root(port, bb)
    @info "BroadcastBrowserCanvas HTTP port $port $(bb.stream)"
    # todo let intelligence know about new client
    put!(bb.processor, JS)
    δ = Δ(newcache(), CACHE)
    js = "pixels=" * write(δ) * "\n" * SET_PIXELS_JS
    put!(bb.processor, js)
end

function write(δ)
    result = []
    for (i, color) = δ
        push!(result, (i[1] - 1, BROADCASTBROWSERCANVAS_HEIGHT - 1 - (i[2] - 1), round.(UInt8, typemax(UInt8) * color)...))
    end
    bracket(x) = "[" * x * "]"
    bracket(join(map(r -> bracket(join(r, ',')), result), ','))
end

# todo use max(bb.width, bb.height) to start with a square containing the full view and then scaling down such that the entire square is contained in the view

import Main.SpriteModule: Sprite
import Main.BroadcastBrowserModule: BroadcastBrowser, start
const BROADCASTBROWSERCANVAS_WIDTH_720p = 1280
const BROADCASTBROWSERCANVAS_HEIGHT_720p = 720
const BROADCASTBROWSERCANVAS_WIDTH_1080p = 1920
const BROADCASTBROWSERCANVAS_HEIGHT_1080p = 1080
# const BROADCASTBROWSERCANVAS_WIDTH = BROADCASTBROWSERCANVAS_WIDTH_1080p
# const BROADCASTBROWSERCANVAS_HEIGHT = BROADCASTBROWSERCANVAS_HEIGHT_1080p
const BROADCASTBROWSERCANVAS_WIDTH = BROADCASTBROWSERCANVAS_WIDTH_720p
const BROADCASTBROWSERCANVAS_HEIGHT = BROADCASTBROWSERCANVAS_HEIGHT_720p
const BROADCASTBROWSERCANVAS_DEPTH = 10 # todo let intelligence know about depth granularity
const BROADCASTBROWSERCANVAS = BroadcastBrowserCanvas(
    (Threads.@spawn start(root)),
    Canvas(
            fill(CLEAR, (
                BROADCASTBROWSERCANVAS_WIDTH,
                BROADCASTBROWSERCANVAS_HEIGHT,
                BROADCASTBROWSERCANVAS_DEPTH)),
            Set([1, 2]), Sprite[], "BROADCASTBROWSERCANVAS"))
newcache() = Canvas(
    fill(CLEAR, (BROADCASTBROWSERCANVAS_WIDTH, BROADCASTBROWSERCANVAS_HEIGHT, 1)),
    Set([1, 2]), Sprite[], "CACHE")
const CACHE = newcache()
export BROADCASTBROWSERCANVAS

# x = {w: window.innerWidth, h: window.innerHeight, dpr: window.devicePixelRatio}
const JS = """
document.body.style.margin = '0'
document.body.style.display = 'flex'
document.body.style.justifyContent = 'center'
document.body.style.alignItems = 'center'
document.body.style.minHeight = '100vh'
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

import Main.RectangleModule: Rectangle
add_depth(rectangle::Rectangle{T,2}, depth) where {T<:Real} = Rectangle{T,3}(SVector{3}(rectangle.center...,depth),SVector{3}(rectangle.radius...,0.0), rectangle.id * " with depth")
add_depth(sprite::Sprite{T,2,2}, depth) where {T<:Real} = Sprite{T,2,3}(sprite.drawing, add_depth(sprite.rectangle, depth), sprite.id * " with depth")

import Main.CanvasModule: collapse!
import Base.put!
put!(sprite::Sprite{T,2,2}) where {T<:Real} = put!(sprite, 0.0)
"Use this mainly and simply to display any `Sprite` on your face (your visual representation to the world), depth goes from 0 (bottom) to 1 (top)."
put!(sprite::Sprite{T,2,2}, depth) where {T<:Real} = put!(add_depth(sprite, depth))
function put!(sprite::Sprite{T,2,3}) where {T<:Real}
    δ = put!(BROADCASTBROWSERCANVAS.canvas, sprite)
    isempty(δ) && return
    δ̂ = collapse!(CACHE, BROADCASTBROWSERCANVAS.canvas, δ, blend)
    isempty(δ̂) && return
    js = "pixels=" * write(δ̂) * "\n" * SET_PIXELS_JS
    put!(BroadcastBrowser, js)
end

import Main.CanvasModule: clear!, remove!, move!, scale!
import Main.DrawingModule: Drawing
clear!(rectangle::Rectangle{T,3}) where {T<:Real} = put!(Sprite{T,2,3}(Drawing{2}(_->CLEAR),rectangle))
clear!(rectangle::Rectangle{T,2}, depth = 0.0) where {T<:Real} = clear!(add_depth(rectangle, depth))
clear!(sprite::Sprite) = clear!(sprite.rectangle)
remove!(sprite::Sprite) = remove!(BROADCASTBROWSERCANVAS.canvas, sprite)
move!(sprite::Sprite, rectangle::Rectangle) = move!(BROADCASTBROWSERCANVAS.canvas, sprite, rectangle)
scale!(rectangle::Rectangle) = scale!(BROADCASTBROWSERCANVAS.canvas, rectangle)

end
