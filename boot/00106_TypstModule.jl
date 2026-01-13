module TypstModule

import Main: @install
@install PNGFiles

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

const CACHE = Dict{String,AbstractArray{Color,2}}()
function create(typst_code)
    cmd = `typst compile - --format png -`
    rgba_pixels = pipeline(IOBuffer(TEMPLATE(typst_code)), cmd) |> read |> IOBuffer |> PNGFiles.load
    pixels = fill(CLEAR, reverse(size(rgba_pixels)))
    for i = 1:size(rgba_pixels, 1), j = 1:size(rgba_pixels, 2)
        pixel = rgba_pixels[i, j]
        all(isone.([pixel.r, pixel.g, pixel.b, pixel.alpha])) && continue # WHITE -> CLEAR
        pixels[j, i] = Color(
            Float64(pixel.r),
            Float64(pixel.g),
            Float64(pixel.b),
            Float64(pixel.alpha))
    end
    pixels
end

function color(typst_code, coordinates)
    !haskey(CACHE, typst_code) && (CACHE[typst_code] = create(typst_code))
    pixels = CACHE[typst_code]
    w, h = size(pixels)
    x = clamp(round(Int, coordinates[1] * w), 1, w)
    y = clamp(round(Int, (1 - coordinates[2]) * h), 1, h)
    pixels[x, y]
end
typst_drawing(typst_code) = Drawing(coordinates -> color(typst_code, coordinates))
function typst_rectangle(typst_code)
    !haskey(CACHE, typst_code) && (CACHE[typst_code] = create(typst_code))
    pixels = CACHE[typst_code]
    w, h = size(pixels)
    radius_height = 0.5 * h / w
    @show "typst_rectangle", w, h, radius_height
    Rectangle([0.5, 0.5], [0.5, radius_height])
end
typst_sprite(typst_code) = Sprite(typst_drawing(typst_code), typst_rectangle(typst_code), typst_code)
export typst_sprite

end
