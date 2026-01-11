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
# function put!(::Type{Speaker},speech::String,subtitles_size::Float64=0.5)
function put!(::Type{Speaker},speech::String)
    center = SA[0.5, 0.1]
    sprite = typst_sprite(speech, center, center[1])
    # sprite.rectangle[1] == subtitles_size == 0.5
    # sprite.rectangle[2] == 0.76
    # subtitles_size*center[2]/sprite.rectangle[2] = center[1]
    # 0.5*0.1/0.76
    # 0.5/0.76
    # 0.4/0.76
    # subtitles_size/sprite.rectangle[2]
    @show sprite.rectangle
    
    width = center[1]*center[1]/sprite.rectangle.radius[2]
    @show width
    height = center[2]*center[1]/sprite.rectangle.radius[2]
    @show height
    # subtitles_size*center[2]/sprite.rectangle[2]
    rectangle = Rectangle(center, SA[width, height])
    put!(Sprite(opacue ∘ black ∘ invert ∘ sprite.drawing, rectangle), 1.0)
end

opacue(color) = Color(color, 1)
black(color) = color == WHITE ? BLACK : color
invert(color) = WHITE - color

end
