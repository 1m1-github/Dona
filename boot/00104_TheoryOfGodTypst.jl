# ── Typst Φ: text → pixel matrix → lookup ───────────────────────────────────

const DPI = 144
const TYPST_TEMPLATE(content) = """
#set page(width: auto, height: auto, margin: (top: 5pt, bottom: 5pt, left: 5pt, right: 5pt))
#set text(font: "EB Garamond", size: 20pt)
$content
"""

const TYPST_CACHE = Dict{UInt,Matrix{T}}()

function typst_to_matrix(typst_code::String)
    h = hash(typst_code)
    haskey(TYPST_CACHE, h) && return TYPST_CACHE[h]
    cmd = `typst compile - --format png --ppi $DPI -`
    rgba = pipeline(IOBuffer(TYPST_TEMPLATE(typst_code)), cmd) |> read |> IOBuffer |> PNGFiles.load
    # convert to T ∈ [0,1]: use luminance, invert (black text → high Φ)
    mat = Matrix{T}(one(T) .- T.(Float64.(red.(rgba))))
    TYPST_CACHE[h] = mat
    mat
end

function Φ_typst(mat::Matrix{T})
    H, W = size(mat)
    (x, y) -> begin
        px = clamp(round(Int, x * (W - 1)) + 1, 1, W)
        py = clamp(round(Int, y * (H - 1)) + 1, 1, H)
        mat[py, px]
    end
end
