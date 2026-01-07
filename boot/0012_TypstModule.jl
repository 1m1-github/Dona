module TypstModule

import Main: @install
@install PNGFiles, StaticArrays
import StaticArrays: SVector
import Main: GraphicsModule
import Main.GraphicsModule: Canvas, Region, Sprite

const DPI = 300
const TEMPLATE(content) = """
#set page(width: auto, height: auto, margin: (top: 0pt, bottom: 4pt, left: 0pt, right: 0pt))
#set text(font: "EB Garamond", size: 20pt)
$content
"""

const CACHE = Ref(Dict{String,Canvas}())
function Canvas(typst_code::String)
    cmd = `typst compile - --format png -`
    pixels = pipeline(IOBuffer(typst_code), cmd) |> read |> IOBuffer |> PNGFiles.load
    GraphicsModule.Canvas(typst_code, pixels)
end
function typst_drawing(typst_code::String, coordinates::SVector{2,Float64})
    !haskey(CACHE[], typst_code) && (CACHE[][typst_code] = Canvas(typst_code))
    canvas = CACHE[][typst_code]
    w, h = size(canvas.pixels)
    x = clamp(round(Int, coordinates[1] * w), 1, w)
    y = clamp(round(Int, coordinates[2] * h), 1, h)
    canvas.pixels[x, y]
end
typst_region = Region("full", [0.5, 0.5], [0.5, 0.5])
typst_sprite(typst_code) = Sprite(
    typst_code,
    coordinates -> typst_drawing(typst_code, coordinates),
    typst_region)
typst(canvas, typst_code) = put!(canvas, typst_sprite(typst_code))

end
