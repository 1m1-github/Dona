module SpriteModule

import Main.DrawingModule: Drawing
import Main.RectangleModule: Rectangle

"""
Imagine everything inside an N dimensional unit square, 0.0=bottom-left.
Define the function mapping from coordinates to a Color (`Drawing`) and a `Rectangle`.
The `Sprite` lives in the perfectly precise digital world, yet can simply be `put!` onto a `Canvas` for actual display.
E.g.: `put!(BroadcastBrowserCanvas, sky_sprite)` or `put!(BroadcastBrowserCanvas, sky_sprite)`
"""
struct Sprite{N,M}
    drawing::Drawing{N}
    rectangle::Rectangle{M}
end
(s::Sprite)(x) = s.drawing(x)
export Sprite

end
