module RectangleModule

import StaticArrays: SVector

"""
An N dimensional rectangle inside an N dimensional unit square with 0=bottom-left=low, 1=top-right=high.
`Rectangle`s are typically used in a `Sprite`.
E.g.: `full = Rectangle(SA[0.5], SA[0.5], "full 1d")`.
"""
struct Rectangle{T<:Real, N}
    center::SVector{N,T}
    radius::SVector{N,T}
    id::String
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

Base.:(==)(r1::Rectangle{T,N}, r2::Rectangle{T,N}) where {T<:Real,N} = r1.center == r2.center && r1.radius == r2.radius
Base.:(≈)(r1::Rectangle{T,N}, r2::Rectangle{T,N}) where {T<:Real,N} = r1.center ≈ r2.center && r1.radius ≈ r2.radius
function pad_dimensions(r::Rectangle{T,M}, ::Val{N}) where {T<:Real,M,N}
    N < M && error("N < M")
    Rectangle{T,N}(
        SVector{N,T}(i ≤ M ? r.center[i] : zero(T) for i = 1:N),
        SVector{N,T}(i ≤ M ? r.radius[i] : zero(T) for i = 1:N),
        r.id * " with $(N-M) padded dimensions"
    )
end
function remove_dimensions(r::Rectangle{T,N}, ::Val{M}) where {T<:Real,N,M}
    N < M && error("N < M")
    Rectangle{T,M}(
        SVector{M,T}(r.center[i] for i = 1:M),
        SVector{M,T}(r.radius[i] for i = 1:M),
        r.id * " with $(N-M) removed dimensions"
    )
end

∅(T,N) = Rectangle(zero(SVector{N,T}),zero(SVector{N,T}),"EMPTY")
Base.:<(r1::Rectangle{T,N}, r2::Rectangle{T,N}) where {T<:Real,N} = all(r1.center .+ r1.radius .< r2.center .- r2.radius)
Base.isempty(r::Rectangle) = all(iszero, r.radius)
id(rs::AbstractVector{<:Rectangle}, separator="")= join((r.id for r in rs), separator)
corner(r::Rectangle) = (r.center - r.radius, r.center + r.radius)
function Base.union(rs::AbstractVector{<:Rectangle})
    corners = corner.(rs)
    low = reduce((a,b) -> min.(a,b), first.(corners))
    high = reduce((a,b) -> max.(a,b), last.(corners))
    center = (high + low) / 2
    radius = (high - low) / 2
    Rectangle(center, radius, id(rs, " ∪ "))
end
Base.union(r1::Rectangle, r2::Rectangle) = ∪([r1, r2])
function Base.intersect(rs::AbstractVector{Rectangle{T,N}}) where {T<:Real,N}
    corners = corner.(rs)
    low = reduce((a,b) -> max.(a,b), first.(corners))
    high = reduce((a,b) -> min.(a,b), last.(corners))
    any(low .> high) && return ∅(T,N)
    center = (high + low) / 2
    radius = (high - low) / 2
    Rectangle(center, radius, id(rs, " ∩ "))
end
Base.intersect(r1::Rectangle, r2::Rectangle) = ∩([r1, r2])
Base.:≤(r1::Rectangle{T,N}, r2::Rectangle{T,N}) where {T<:Real,N} = r1 < r2 || !isempty(r1 ∩ r2)
Base.in(x::SVector{N,T}, r::Rectangle{T,N}) where {T,N} = all(r.center .- r.radius .≤ x .≤ r.center .+ r.radius)

end
