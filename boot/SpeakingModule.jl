module SpeakingModule

import StaticArrays: SA

import Main.ColorModule: Color, CLEAR, WHITE, BLACK
import Main.DrawingModule: Drawing, invert, opaque
import Main.SpriteModule: Sprite
import Main.TypstModule: typst_sprite
import Main: LoopOS

struct Speaker <: LoopOS.OutputPeripheral end
export Speaker

import Base.put!
function put!(::Type{Speaker},speech::String)
    center = SA[0.5, 0.05]
    sprite = typst_sprite(speech, center, 1.0)
    @show sprite.rectangle
    width = center[2]*sprite.rectangle.radius[1]/sprite.rectangle.radius[2]
    height = center[2]
    @show width,height
    rectangle = Rectangle(center, SA[width, height])
    put!(Sprite(opaque ∘ black ∘ invert ∘ sprite.drawing, rectangle), 1.0)
end
black(color) = color == WHITE ? BLACK : color

end
