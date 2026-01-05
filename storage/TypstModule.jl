module TypstModule

export typst_sprite, TYPST_ADVICE

const TYPST_ADVICE = """
The TypstModule allows you to create a Sprite based on Typst code using `typst_sprite`.
The page params are set automatically.
`put!(typst_sprite((0.5,0.5), "hi"))` would draw "hi" in the center on top of all other sprites (Inf z depth).
"""

import Main: @install
@install PNGFiles, Colors
import Colors: RGBA
import Main.CanvasModule: Position, Pixels, Sprite, WHITE, CLEAR

const DPI = 300
const TEMPLATE(content) = """
#set page(width: auto, height: auto, margin: (top: 0pt, bottom: 4pt, left: 0pt, right: 0pt))
#set text(font: "EB Garamond", size: 20pt)
$content
"""

# function load_png(path::String; transparent_white::Bool=true)
function load_png(path::String)::Pixels
    img = PNGFiles.load(path)
    h, w = size(img)
    pixels = Matrix{RGBA}(undef, h, w)
    for y in 1:h, x in 1:w
        c = img[y, x]
        # if transparent_white && c == WHITE
            # pixels[y, x] = CLEAR
        # else
            pixels[y, x] = c
        # end
    end
    pixels
end


source = """#set page(width: auto, height: auto, margin: 5pt)\n\$ x^2 \$"""
function typst_to_png(source)
    cmd = `typst compile - --format png -`
    pipeline(IOBuffer(source), cmd) |> read |> IOBuffer |> PNGFiles.load
end
typst_to_png(source)


"compiles Typst code and returns a Sprite"
typst_sprite(id::String, pos::Position, code::String)::Sprite = Sprite(id, pos, typst_pixels(code))
function typst_pixels(code::String)::Pixels
    dir = mktempdir()
    typ_file = joinpath(dir, "input.typ")
    png_file = joinpath(dir, "output.png")
    full_code = contains(code, TEMPLATE("")) ? code : TEMPLATE(code)
    write(typ_file, full_code)
    run(`typst compile --format png --ppi $DPI $typ_file $png_file`)
    !isfile(png_file) && error("Typst compilation failed")
    pixels = load_png(png_file)
    rm(dir; recursive=true)
    pixels
end

end
