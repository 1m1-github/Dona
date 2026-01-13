module RectangleModule

import StaticArrays: SVector

"""
An N dimensional rectangle inside an N dimensional unit square with 0=bottom-left.
`Rectangle`s are typically used in a `Sprite`.
E.g.: `full = Rectangle("full", SA[0.0, 0.0], SA[1.0, 1.0])`.
"""
struct Rectangle{T<:Real, N}
    center::SVector{N,T}
    radius::SVector{N,T}
    id::AbstractString
    function Rectangle{T,N}(center::SVector{N,T}, radius::SVector{N,T}, id::AbstractString="") where {T<:Real,N}
        any(center .< zero(T) .|| one(T) .< center) && error("Rectangle any(center .< 0.0 || 1.0 .< center): $center")
        any(radius .< zero(T)) && error("Rectangle any(radius .< 0.0): $radius")
        any(center - radius .< zero(T) .|| one(T) .< center + radius) && error("Rectangle any(center - radius .< 0.0 || 1.0 .< center + radius): $center, $radius")
        new{T,N}(center, radius, id)
    end
end
export Rectangle
Rectangle(center::SVector{N,T}, radius::SVector{N,T}, id="") where {T<:Real,N} = Rectangle{T,N}(center, radius, id)
Rectangle(center::AbstractVector{<:Real}, radius::AbstractVector{<:Real}, id="") = Rectangle(SVector(promote(center...)), SVector(promote(radius...)), id)
Rectangle(center::NTuple{N,<:Real}, radius::NTuple{N,<:Real}, id="") where N = Rectangle(SVector(center), SVector(radius), id)

function pad_dimensions(rectangle::Rectangle{T,M}, ::Val{N}) where {T<:Real,M,N}
    N < M && error("N < M")
    Rectangle{T,N}(
        SVector{N,T}(i ≤ M ? rectangle.center[i] : zero(T) for i = 1:N),
        SVector{N,T}(i ≤ M ? rectangle.radius[i] : zero(T) for i = 1:N),
        rectangle.id * " with $(N-M) added dimensions"
    )
end
function trim_dimensions(rectangle::Rectangle{T,N}, ::Val{M}) where {T<:Real,N,M}
    N < M && error("N < M")
    Rectangle{T,M}(
        rectangle.center[SVector(M)],
        rectangle.radius[SVector(M)],
        rectangle.id * " with $(N-M) removed dimensions"
    )
end

Base.:<(r1::Rectangle{T,N}, r2::Rectangle{T,N}) where {T<:Real,N} =
    all(r1.center + r1.radius .< r2.center - r2.radius)
Base.isempty(rectangle::Rectangle) = any(iszero, rectangle.radius)
intersects(r1::Rectangle{T,N}, r2::Rectangle{T,N}) where {T<:Real,N} = !(r1 < r2 || r2 < r1)
Base.union(r1::Rectangle{T,N}, r2::Rectangle{T,N}) where {T<:Real,N} = begin
    lo = min.(r1.center - r1.radius, r2.center - r2.radius)
    hi = max.(r1.center + r1.radius, r2.center + r2.radius)
    Rectangle((lo + hi)/2, (hi - lo)/2, r1.id * " ∪ " * r2.id)
end
Base.in(x::AbstractVector{<:Real}, rectangle::Rectangle) = length(x) == length(rectangle.center) && all(rectangle.center .- rectangle.radius .≤ x .≤ rectangle.center .+ rectangle.radius)

end
