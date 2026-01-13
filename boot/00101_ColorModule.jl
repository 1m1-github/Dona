using .PkgModule
@install StaticArrays
import StaticArrays: SVector, SA
module ColorModule

import StaticArrays: SVector

struct Color{T<:Real} <: AbstractVector{T}
    data::SVector{4,T}
    function Color{T}(data::SVector{4,T}) where {T<:Real}
        any(x -> x < zero(T) || x > one(T), data) &&
            error("Color components must be in [0,1]: $data")
        new{T}(data)
    end
end
export Color
Color(data::SVector{4,T}) where T<:Real = Color{T}(data)
Color(data::AbstractVector{T}) where T<:Real = Color{T}(SVector{4,T}(data))
Color(r, g, b, a=1.0) = Color(SVector{4}(promote(r, g, b, a)...))
Color(x) = Color(x, x, x)
Color(color::Color, α) = Color(color[1], color[2], color[3], α)
Base.size(::Color) = (4,)
Base.getindex(color::Color, i::Int) = color.data[i]
clear(color::Color) = Color(color, 0.0)
opaque(color::Color) = Color(color, 1.0)
invert(color::Color) = Color(one(eltype(color)) .- color.data)
opacity(color::Color) = color[4]
export invert, opaque, clear

const BLACK = Color(0.0)
const CLEAR = clear(BLACK)
const BLUE = Color(0, 0, 1)
const GREEN = Color(0, 1, 0)
const TURQUOISE = Color(0, 1, 1)
const RED = Color(1, 0, 0)
const PINK = Color(1, 0, 1)
const YELLOW = Color(1, 1, 0)
const WHITE = Color(1.0)
export BLACK, CLEAR, BLUE, GREEN, TURQUOISE, RED, PINK, YELLOW, WHITE

"Fair information theoretic mixture"
function Base.:∘(a::Color{T}, b::Color{T}) where T
    α, β = opacity(a), opacity(b)
    total = α + β
    iszero(total) && return CLEAR
    wa, wb = α / total, β / total
    rgb = wa * a[1:3] + wb * b[1:3]
    Color(rgb..., α + β - α * β)
end

"`top` dominates in opacity"
function blend(bottom::Color{T}, top::Color{T}) where T
    α = opacity(top)
    isone(α) && return top
    β = (one(T) - α) * opacity(bottom)
    rgb = α * top[1:3] + β * bottom[1:3]
    Color(rgb..., α + β)
end

using Test
begin
    tests = [
        (CLEAR, WHITE) => WHITE,
        (BLACK, WHITE) => WHITE,
        (Color(1, 0, 0, 0.5), Color(0, 1, 0, 0.5)) => Color(0.25, 0.5, 0, 0.75),
    ]
    for test in tests
        @test blend(test[1]...) ≈ test[2]
    end
    tests = [
        (CLEAR, WHITE) => Color(1, 1, 1, 1),
        (BLACK, WHITE) => Color(0.5, 0.5, 0.5, 1.0),
        (Color(1, 0, 0, 0.5), Color(0, 1, 0, 0.5)) => Color(0.5, 0.5, 0, 0.75),
    ]
    for test in tests
        @test ∘(test[1]...) ≈ test[2]
    end
end

end
