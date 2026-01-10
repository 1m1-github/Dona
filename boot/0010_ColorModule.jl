module ColorModule

export Color

import Main: @install
@install StaticArrays
import StaticArrays: SVector

struct Color <: AbstractVector{Float64}
    data::SVector{4,Float64}
end
# Base.broadcastable(c::Color) = Ref(c)
# d=SVector{4,Float64}(1.0,1.0,1.0,1.0)
# Color(d)==Color(d)
Color(r,g,b,a=1.0) = Color(SVector{4,Float64}(float([r,g,b,a])...))
Color(x) = Color(x,x,x)
Color(c::Color, α) = Color(c[1], c[2], c[3], α)
clear(c::Color) = Color(c, 0)
opacity(c::Color) = c[4]
# import Base: size, getindex, ==
Base.size(::Color) = (4,)
Base.getindex(c::Color, i::Int) = c.data[i]
# Base.:(==)(a::Color, b::Color) = a.data == b.data

const BLACK = Color(0)
const CLEAR = clear(BLACK)
const BLUE = Color(0, 0, 1)
const GREEN = Color(0, 1, 0)
const TURQUOISE = Color(0, 1, 1)
const RED = Color(1, 0, 0)
const PINK = Color(1, 0, 1)
const YELLOW = Color(1, 1, 0)
const WHITE = Color(1)
export BLACK,CLEAR,BLUE,GREEN,TURQUOISE,RED,PINK,YELLOW,WHITE

import Base.∘
"Fair information theoretic mixture"
function ∘(a::Color, b::Color)
    α = opacity(a)
    β = opacity(b)
    total = 0.5 * α + 0.5 * β
    total == 0.0 && return CLEAR
    wa, wb = 0.5 * α / total, 0.5 * β / total
    Color((wa * a + wb * b)[1:3]..., α + β - α * β) # todo check new opacity
end

"`b` dominates in opacity"
function blend(bottom::Color, top::Color)
    α = opacity(top)
    1.0 ≤ α && return top
    t = (1.0 - α) * opacity(bottom)
    Color((top + t * bottom)[1:3]...,α + t)
end

using Test
begin
tests = [
    (CLEAR, WHITE) => WHITE,
    (BLACK, WHITE) => WHITE,
    (Color(1,0,0,0.5), Color(0,1,0,0.5)) => Color(0.25,1.0,0,0.75),
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
    @test ∘(test[1]...) ≈ test[2]
end
end

end
