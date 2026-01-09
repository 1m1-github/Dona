module ColorModule

import Colors: RGBA
const Color = RGBA{Float64}
Color(c::Color, α) = Color(c.r, c.g, c.b, α)
export Color

const BLACK = Color(0, 0, 0)
const BLUE = Color(0, 0, 1)
const GREEN = Color(0, 1, 0)
const TURQUOISE = Color(0, 1, 1)
const RED = Color(1, 0, 0)
const PINK = Color(1, 0, 1)
const YELLOW = Color(1, 1, 0)
const WHITE = Color(1, 1, 1)
clear(c::Color) = Color(c, 0)
const CLEAR = clear(BLACK)

"Fair information theoretic mixture"
function average(a::Color, b::Color)
    total = 0.5 * a.alpha + 0.5 * b.alpha
    0.5*(a.alpha + b.alpha)
    a.alpha + b.alpha
    a.alpha
    b.alpha
    0.5 * a.alpha
    0.5 * b.alpha
    total == 0.0 && return CLEAR
    wa, wb = 0.5 * a.alpha / total, 0.5 * b.alpha / total
    Color(
        a.r * wa + b.r * wb,
        a.g * wa + b.g * wb,
        a.b * wa + b.b * wb,
        a.alpha + b.alpha - a.alpha * b.alpha
    )
end

"`b` dominates in opacity"
function blend(a::Color, b::Color)
    b.alpha == 1.0 && return b
    b.alpha == 0.0 && return a
    β = 1.0 - b.alpha
    Color(b.alpha * b.r + β * a.r, b.alpha * b.g + β * a.g, b.alpha * b.b + β * a.b, a.alpha + b.alpha - a.alpha * b.alpha)
end

using Test
begin
tests = [
    (CLEAR, WHITE) => WHITE,
    (BLACK, WHITE) => WHITE,
    (Color(1,0,0,0.5), Color(0,1,0,0.5)) => Color(0.5,0.5,0,0.75),
]
for test in tests
    @test blend(test[1]...) ≈ test[2]
end
tests = [
    (CLEAR, WHITE) => Color(1,1,1,1),
    (BLACK, WHITE) => Color(0.5,0.5,0.5,1.0),
    (Color(1,0,0,0.5), Color(0,1,0,0.5)) => Color(0.5,0.5,0,0.75),
]
for test in tests
    @test average(test[1]...) ≈ test[2]
end
end

end
