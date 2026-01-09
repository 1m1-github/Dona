module DrawingModule

export Drawing

import Main: @install
@install StaticArrays
import StaticArrays: SVector

"""
Draw inside an N dimensional unit square, 0=bottom-left.
`Drawing`s are typically used in a `Sprite`.
E.g.:
sky = Drawing("sky", coordinates -> Color(0.1, 0, 1))
upper_half = Rectangle("upper half", [0.5, 0.75], [0.5, 0.25])
sky_sprite = Sprite("sky in upper half", sky, upper_half)
put!(BroadcastBrowserCanvas, sky_sprite)
"""
struct Drawing{N}
    id::String
    f::Function # N-dim unit hypercube vector -> Color
end
(d::Drawing)(x::SVector) = d.f(x)
(d::Drawing)(x::Vector) = d.f(SVector{length(x)}(x))
(d::Drawing)(x::NTuple) = d.f(SVector(x...))

import Base.∘
import Main.ColorModule: ∘
"""
Drawing composition using fair information theoretic color composition.
E.g.:
sky = rect("half rect", [0.7, 0.75], [0.25, 0.5], TURQUOISE)
sun = circle("sun", [0.75, 0.75], 0.3, YELLOW)
cloud = square("cloud", [0.25, 0.75], 0.2, WHITE)
scene = cloud ∘ sun ∘ sky # cloud ontop of the sun ontop of the sky
"""
∘(a::Drawing{N}, b::Drawing{N}) where N = Drawing{N}(a.id * b.id, x -> a(x) ∘ b(x))
export ∘

import Main.ColorModule: CLEAR
export circle, rect, square
"""
A N dimensional ball with a metric `d`
"""
ball(id, c, r, color, d) = Drawing{length(c)}(id, x -> all(d(x,c) .≤ r) ? color : CLEAR)
"""`sun::Drawing = circle("sun", [0.75, 0.75], 0.1, YELLOW)`"""
circle(id, c, r, color) = ball(id, c, r, color, (x,y) -> hypot((x .- y)...))
"""`sky::Drawing = rect("half rect", [0.5, 0.75], [0.25, 0.5], TURQUOISE)`"""
rect(id, c, r, color) = ball(id, c, r, color, (x,y) -> abs.(x .- y))
"""`s::Drawing = square("full square", [0.5, 0.5], 0.5, YELLOW)`"""
square(id, c, r, color) = rect(id, c, fill(minimum(r),length(r)), color)

using Test
begin
    import Main.ColorModule: WHITE, BLACK
    tests = [
        (square("", [0.5], 0.05, WHITE), [0.4]) => CLEAR
        (square("", [0.5], 0.05, WHITE), [0.54]) => WHITE
        (rect("", [0.5,0.5], [0.05,0.1], WHITE), [0.6,0.6]) => CLEAR
        (rect("", [0.5,0.5], [0.05,0.1], WHITE), [0.54,0.59]) => WHITE
        (circle("", [0.5], 0.05, WHITE), [1,1]) => CLEAR
        (circle("", [0.5], 0.05, WHITE), [0.5,0.5]) => WHITE
        (square("", [0.6], 0.1, BLACK) ∘ square("", [0.5], 0.1, WHITE), [0.3]) => CLEAR
        (square("", [0.6], 0.1, BLACK) ∘ square("", [0.5], 0.1, WHITE), [0.6]) => WHITE ∘ BLACK
        (square("", [0.6], 0.1, BLACK) ∘ square("", [0.5], 0.1, WHITE), [0.7]) => BLACK
    ]
    for test in tests
        @test test[1][1](test[1][2:end]...) ≈ test[2]
    end
end

end
