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
    @info length(δ)
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
newcache(w, h, d, p, n) = Canvas(fill(CLEAR, (w, h, d)), p, Sprite[], n)
const BROADCASTBROWSERCANVAS_WIDTH_720p = 1280
const BROADCASTBROWSERCANVAS_HEIGHT_720p = 720
const BROADCASTBROWSERCANVAS_WIDTH_1080p = 1920
const BROADCASTBROWSERCANVAS_HEIGHT_1080p = 1080
# const BROADCASTBROWSERCANVAS_WIDTH = BROADCASTBROWSERCANVAS_WIDTH_1080p
# const BROADCASTBROWSERCANVAS_HEIGHT = BROADCASTBROWSERCANVAS_HEIGHT_1080p
const BROADCASTBROWSERCANVAS_WIDTH = 200
const BROADCASTBROWSERCANVAS_HEIGHT = 100
const BROADCASTBROWSERCANVAS_DEPTH = 10 # todo let intelligence know about depth granularity
const BROADCASTBROWSERCANVASTASK = Threads.@spawn start(root)
const BROADCASTBROWSERCANVAS = newcache(BROADCASTBROWSERCANVAS_WIDTH, BROADCASTBROWSERCANVAS_HEIGHT, BROADCASTBROWSERCANVAS_DEPTH, Set((1, 2)), "BROADCASTBROWSERCANVAS")
export BROADCASTBROWSERCANVAS
const BROADCASTBROWSERCANVASMANAGER = BroadcastBrowserCanvas(BROADCASTBROWSERCANVASTASK, BROADCASTBROWSERCANVAS)
newcache() = newcache(BROADCASTBROWSERCANVAS_WIDTH, BROADCASTBROWSERCANVAS_HEIGHT, 1, Set((1, 2)), "CACHE")
const CACHE = newcache()

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
add_depth(rectangle::Rectangle{T,2}, depth) where {T<:Real} = Rectangle{T,3}(SVector{3}(rectangle.center..., depth), SVector{3}(rectangle.radius..., 0.0), rectangle.id * " with depth")
add_depth(sprite::Sprite{T,2,2}, depth) where {T<:Real} = Sprite{T,2,3}(sprite.drawing, add_depth(sprite.rectangle, depth), sprite.id * " with depth")

import Main.CanvasModule: collapse!
import Base.put!
put!(sprite::Sprite{T,2,2}) where {T<:Real} = put!(sprite, 0.0)
"Use this mainly and simply to display any `Sprite` on your face (your visual representation to the world), depth goes from 0 (bottom) to 1 (top)."
put!(sprite::Sprite{T,2,2}, depth) where {T<:Real} = put!(add_depth(sprite, depth))
function put!(sprite::Sprite{T,2,3}) where {T<:Real}
    @show "put!"
    δ = put!(BROADCASTBROWSERCANVAS, sprite)
    @show "put!", length(δ)
    isempty(δ) && return
    broadcast(collapse!(CACHE, BROADCASTBROWSERCANVAS, δ, blend))
end
# function update!()
#     canvas_size = size(BROADCASTBROWSERCANVAS)
#     N = length(canvas_size)
#     δ = CartesianIndex{N}[]
#     for i = CartesianIndices(canvas_size)
#         push!(δ, i)
#     end
#     broadcast(collapse!(CACHE, BROADCASTBROWSERCANVAS, δ, blend))
# end
function broadcast(δ::AbstractVector{<:Tuple{CartesianIndex,Color}})
    # @show "broadcast", length(δ)
    isempty(δ) && return
    js = "pixels=" * write(δ) * "\n" * SET_PIXELS_JS
    put!(BroadcastBrowser, js)
end
# export update!

# Main.CanvasModule.info(CACHE)
import Main.CanvasModule: remove!, move!, scale!
# import Main.DrawingModule: Drawing
# function clear!(rectangle::Rectangle{T,3}) where {T<:Real}
#     put!(Sprite{T,2,3}(Drawing{2}(_->CLEAR),rectangle))
#     deleteat!(BROADCASTBROWSERCANVAS.sprites, length(BROADCASTBROWSERCANVAS.sprites))
# end
# clear!(rectangle::Rectangle{T,2}, depth = 0.0) where {T<:Real} = clear!(add_depth(rectangle, depth))
# clear!(sprite::Sprite) = clear!(sprite.rectangle)
remove!(id::AbstractString) = remove!(BROADCASTBROWSERCANVAS, id)
function remove!(sprite::Sprite)
    δ = remove!(BROADCASTBROWSERCANVAS, sprite)
    broadcast(collapse!(CACHE, BROADCASTBROWSERCANVAS, δ, blend))
end
remove!(sprite::Sprite, depth) = remove!(add_depth(sprite, depth))
move!(sprite::Sprite, rectangle::Rectangle) = move!(BROADCASTBROWSERCANVAS, sprite, rectangle)
scale!(rectangle::Rectangle) = scale!(BROADCASTBROWSERCANVAS, rectangle)

end
