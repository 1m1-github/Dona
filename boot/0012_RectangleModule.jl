module RectangleModule

export Rectangle

import Main: @install
@install StaticArrays
import StaticArrays: SVector

"""
An N dimensional rectangle inside an N dimensional unit square with 0=bottom-left.
`Rectangle`s are typically used in a `Sprite`.
E.g.: `full = Rectangle("full", [0.0, 0.0], [1.0, 1.0])`.
"""
struct Rectangle{N}
    id::String
    center::SVector{N,Float64}
    radius::SVector{N,Float64}
end
Rectangle(id::String, center::Vector, radius::Vector) = Rectangle(id, SVector{length(center)}(center), SVector{length(radius)}(radius))
Rectangle(id::String, center::NTuple{N,Float64}, radius::NTuple{N,Float64}) where N = Rectangle(id, SVector{N}(center...), SVector{N}(radius...))

function pad(rectangle::Rectangle{M}, N)::Rectangle{N} where M
    center = SVector{N}(i ≤ M ? rectangle.center[i] : 0.0 for i = 1:N)
    radius = SVector{N}(i ≤ M ? rectangle.radius[i] : 0.0 for i = 1:N)
    Rectangle(rectangle.id, center, radius)
end

end
