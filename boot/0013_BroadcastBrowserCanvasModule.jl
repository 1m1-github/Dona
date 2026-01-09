# module BroadcastBrowserCanvasModule

import Main: @install
@install StaticArrays
import StaticArrays: SA

import Main.StateModule: state
import Main: LoopOS

import Main.ColorModule: Color, blend, CLEAR, WHITE, BLACK, RED, GREEN, BLUE, YELLOW
import Main.DrawingModule: Drawing, circle
import Main.GraphicsModule: Rectangle, Sprite, Canvas, collapse, Δ

struct BroadcastBrowserCanvas <: LoopOS.OutputPeripheral
    broadcastbrowser_task::Task
    canvas::Canvas
end

function root(port, bb)
    @info "BroadcastBrowserCanvas HTTP port $port $(bb.stream)"
    put!(bb.processor, JS)
    δ = Δ(Canvas("root", fill(WHITE, size(CACHE[].pixels)), CACHE[].proportional_dimensions), CACHE[])
    js = "pixels=" * write(δ) * "\n" * SET_PIXELS_JS
    put!(bb.processor, js)
end

function write(canvas::Canvas{2})
    h = size(canvas.pixels, 2)
    result = []
    for i = CartesianIndices(canvas.pixels)
        p = canvas.pixels[i]
        p == CLEAR && continue
        push!(result, (i[1]-1, h-i[2], 
            reinterpret(UInt8, p.r), reinterpret(UInt8, p.g),
            reinterpret(UInt8, p.b), reinterpret(UInt8, p.alpha)))
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

import Main: BroadcastBrowserModule
import Main.BroadcastBrowserModule: BroadcastBrowser
const BROADCASTBROWSERCANVAS_WIDTH = 200
const BROADCASTBROWSERCANVAS_HEIGHT = 100
const BROADCASTBROWSERCANVAS_TIME = 2
const BROADCASTBROWSERCANVAS_DEPTH = 3
# const BROADCASTBROWSERCANVAS_WIDTH = 3056
# const BROADCASTBROWSERCANVAS_HEIGHT = 3152
const BROADCASTBROWSERCANVAS = Ref(BroadcastBrowserCanvas(
    (Threads.@spawn BroadcastBrowserModule.start(root)),
    Canvas{4}(
        "BroadcastBrowserCanvas",
        fill(CLEAR, (
            BROADCASTBROWSERCANVAS_WIDTH, 
            BROADCASTBROWSERCANVAS_HEIGHT, 
            BROADCASTBROWSERCANVAS_TIME, 
            BROADCASTBROWSERCANVAS_DEPTH)),
        Set([1,2])))) # todo test half and double
# BROADCASTBROWSERCANVAS=Ref(Canvas{4}(
# "BroadcastBrowserCanvas",
# fill(CLEAR, (BROADCASTBROWSERCANVAS_WIDTH, BROADCASTBROWSERCANVAS_HEIGHT, 100, 10))))
const CACHE = Ref(Canvas{2}(
    "CACHE", 
    fill(WHITE, (BROADCASTBROWSERCANVAS_WIDTH, BROADCASTBROWSERCANVAS_HEIGHT)),
    Set([1,2])))
# BROADCASTBROWSERCANVAS[].canvas.pixels[:, :, 1, 1] = CACHE[].pixels
# CACHE[].pixels[1,1,1,1]=ColorModule.BLACK
# CACHE[].pixels[1,2,1,1]=ColorModule.BLACK
# δ = Δ(Canvas("root", fill(WHITE, size(CACHE[].pixels))), CACHE[])
# write(δ)
# BROADCASTBROWSERCANVAS[].canvas.pixels[:, :, 1, 1] = CACHE[].pixels
export BROADCASTBROWSERCANVAS

