# module ωBrowserModule

# import Main.LoopOS: OutputPeripheral

# struct godBrowser <: OutputPeripheral
struct godBrowser
    g::god
    loop::Task
    browser::BroadcastBrowser
end
godBrowser(g,browser) = godBrowser(g, Threads.@spawn begin
    try
put!(browser.processor, JS(g.♯[2], g.♯[3]))
t = time()
pixel = fill((one(T),one(T),one(T),one(T)), g.♯[2],g.♯[3])
while true
    sleep(5)
    yield()
    t̂ = time()
    dt = t̂ - t
    t = t̂
    step(g, dt)
    p̂ixel = observe(g)
    @show p̂ixel
    δ = Δ(pixel, p̂ixel)
    @show δ
    isempty(δ) && continue
    js = "pixel=" * write(δ, g.♯[2]) * "\n" * SET_PIXELS_JS
    put!(browser.processor, js)
end
catch e @show e end
end
, browser)
function godBrowser(browser)
    @show "godBrowser"
    dimx, dimy, dimc = T(0.1),T(0.2),T(0.3)
    x, y = T(0.1),T(0.1)
    # g = god{T}(dimx, dimy, dimc, x, y, browser.width, browser.height)
    # g = god{T}(dimx, dimy, dimc, x, y, T(200), T(100))
    g = god{T}(dimx, dimy, dimc, x, y, T(2^3), T(2^3))
    gb = godBrowser(g, browser)
    push!(godBROWSER[], gb)
    gb
end
# put!(::godBrowser) = nothing # todo ?
const godBROWSER = Ref(Set{godBrowser}())

function Δ(pixel, p̂ixel)
    δ = Tuple{CartesianIndex{2},Tuple{T,T,T,T}}[]
    # i = collect(CartesianIndices(p̂ixel))[1]
    for i = CartesianIndices(p̂ixel)
        p̂ = p̂ixel[i]
        p̂ == pixel[i] && continue
        push!(δ, (i,p̂))
    end
    δ
end

function write(δ, height)
    result = []
    for (i, color) = δ
        @show i, color
        push!(result, (i[1] - 1, height - 1 - (i[2] - 1), round.(UInt8, typemax(UInt8) * color)...))
    end
    bracket(x) = "[" * x * "]"
    bracket(join(map(r -> bracket(join(r, ',')), result), ','))
end

const JS(width, height) = """
document.body.style.margin = '0'
document.body.style.display = 'flex'
document.body.style.justifyContent = 'center'
document.body.style.alignItems = 'center'
document.body.style.minHeight = '100vh'
canvas = document.createElement('canvas')
canvas.width = $(width)
canvas.height = $(height)
document.body.appendChild(canvas)
ctx = canvas.getContext('2d')
imageData = ctx.createImageData(canvas.width, canvas.height)
setPixel = (x, y, r, g, b, a) => {
    let i = (y * canvas.width + x) * 4
    imageData.data[i] = r
    imageData.data[i+1] = g
    imageData.data[i+2] = b
    imageData.data[i+3] = a
}
"""
const SET_PIXELS_JS = """
for (let [x,y,r,g,b,a] of pixel) setPixel(x,y,r,g,b,a)
ctx.putImageData(imageData, 0, 0)
"""

# end
