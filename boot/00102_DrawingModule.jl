module DrawingModule

import StaticArrays: SVector

import Main.ColorModule: Color

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
    f::Function # N dimensional unit square vector -> Color
    id::AbstractString
    function Drawing{N}(f::Function, id::AbstractString="") where N
        !isa(f(zero(SVector{N,<:Real})), Color) && error("Drawing f(x) needs to be Color")
        new{N}(f,id)
    end
end
export Drawing
Drawing(f, id="") = Drawing{2}(f, id)
(d::Drawing{N})(x::SVector{N,<:Real}) where N = d.f(x)
(d::Drawing{N})(x::AbstractVector) where N = d(SVector{length(x)}(x))
(d::Drawing{N})(x::NTuple{N,<:Real}) where N  = d(SVector(x))

"""
Drawing composition using fair information theoretic color composition.
E.g.:
sky = rect("half rect", [0.7, 0.75], [0.25, 0.5], TURQUOISE)
sun = circle("sun", [0.75, 0.75], 0.3, YELLOW)
cloud = square("cloud", [0.25, 0.75], 0.2, WHITE)
scene = cloud ∘ sun ∘ sky # cloud ontop of the sun ontop of the sky
"""
Base.:∘(a::Drawing{N}, b::Drawing{N}) where N = Drawing{N}(x -> a(x) ∘ b(x), a.id * " ∘ " * b.id)
Base.:∘(f::Function, d::Drawing{N}) where N = Drawing{N}(f ∘ d.f, "$f after " * d.id)

import Main.ColorModule: CLEAR
"""
A N dimensional ball with a metric `distance`
"""
ball(center, radius, color, distance, id="") = Drawing{length(center)}(x -> all(distance(x, SVector{length(center)}(center)) .≤ radius) ? color : CLEAR, id)
"""`sun::Drawing = circle("sun", [0.75, 0.75], 0.1, YELLOW)`"""
circle(center, radius, color, id="") = ball(center, radius, color, (x, y) -> hypot((x - y)...), id)
"""`sky::Drawing = rect("half rect", [0.5, 0.75], [0.25, 0.5], TURQUOISE)`"""
rect(center, radius, color, id="") = ball(center, radius, color, (x, y) -> abs.(x - y), id)
"""`s::Drawing = square("full square", [0.5, 0.5], 0.5, YELLOW)`"""
square(center, radius, color, id="") = rect(center, fill(radius, length(center)), color, id)
export circle, rect, square

using Test
begin
    import Main.ColorModule: WHITE, BLACK
    tests = [
        (square([0.5], 0.05, WHITE), [0.4]) => CLEAR
        (square([0.5], 0.05, WHITE), [0.54]) => WHITE
        (rect([0.5,0.5], [0.05,0.1], WHITE), [0.6,0.6]) => CLEAR
        (rect([0.5,0.5], [0.05,0.1], WHITE), [0.54,0.59]) => WHITE
        (circle([0.5], 0.05, WHITE), [1]) => CLEAR
        (circle([0.5], 0.05, WHITE), [0.5]) => WHITE
        (square([0.6], 0.1, BLACK) ∘ square([0.5], 0.1, WHITE), [0.3]) => CLEAR
        (square([0.6], 0.1, BLACK) ∘ square([0.5], 0.1, WHITE), [0.6]) => WHITE ∘ BLACK
        (square([0.6], 0.1, BLACK) ∘ square([0.5], 0.1, WHITE), [0.7]) => BLACK
    ]
    for test in tests
        @test test[1][1](test[1][2:end]...) ≈ test[2]
    end
end

end
