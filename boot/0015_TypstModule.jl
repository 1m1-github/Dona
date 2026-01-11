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
    @show typeof(rgba_pixels)
    pixels = fill(CLEAR, reverse(size(rgba_pixels)))
    @show typeof(pixels)
    for i = 1:size(rgba_pixels,1), j = 1:size(rgba_pixels,2)
        pixel = rgba_pixels[i, j]
        all(isone.([pixel.r, pixel.g, pixel.b, pixel.alpha])) && continue # WHITE -> CLEAR
        # @show i, typeof(i)
        pixels[j, i] = Color(SVector{4,Float64}(
            Float64(pixel.r),
            Float64(pixel.g),
            Float64(pixel.b),
            Float64(pixel.alpha)))
    end
    Canvas(pixels, Set([1, 2]))
end

function typst_drawing(typst_code::String, coordinates::SVector{2,Float64})
    !haskey(CACHE, typst_code) && (CACHE[typst_code] = Canvas(typst_code))
    canvas = CACHE[typst_code]
    w,h = size(canvas.pixels)
    @show "typst_drawing", w,h
    x = clamp(round(Int, coordinates[1] * w), 1, w)
    y = clamp(round(Int, (1 - coordinates[2]) * h), 1, h)
    @show "typst_drawing", x, y
    canvas.pixels[x, y]
end
typst_drawing(typst_code::String) = Drawing{2}(coordinates -> typst_drawing(typst_code, coordinates))
function typst_rectangle(typst_code::String, center::SVector{2,Float64}, radius_width::Float64)
    !haskey(CACHE, typst_code) && (CACHE[typst_code] = Canvas(typst_code))
    canvas = CACHE[typst_code]
    w,h = size(canvas.pixels)
    @show "typst_rectangle", w,h, radius_width,radius_width*h/w
    Rectangle(center,[radius_width,radius_width*h/w])
end
typst_sprite(typst_code::String, center::SVector{2,Float64}, radius_width::Float64) = Sprite(typst_drawing(typst_code), typst_rectangle(typst_code, center, radius_width))
export typst_sprite

end
