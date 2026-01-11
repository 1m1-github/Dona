module BroadcastBrowserCanvasModule

import Main: @install
@install StaticArrays
import StaticArrays: SA

import Main.ColorModule: Color, blend, CLEAR, WHITE, BLACK, RED, GREEN, BLUE, YELLOW
import Main.DrawingModule: Drawing, circle
import Main.RectangleModule: Rectangle
import Main.SpriteModule: Sprite
import Main.CanvasModule: Canvas, collapse!, Δ, clear!, move!
import Base.put!

import Main: LoopOS

mutable struct BroadcastBrowserCanvas <: LoopOS.OutputPeripheral
    broadcastbrowser_task::Task
    canvas::Canvas
    timehead::Int
end

function root(port, bb)
    @info "BroadcastBrowserCanvas HTTP port $port $(bb.stream)"
    put!(bb.processor, JS)
    δ = Δ(newcache(), CACHE)
    # @show "root", length(δ)
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
const BROADCASTBROWSERCANVAS_WIDTH = 100
const BROADCASTBROWSERCANVAS_HEIGHT = 100
# const BROADCASTBROWSERCANVAS_WIDTH = 3056 # todo test half and double
# const BROADCASTBROWSERCANVAS_HEIGHT = 3152 # todo test half and double
const BROADCASTBROWSERCANVAS_DEPTH = 10
const BROADCASTBROWSERCANVAS_TIME = 1
const BROADCASTBROWSERCANVAS = BroadcastBrowserCanvas(
    (Threads.@spawn start(root)),
    Canvas(
            fill(CLEAR, (
                BROADCASTBROWSERCANVAS_WIDTH,
                BROADCASTBROWSERCANVAS_HEIGHT,
                BROADCASTBROWSERCANVAS_DEPTH,
                BROADCASTBROWSERCANVAS_TIME)),
            Set([1, 2])),
    1)
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
    @show "put!"
    canvas_3d = current_3d_canvas(BROADCASTBROWSERCANVAS.canvas)
    @show "put!", info(canvas_3d.pixels)
    δ = put!(canvas_3d, sprite)
    @show "put!", info(canvas_3d.pixels), length(δ)
    isempty(δ) && return
    @show "put!", info(CACHE.pixels)
    δ̂ = collapse!(CACHE, canvas_3d, δ, blend, 3)
    @show "put!", info(CACHE.pixels), length(δ̂)
    isempty(δ̂) && return
    js = "pixels=" * write(δ̂) * "\n" * SET_PIXELS_JS
    put!(BroadcastBrowser, js)
end

# rectangle=Rectangle([0.5,0.5],[0.5,0.5])
# rectangle=add_depth(rectangle, 0.0)
# sprite=Sprite(Drawing{2}(_->CLEAR),rectangle)
# put!(sprite,1.0)

clear!(rectangle::Rectangle{2}, depth = 0.0) = clear!(add_depth(rectangle, depth))
clear!(rectangle::Rectangle{3}) = clear!(BROADCASTBROWSERCANVAS.canvas, rectangle)
clear!(sprite::Sprite) = clear!(sprite.rectangle)
move!(sprite::Sprite{2,2}, new_center, depth = 0.0) = move!(add_depth(sprite, depth), new_center)
move!(sprite::Sprite{2,3}, new_center) = move!(BROADCASTBROWSERCANVAS.canvas, sprite, new_center)
colors(pixels) = for c in [WHITE, BLACK, RED, GREEN, BLUE, YELLOW]
    println(c, "=",count(p->p[1:3]==c[1:3],pixels))
end 
info(pixels::AbstractArray{Color,4})=begin
    println("size=", size(pixels), prod(size(pixels)))
    println("CLEAR=", count(p->p==CLEAR,pixels))
    for z in 1:size(pixels,3)
        println("z=$z")
        colors(pixels[:,:,z,1])
    end
end
info(pixels::AbstractArray{Color,3})=begin
    println("size=", size(pixels), prod(size(pixels)))
    println("CLEAR=", count(p->p==CLEAR,pixels))
    for z in 1:size(pixels,3)
        println("z=$z")
        colors(pixels[:,:,z])
    end
end
# # fill!(BROADCASTBROWSERCANVAS.canvas.pixels,CLEAR)
# # fill!(CACHE.pixels,CLEAR)
# info(BROADCASTBROWSERCANVAS.canvas.pixels)
# info(CACHE.pixels)
# canvas_3d = current_3d_canvas(BROADCASTBROWSERCANVAS.canvas)
# info(canvas_3d.pixels)
# # sprite=Sprite(Drawing{2}(x->Color(1,0,0,0.5)), Rectangle([0.4,0.5],[0.3,0.1]))
# # depth=0.4
# # sprite=Sprite{2,3}(sprite.drawing, Rectangle{3}(SVector{3}(sprite.rectangle.center...,depth),SVector{3}(sprite.rectangle.radius...,0.0)))
# sprite = Sprite(Drawing{3}(_->CLEAR),Rectangle([0.5,0.5],[0.5,0.5]))
# δ = put!(canvas_3d, sprite)
# # info(canvas_3d.pixels)
# # info(BROADCASTBROWSERCANVAS.canvas.pixels)
# # info(CACHE.pixels)
# δ=Tuple{CartesianIndex{3}, Color}[]
# for i=1:100,j=1:100,z=1:10
#     push!(δ, (CartesianIndex(i,j,z),CLEAR))
# end
# δ̂ = Main.CanvasModule.collapse!(CACHE, canvas_3d, δ, blend, 3)

# info(CACHE.pixels)
# info(canvas_3d.pixels)
# info(BROADCASTBROWSERCANVAS.canvas.pixels)

# map(x->x[2],δ̂)

# js = "pixels=" * write(δ̂) * "\n" * SET_PIXELS_JS
# put!(BroadcastBrowser, js)


# collapsed=CACHE
# canvas=canvas_3d
# δ
# combine=Main.ColorModule.blend
# collapse_dimension=3
# collapse_dimension_size = size(canvas.pixels, collapse_dimension)
# N=3
# δ̂ = Tuple{CartesianIndex{N}, Color}[]
# non_collapse_dimensions = setdiff(1:N, collapse_dimension)
# non_collapse_index = unique(i.I[non_collapse_dimensions] for (i, _) in δ)
# i = non_collapse_index[1]
# # for i = non_collapse_index
# pixel = CLEAR
# collapse_index = (collapse_dimension_size:-1:1)[10]
# # for collapse_index = collapse_dimension_size:-1:1
# canvas_i = CartesianIndex{N}(ntuple(j -> j < collapse_dimension ? i[j] : (j == collapse_dimension ? collapse_index : i[j-1]), N))
# canvas.pixels[canvas_i], pixel
# pixel = combine(canvas.pixels[canvas_i], pixel)
# 1.0 ≤ Main.ColorModule.opacity(pixel) # && break
# # end
# î = CartesianIndex{N}((i..., 1))
# collapsed.pixels[î] == pixel && continue
# collapsed.pixels[î] = pixel
#     push!(δ̂, (î, pixel))
# # end
# info(collapsed.pixels)

end
