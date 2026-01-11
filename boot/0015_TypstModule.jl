module TypstModule

import Main: @install
@install PNGFiles
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
    pixels = fill(CLEAR, size(rgba_pixels))
    for (i, pixel) = enumerate(rgba_pixels)
        all(isone.([pixel.r, pixel.g, pixel.b, pixel.alpha])) && continue # WHITE->CLEAR
        pixels[i] = Color(SVector{4,Float64}(
            Float64(pixel.r),
            Float64(pixel.g),
            Float64(pixel.b),
            Float64(pixel.alpha)))
    end
    Canvas(pixels, Set([1, 2]))
end

function _typst_drawing(typst_code::String, coordinates::SVector{2,Float64})
    !haskey(CACHE, typst_code) && (CACHE[typst_code] = Canvas(typst_code))
    canvas = CACHE[typst_code]
    h, w = size(canvas.pixels)
    x = clamp(round(Int, coordinates[1] * w), 1, w)
    y = clamp(round(Int, (1 - coordinates[2]) * h), 1, h)  # flip y
    canvas.pixels[y, x]
end
typst_drawing(typst_code::String) = Drawing{2}(coordinates -> _typst_drawing(typst_code, coordinates))
function typst_rectangle(typst_code::String, center::SVector{2,Float64}, radius_width::Float64)
    !haskey(CACHE, typst_code) && (CACHE[typst_code] = Canvas(typst_code))
    canvas = CACHE[typst_code]
    h, w = size(canvas.pixels)
    Rectangle(center,[radius_width,radius_width*h/w])
end
export typst_drawing, typst_rectangle

end
