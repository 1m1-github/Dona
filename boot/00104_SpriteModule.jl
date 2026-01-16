module SpriteModule

import Main.DrawingModule: Drawing
import Main.RectangleModule: Rectangle

"""
Imagine everything inside an N dimensional unit square, 0.0=bottom-left.
Define the function mapping from coordinates to a Color (`Drawing`) and a `Rectangle`.
The `Sprite` lives in the perfectly precise digital world, yet can simply be `put!` onto a `Canvas` for actual display.
E.g.: `put!(BroadcastBrowserCanvas, sky_sprite)` or `put!(BroadcastBrowserCanvas, sky_sprite)`
"""
struct Sprite{T<:Real,N,M}
    drawing::Drawing{N}
    rectangle::Rectangle{T,M}
    id::AbstractString
    Sprite{T,N,M}(drawing::Drawing{N}, rectangle::Rectangle{T,M}, id::AbstractString="") where {T<:Real,N,M} = new{T,N,M}(drawing, rectangle, id)
end
export Sprite
Sprite(drawing::Drawing{N}, rectangle::Rectangle{T,M}, id="") where {T<:Real,N,M} = Sprite{T,N,M}(drawing, rectangle, id)
(s::Sprite)(x) = s.drawing(x)
Base.:(==)(s1::Sprite{T,N,M}, s2::Sprite{T,N,M}) where {T<:Real,N,M} = s1.drawing == s2.drawing && s1.rectangle == s2.rectangle
import Main.ColorModule: CLEAR
clear(sprite::Sprite{T,N,M}) where {T<:Real,N,M} = Sprite{T,N,M}(Drawing{N}(_ -> CLEAR), sprite.rectangle)
# function Base.:∪(s1::Sprite{T,N,M}, s2::Sprite{T,N,M}, x) where {T<:Real,N,M}
#     in_s1 = x ∈ s1.rectangle
#     in_s2 = x ∈ s2.rectangle
#     return if in_s1 && in_s2
#         s1(x) ∘ s2(x)
#     elseif in_s1
#         s1(x)
#     elseif in_s2
#         s2(x)
#     else
#         CLEAR
#     end
# end
# function Base.:∪(s1::Sprite{T,N,M}, s2::Sprite{T,N,M}) where {T<:Real,N,M}
#     drawing = Drawing{N}(x -> ∪(s1, s2, x))
#     Sprite{T,N,M}(drawing, s1.rectangle ∪ s2.rectangle, s1.id * " ∪ " * s2.id)
# end

import Main.RectangleModule: scale, move
scale(sprite::Sprite, rectangle::Rectangle) = (x -> x + rectangle.center - rectangle.radius) ∘ sprite.drawing
function move(sprite::Sprite, rectangle::Rectangle)
    _rectangle = move(sprite.rectangle, rectangle)
    drawing = scale(sprite, _rectangle)
    Sprite(drawing, _rectangle)
end

end