# BROADCASTBROWSERCANVAS[].canvas.pixels .= CLEAR
# BROADCASTBROWSERCANVAS[].canvas.pixels
using Plots
plot(BROADCASTBROWSERCANVAS[].canvas.pixels[:,:,end,end])
info(pixels)=for c = [CLEAR, WHITE, BLACK, RED, GREEN, BLUE, YELLOW]
@info "is", c, count(==(c),pixels)
@info "is not", c, count(≠(c),pixels)
end
info(BROADCASTBROWSERCANVAS[].canvas.pixels)
info(cache.pixels)
d=Drawing{2}("d",_->Color(1,0,0,0.5))
d2=Drawing{2}("d",_->Color(0,1,0,0.5))
r=Rectangle("r",[0.5,0.5],[0.2,0.2])
r2=Rectangle("r",[0.5,0.5,1.0,0.5],[0.1,0.3,0.0,0.0])
sprite=Sprite("s",d, r)
sprite2=Sprite("s",d2, r2)
put!(sprite2)
sprite=sprite2
canvas=BROADCASTBROWSERCANVAS[].canvas
rectangle=r2
# stretch=false
# stretch=true
all_clear = Sprite("",Drawing{2}("",_->CLEAR),Rectangle("",[0.5,0.5,0.5,0.5],[0.5,0.5,0.5,0.5]))
sprite=all_clear
sprite=WHITE_SPRITE
put!()
put!(WHITE_SPRITE)
# rectangle = tests[10][1]
# f(canvas, rectangle)
# f(canvas, rectangle) = begin
#     canvas_size = size(canvas.pixels)
#     # max_pixels = 0 ; min_pixels = typemax(Int)
#     # for i=1:N
#     #     pixels = ceil(Int, canvas_size[i] * rectangle.width[i])
#     #     if max_pixels < pixels
#     #         max_pixels = pixels
#     #     elseif pixels < min_pixels
#     #         min_pixels = pixels
#     #     end
#     # end
#     # for i = 1:N
#     #     np = size(canvas.pixels, i) - 1
#     #     start_index = floor(rectangle.center[i] * np + 0.5) + 1
#     #     end_index = ceil((rectangle.center[i] + rectangle.width[i]) * np + 0.5)
#     # end
#     start_index = floor.(rectangle.center .* canvas_size .+ 0.5) .+ 1
#     end_index = ceil.((rectangle.center .+ rectangle.radius) .* canvas_size .+ 0.5) .+ 1
#     # available = rectangle.width * max_pixels
#     # center = rectangle.center .* canvas_size
#     # start_index = max.(ceil.(Int, center), 1)
#     # end_index = ceil.(Int, center .+ available)
#     # @assert all(end_index .≤ canvas_size)
#     CartesianIndices(Tuple(UnitRange.(start_index, end_index)))
# end
# hyperrectangle_index = GraphicsModule.index(canvas, sprite.rectangle, stretch)
# hyperrectangle_index = GraphicsModule.index(canvas, sprite2.rectangle, stretch)
# start_index = SVector{N}([hyperrectangle_index[1][i] for i = 1:N])
# end_index = SVector{N}([hyperrectangle_index[end][i] for i = 1:N])
# width = end_index .- start_index .+ 1
# δ = Δ(BROADCASTBROWSERCANVAS[].canvas, sprite)
# put!(BROADCASTBROWSERCANVAS[].canvas, δ)
# δ = Δ(BROADCASTBROWSERCANVAS[].canvas, sprite2)
# put!(BROADCASTBROWSERCANVAS[].canvas, δ)
# cache = collapse(BROADCASTBROWSERCANVAS[].canvas, δ, blend)
# size(cache.pixels)
# info(cache.pixels)
# cache.pixels
plot(cache.pixels[:,:,end,end])
# put!(s)
# methods(collapse)
# drawing = circle("circle", [0.5, 0.5], 0.5, Color(1,0,0,1))
# # d = Drawing{2}("fill", _ -> Color(1,0,0,1))
# rectangle = Rectangle("center", [0.5, 0.5], [0.5, 0.5])
# sprite=Sprite("circle in the center", drawing, rectangle)
# canvas=Canvas{4}("BroadcastBrowserCanvas",fill(CLEAR, (BROADCASTBROWSERCANVAS_WIDTH, BROADCASTBROWSERCANVAS_HEIGHT, BROADCASTBROWSERCANVAS_TIME, BROADCASTBROWSERCANVAS_DEPTH)))
import Base: put!
"Use this mainly and simply to display any `Sprite` on all browsers"
function put!(sprite::Sprite)
# @info "put!(sprite::Sprite)"
    # Δ_index = put!(canvas, sprite, true)
    δ = Δ(BROADCASTBROWSERCANVAS[].canvas, sprite)
    put!(BROADCASTBROWSERCANVAS[].canvas, δ)
    @info "put!(sprite::Sprite)", length(δ)
    cache = collapse(BROADCASTBROWSERCANVAS[].canvas, δ, blend)
    # cache = collapse(canvas, Δ_index, blend)
    cache = Canvas("CACHE", cache.pixels[:, :, end, end], cache.proportional_dimensions)
    δcache = Δ(CACHE[], cache)
    CACHE[] = cache
    js = "pixels=" * write(δcache) * "\n" * SET_PIXELS_JS
    @info "l", length(js)
    put!(BroadcastBrowser, js)
