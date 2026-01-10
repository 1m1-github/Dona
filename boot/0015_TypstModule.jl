module TypstModule

import Main: @install
@install PNGFiles, StaticArrays
import StaticArrays: SVector

import Main.ColorModule: Color, WHITE, CLEAR
import Main.DrawingModule: Drawing
import Main.RectangleModule: Rectangle
import Main.SpriteModule: Sprite
import Main.CanvasModule: Canvas

const DPI = 300
const TEMPLATE(content) = """
#set page(width: auto, height: auto, margin: (top: 0pt, bottom: 4pt, left: 0pt, right: 0pt))
#set text(font: "EB Garamond", size: 20pt)
$content
"""

const CACHE = Dict{String,Canvas}()
function Canvas(typst_code::String)
    cmd = `typst compile - --format png -`
    rgba_pixels = pipeline(IOBuffer(typst_code), cmd) |> read |> IOBuffer |> PNGFiles.load
    pixels = map(rgba_pixels) do p
        Color(SVector{4,Float64}(
            Float64(p.r),
            Float64(p.g),
            Float64(p.b),
            Float64(p.alpha)))
    end
    pixels[pixels .== Ref(WHITE)] .= Ref(CLEAR)
    Canvas(pixels, Set([1,2]))
end
function typst_drawing(typst_code::String, coordinates::SVector{2,Float64})
    !haskey(CACHE, typst_code) && (CACHE[typst_code] = Canvas(typst_code))
    canvas = CACHE[typst_code]
    w, h = size(canvas.pixels)
    x = clamp(round(Int, coordinates[1] * w), 1, w)
    y = clamp(round(Int, coordinates[2] * h), 1, h)
    canvas.pixels[x, y]
end
# typst_sprite(typst_code) = Sprite(
#     Drawing{2}(coordinates -> typst_drawing(typst_code, coordinates)),
#     Rectangle([0.5, 0.5], [0.5, 0.5]))
# typst(canvas, typst_code) = put!(canvas, typst_sprite(typst_code))

# using Test
# begin
#     import Main.ColorModule: WHITE, BLACK
#     canvas = Canvas("",fill(CLEAR,200,100,2,3),Set([1,2]))
#     tests = [
#         () => 
#     ]
#     for test in tests
#         typst(canvas, "\$x^2\$")
#         @test test[1][1](test[1][2:end]...) ≈ test[2]
#     end
# end

end
