module BroadcastBrowserCanvasModule

import Main: @install
@install StaticArrays
import StaticArrays: SA

import Main.StateModule: state
import Main: LoopOS

import Main.ColorModule: CLEAR, Color, blend, WHITE, RED, YELLOW
import Main.DrawingModule: Drawing, circle
import Main.GraphicsModule: Region, Sprite, Canvas, collapse, Δ

struct BroadcastBrowserCanvas <: LoopOS.OutputPeripheral
    broadcastbrowser_task::Task
    canvas::Canvas
end

function root(port, bb)
    @info "BroadcastBrowserCanvas HTTP port $port $(bb.stream)"
    put!(bb.processor, JS)
    # δ = Δ(Canvas("root", fill(WHITE, size(CACHE[].pixels))), CACHE[])
    # js = "pixels=" * write(δ) * "\n" * SET_PIXELS_JS
    # put!(bb.processor, js)
end

function write(canvas::Canvas{2})
    h = size(canvas.pixels, 2)
    result = []
    for i in CartesianIndices(canvas.pixels)
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
var canvas = document.createElement('canvas')
canvas.width = window.innerWidth
canvas.height = window.innerHeight
document.body.appendChild(canvas)
var ctx = canvas.getContext('2d')
var imageData = ctx.createImageData(canvas.width, canvas.height)
function setPixel(x, y, r, g, b, alpha) {
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
const BROADCASTBROWSERCANVAS_WIDTH = 1000
const BROADCASTBROWSERCANVAS_HEIGHT = 1000
const BROADCASTBROWSERCANVAS_TIME = 10
const BROADCASTBROWSERCANVAS_DEPTH = 100
# const BROADCASTBROWSERCANVAS_WIDTH = 3056
# const BROADCASTBROWSERCANVAS_HEIGHT = 3152
const BROADCASTBROWSERCANVAS = Ref(BroadcastBrowserCanvas(
    (Threads.@spawn BroadcastBrowserModule.start(root)),
    Canvas{4}(
        "BroadcastBrowserCanvas",
        fill(CLEAR, (BROADCASTBROWSERCANVAS_WIDTH, BROADCASTBROWSERCANVAS_HEIGHT, BROADCASTBROWSERCANVAS_TIME, BROADCASTBROWSERCANVAS_DEPTH))))) # todo test half and double
# BROADCASTBROWSERCANVAS=Ref(Canvas{4}(
# "BroadcastBrowserCanvas",
# fill(CLEAR, (BROADCASTBROWSERCANVAS_WIDTH, BROADCASTBROWSERCANVAS_HEIGHT, 100, 10))))
const CACHE = Ref(Canvas{2}("CACHE", fill(WHITE, (BROADCASTBROWSERCANVAS_WIDTH, BROADCASTBROWSERCANVAS_HEIGHT))))
# BROADCASTBROWSERCANVAS[].canvas.pixels[:, :, 1, 1] = CACHE[].pixels
# CACHE[].pixels[1,1,1,1]=ColorModule.BLACK
# CACHE[].pixels[1,2,1,1]=ColorModule.BLACK
# δ = Δ(Canvas("root", fill(WHITE, size(CACHE[].pixels))), CACHE[])
# write(δ)
# BROADCASTBROWSERCANVAS[].canvas.pixels[:, :, 1, 1] = CACHE[].pixels
export BROADCASTBROWSERCANVAS

# d = circle("circle", [0.5, 0.5], 0.5, Color(1,0,0,1))
# # d = Drawing{2}("fill", _ -> Color(1,0,0,1))
# r = Region("center", [0.0, 0.0], [1.0, 1.0])
# sprite=Sprite("circle in the center", d, r)
# canvas=Canvas{4}("BroadcastBrowserCanvas",fill(CLEAR, (BROADCASTBROWSERCANVAS_WIDTH, BROADCASTBROWSERCANVAS_HEIGHT, BROADCASTBROWSERCANVAS_TIME, BROADCASTBROWSERCANVAS_DEPTH)))
import Base: put!
"Use this mainly and simply to display any `Sprite` on all browsers"
function put!(sprite::Sprite)
    # @info "put!(sprite::Sprite)"
    # Δ_index = put!(canvas, sprite, true)
    Δ_index = put!(BROADCASTBROWSERCANVAS[].canvas, sprite)
    @info "put!(sprite::Sprite)", length(Δ_index)
    cache = collapse(BROADCASTBROWSERCANVAS[].canvas, Δ_index, blend)
    # cache = collapse(canvas, Δ_index, blend)
    cache = Canvas("CACHE", cache.pixels[:, :, end, end])
    δ = Δ(CACHE[], cache)
    CACHE[] = cache
    js = "pixels=" * write(δ) * "\n" * SET_PIXELS_JS
    @info "l", length(js)
    put!(BroadcastBrowser, js)
end
# old,new=cache, CACHE[]
# pixels = fill(CLEAR, size(new.pixels))
# for i in eachindex(new.pixels)
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
# for i in Δ_index, composite_index in canvas_size[end]:-1:1
# î = i.I[1:N-1]
# canvas_i = CartesianIndex((î..., composite_index))
# canvas_composite = CartesianIndex((î..., 1))
# # pixels[canvas_composite], canvas.pixels[canvas_i]
# pixels[canvas_composite] = combine(pixels[canvas_composite], canvas.pixels[canvas_i])
# 1.0 ≤ pixels[canvas_composite].alpha && break
# end
# Canvas(canvas.id, pixels)
using Plots
plot(BROADCASTBROWSERCANVAS[].canvas.pixels[:,:,end,end])
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
const FULL_BOTTOM_LAYER = Region("full", SA[0.5, 0.5, 0.0, 0.0], SA[0.5, 0.5, 0.0, 0.0])
const WHITE_DRAWING = Drawing{2}("white", _ -> RED)
const WHITE_SPRITE = Sprite("WHITE_SPRITE", WHITE_DRAWING, FULL_BOTTOM_LAYER)
put!(WHITE_SPRITE)
put!(Sprite("s",circle("c",[0.5,0.5],0.5,YELLOW), Region("r",[0.5,0.5],[0.2,0.2])))

import Main.TypstModule: typst
raw"""
Only needs the inner small Typst code.
E.g.: `typst(raw"$ x^2 $")`.
"""
typst(typst_code::String)::Sprite = TypstModule.typst(BROADCASTBROWSERCANVAS[].canvas, typst_code)
export typst

end
