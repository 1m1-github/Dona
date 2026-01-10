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
#set page(width: auto, height: auto, margin: (top: 5pt, bottom: 5pt, left: 5pt, right: 5pt))
#set text(font: "EB Garamond", size: 20pt)
$content
"""

const CACHE = Dict{String,Canvas}()
function Canvas(typst_code::String)
    cmd = `typst compile - --format png -`
    rgba_pixels = pipeline(IOBuffer(TEMPLATE(typst_code)), cmd) |> read |> IOBuffer |> PNGFiles.load
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

end
