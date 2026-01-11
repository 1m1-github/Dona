module RectangleModule

export Rectangle

import StaticArrays: SVector

"""
An N dimensional rectangle inside an N dimensional unit square with 0=bottom-left.
`Rectangle`s are typically used in a `Sprite`.
E.g.: `full = Rectangle("full", [0.0, 0.0], [1.0, 1.0])`.
"""
struct Rectangle{N}
    center::SVector{N,Float64}
    radius::SVector{N,Float64}
end
Rectangle(center::AbstractVector, radius::AbstractVector) = Rectangle(SVector{length(center)}(center), SVector{length(radius)}(radius))
Rectangle(center::NTuple{N,Float64}, radius::NTuple{N,Float64}) where N = Rectangle(SVector{N}(center...), SVector{N}(radius...))

function pad(rectangle::Rectangle{M}, N)::Rectangle{N} where M
    center = SVector{N}(i ≤ M ? rectangle.center[i] : 0.0 for i = 1:N)
    radius = SVector{N}(i ≤ M ? rectangle.radius[i] : 0.0 for i = 1:N)
    Rectangle(center, radius)
end

end
