module SpeakingModule

import StaticArrays: SA

import Main.ColorModule: Color, CLEAR, WHITE, BLACK
import Main.DrawingModule: Drawing
import Main.SpriteModule: Sprite
import Main.TypstModule: typst_sprite
import Main: LoopOS

struct Speaker <: LoopOS.OutputPeripheral end
export Speaker

import Base.put!
function put!(::Type{Speaker},speech::String,subtitles_size::Float64=0.5)
    center = SA[0.5, 0.1]
    sprite = typst_sprite(speech, center, subtitles_size)
    put!(Sprite(opacue ∘ black ∘ invert ∘ sprite.drawing, sprite.rectangle), 1.0)
end

opacue(color) = Color(color, 1)
black(x) = x == WHITE ? BLACK : x
invert(color) = WHITE - color

end