end
# old,new=cache, CACHE[]
# pixels = fill(CLEAR, size(new.pixels))
# for i = eachindex(new.pixels)
#     old.pixels[i] == new.pixels[i] && continue
#     pixels[i] = new.pixels[i]
# end
# Canvas(new.id, pixels)
# plot(old.pixels[:, :, end, end])
# filter(c -> c == CLEAR, old.pixels)
# filter(c -> c == ColorModule.RED, old.pixels)
# filter(c -> c == ColorModule.WHITE, old.pixels)
# plot(new.pixels[:, :, end, end])
# filter(c -> c == CLEAR, new.pixels)
# filter(c -> c == ColorModule.RED, new.pixels)
# filter(c -> c == ColorModule.WHITE, new.pixels)

# # δ.pixels
# # filter(c->c ≠ CLEAR, δ.pixels)
# w=write(δ)
# δ
# split(w,"],[")
# plot(δ.pixels)
# 200*100
# filter(c->c ≠ CLEAR, cache.pixels)
# canvas=BROADCASTBROWSERCANVAS[].canvas
# combine=blend
# canvas_size = size(canvas.pixels)
# composite_size = (canvas_size[1:end-1]..., 1)
# pixels = fill(CLEAR, composite_size)
# i = Δ_index[2]
# composite_index = (canvas_size[end]:-1:1)[1]
# N=length(size(canvas.pixels))
# for i = Δ_index, composite_index = canvas_size[end]:-1:1
# î = i.I[1:N-1]
# canvas_i = CartesianIndex((î..., composite_index))
# canvas_composite = CartesianIndex((î..., 1))
# # pixels[canvas_composite], canvas.pixels[canvas_i]
# pixels[canvas_composite] = combine(pixels[canvas_composite], canvas.pixels[canvas_i])
# 1.0 ≤ pixels[canvas_composite].alpha && break
# end
# Canvas(canvas.id, pixels)
# using Plots
# plot(BROADCASTBROWSERCANVAS[].canvas.pixels[:,:,end,end])
# plot(canvas.pixels[:, :, end, end])
# plot(cache.pixels[:, :, end, end])
# plot(CACHE[].pixels[:, :, end, end])
# plot(pixels[:, :, end, end])
# # size(pixels[:, :, end, end])
# # size(canvas.pixels[:, :, end, end])
# size(pixels[:, :, end, end])
# size(δ.pixels)
# plot(canvas.pixels[:, :, end, end])
# filter(c -> c == CLEAR, δ.pixels)
# filter(c -> c == ColorModule.RED, δ.pixels)
# filter(c -> c == ColorModule.WHITE, δ.pixels)
# size(cache.pixels[:, :, end, end])
# size(CACHE[].pixels[:, :, end, end])
# filter(c -> c == CLEAR, pixels)
# filter(c -> c == ColorModule.RED, pixels)
# filter(c -> c == ColorModule.RED, pixels[:,:,end,end])
# filter(c -> c == CLEAR, canvas.pixels)
# filter(c -> c == ColorModule.RED, canvas.pixels)
# filter(c -> c == ColorModule.RED, canvas.pixels[:,:,end,end])
# size(canvas.pixels[:,:,end,end])
# filter(c -> c == CLEAR, cache.pixels)
# filter(c -> c == ColorModule.RED, cache.pixels)
# filter(c -> c == CLEAR, CACHE[].pixels)
# filter(c -> c == ColorModule.RED, CACHE[].pixels)
# CACHE[].pixels
# pixels[:, :, end, end]
# plot(BROADCASTBROWSERCANVAS[].canvas.pixels[:, :, end, end])
const FULL_BOTTOM_LAYER = Rectangle("full", SA[0.5, 0.5, 0.0, 0.0], SA[0.5, 0.5, 0.0, 0.0])
const WHITE_DRAWING = Drawing{2}("white", _ -> RED)
const WHITE_SPRITE = Sprite("WHITE_SPRITE", WHITE_DRAWING, FULL_BOTTOM_LAYER)
# put!(WHITE_SPRITE)

import Main.TypstModule: typst
raw"""
Only needs the inner small Typst code.
E.g.: `typst(raw"$ x^2 $")`.
"""
typst(typst_code::String)::Sprite = TypstModule.typst(BROADCASTBROWSERCANVAS[].canvas, typst_code)
export typst

# end
