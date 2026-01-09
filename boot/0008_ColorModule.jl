module ColorModule

import Colors: RGBA
import FixedPointNumbers: N0f8
const Color = RGBA{N0f8}
export Color

const CLEAR = Color(0.0, 0.0, 0.0, 0.0)
const WHITE = Color(1, 1, 1, 1)
const BLACK = Color(0, 0, 0, 1)
const RED = Color(1, 0, 0, 1)
const GREEN = Color(0, 1, 0, 1)
const BLUE = Color(0, 0, 1, 1)
const YELLOW = Color(1, 1, 0, 1)

function average(a::Color, b::Color)
    total = 0.5 * a.alpha + 0.5 * b.alpha
    total == 0.0 && return CLEAR
    wa, wb = 0.5 * a.alpha / total, 0.5 * b.alpha / total
    Color(
        a.r * wa + b.r * wb,
        a.g * wa + b.g * wb,
        a.b * wa + b.b * wb,
        a.alpha + b.alpha - a.alpha * b.alpha
    )
end
function blend(a::Color, b::Color)
    b.alpha == 1.0 && return b
    b.alpha == 0.0 && return a
    α = Float64(b.alpha)
    β = 1.0 - α
    Color(α * b.r + β * a.r, α * b.g + β * a.g, α * b.b + β * a.b, 1.0)
end

end
