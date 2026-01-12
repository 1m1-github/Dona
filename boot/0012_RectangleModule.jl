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
    id::String
end
Rectangle(center::SVector{N,Float64}, radius::SVector{N,Float64} ,id::String="") where N = Rectangle{N}(center, radius, id)
Rectangle(center::AbstractVector, radius::AbstractVector, id::String="") = Rectangle{length(center)}(SVector{length(center)}(center), SVector{length(radius)}(radius), id)
Rectangle(center::NTuple{N,Float64}, radius::NTuple{N,Float64}, id::String="") where N = Rectangle{N}(SVector{N}(center...), SVector{N}(radius...), id)

function pad(rectangle::Rectangle{M}, N)::Rectangle{N} where M
    center = SVector{N}(i ≤ M ? rectangle.center[i] : 0.0 for i = 1:N)
    radius = SVector{N}(i ≤ M ? rectangle.radius[i] : 0.0 for i = 1:N)
    Rectangle{N}(center, radius, rectangle.id)
end

end
