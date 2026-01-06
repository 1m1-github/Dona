module BroadcastBrowserCanvasModule

import Main: @install
@install StaticArrays, JSON3

import Main.StateModule: state
import Main: LoopOS

import Main.ColorModule: CLEAR, Color
import Main.DrawingModule: Drawing
import Main.GraphicsModule: Region, Sprite, Canvas, collapse, blend

struct BroadcastBrowserCanvas <: LoopOS.OutputPeripheral
    browser_task::Task
    canvas::Canvas
end
function Δ(old, new)
    pixels = fill(CLEAR, size(new.pixels))
    for i in eachindex(new.pixels)
        old.pixels[i] == new.pixels[i] && continue
        pixels[i] = new.pixels[i]
    end
    Canvas(new.id, pixels)
end

function root(port, bb)
    @info "BroadcastBrowserCanvas HTTP port $port $(bb.stream)"
    δ = Δ(Canvas("root", fill(WHITE, size(CACHE[].pixels))), CACHE[])
    js = "pixels=" * write(δ) * "\n" * SET_PIXELS_JS
    put!(BroadcastBrowser, js)
end

write(canvas::Canvas) = JSON3.write(canvas.pixels)

const JS = raw"""
x = {w: window.innerWidth, h: window.innerHeight, dpr: window.devicePixelRatio}
document.body.appendChild(document.createElement('canvas'))
const canvas = document.getElementById('canvas')
const ctx = canvas.getContext('2d')
let imageData = ctx.createImageData(window.innerWidth, window.innerHeight)
function setPixel(x, y, r, g, b, alpha) {
    const i = (y * canvas.width + x) * 4
    imageData.data[i] = r
    imageData.data[i+1] = g
    imageData.data[i+2] = b
    imageData.data[i+3] = alpha
}
sse.onmessage = (e) => {
    const data = JSON.parse(e.data)
    for (const [x,y,r,g,b,a] of data.pixels) setPixel(x,y,r,g,b,a)
    ctx.putImageData(imageData, 0, 0)
}
"""
const SET_PIXELS_JS = """
for (const [x,y,r,g,b,a] of pixels) setPixel(x,y,r,g,b,a)
ctx.putImageData(imageData, 0, 0)
"""

import Main: BroadcastBrowserModule
import Main.BroadcastBrowserModule: BroadcastBrowser
const BROADCASTBROWSERCANVAS_WIDTH = 200
const BROADCASTBROWSERCANVAS_HEIGHT = 100
# const BROADCASTBROWSERCANVAS_WIDTH = 3056
# const BROADCASTBROWSERCANVAS_HEIGHT = 3152
const BROADCASTBROWSERCANVAS = Ref(BroadcastBrowserCanvas(
    (Threads.@spawn BroadcastBrowserModule.start(root)),
    Canvas{4}(
        "BroadcastBrowserCanvas",
        fill(CLEAR, (BROADCASTBROWSERCANVAS_WIDTH, BROADCASTBROWSERCANVAS_HEIGHT, 100, 10))))) # width, height, depth, time # todo test half and double
const CACHE = Ref(Canvas{2}("CACHE", fill(CLEAR, (BROADCASTBROWSERCANVAS_WIDTH, BROADCASTBROWSERCANVAS_HEIGHT))))

const WHITE = Color(1.0, 1.0, 1.0, 1.0)
const FULL_BOTTOM_LAYER = Region("full", SA[0.5, 0.5, 0.0, 0.0], SA[0.5, 0.5, 0.0, 0.0])
const WHITE_DRAWING = Drawing{2}("white", _ -> WHITE)
const WHITE_SPRITE = Sprite("WHITE_SPRITE", WHITE_DRAWING, FULL_BOTTOM_LAYER)
import Base: put!
"Use this mainly and simply to display any `Sprite` on all browsers"
function put!(sprite::Sprite)
    Δ_index = put!(BROADCASTBROWSERCANVAS[].canvas, sprite)
    cache = collapse(BROADCASTBROWSERCANVAS[].canvas, Δ_index, blend)
    cache = Canvas("CACHE", cache.pixels[:, :, end, end])
    δ = Δ(cache, CACHE[])
    CACHE[] = cache
    js = "pixels=" * write(δ) * "\n" * SET_PIXELS_JS
    put!(BroadcastBrowser, js)
end

import Main.TypstModule: typst
raw"""Only needs the inner small Typst code, like $ int $`typst(raw"$ x^2 $")` gives a x^2 Sprite"""
typst(typst_code::String)::Sprite = TypstModule.typst(BROADCASTBROWSERCANVAS[].canvas, typst_code)
export typst

end
