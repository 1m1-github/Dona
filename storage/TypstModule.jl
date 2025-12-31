module TypstModule

# export add_typst_sprite

import Main.CanvasModule: RGBA, add_sprite!
using PNGFiles
using Colors: red, green, blue, alpha

const DPI = 300
const WHITE_THRESHOLD = 250

TEMPLATE(content) = "#set page(width: auto, height: auto, margin: 0pt)\n$content"

function load_png(path::String; transparent_white::Bool=true)
    img = PNGFiles.load(path)
    h, w = size(img)
    pixels = Matrix{RGBA}(undef, h, w)
    for y in 1:h, x in 1:w
        c = img[y, x]
        r = round(UInt8, red(c) * 255)
        g = round(UInt8, green(c) * 255)
        b = round(UInt8, blue(c) * 255)
        a = round(UInt8, alpha(c) * 255)
        if transparent_white && r >= WHITE_THRESHOLD && g >= WHITE_THRESHOLD && b >= WHITE_THRESHOLD
            pixels[y, x] = RGBA(0, 0, 0, 0)
        else
            pixels[y, x] = RGBA(r, g, b, a)
        end
    end
    pixels
end

"compiles a Typst with 300 DPI and calls CanvasModule.add_sprite!"
function add_typst_sprite(code::String; x=0, y=0, z=0, desc="")
    dir = mktempdir()
    typ_file = joinpath(dir, "input.typ")
    png_file = joinpath(dir, "output.png")
    
    full_code = TEMPLATE(code)
    write(typ_file, full_code)
    
    run(`typst compile --format png --ppi $DPI $typ_file $png_file`)
    
    if !isfile(png_file)
        error("Typst compilation failed")
    end
    
    pixels = load_png(png_file)
    rm(dir; recursive=true)
    
    add_sprite!(Symbol(desc), x, y, z, pixels, desc)
end

end
