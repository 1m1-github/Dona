module SpeakingModule

import StaticArrays: SA

import Main.ColorModule: CLEAR, WHITE, BLACK, invert, opaque
import Main.DrawingModule: Drawing, ∘
import Main.RectangleModule: Rectangle
import Main.SpriteModule: Sprite
import Main.TypstModule: typst_sprite
import Main.CanvasModule: remove!
import Main.LoopOS: OutputPeripheral

function Sprite(speech::AbstractString)
    sentences = split(strip(speech), r"[.!?;]")
    sentences = filter(!isempty, sentences)
    s = Sprite(Drawing(_->CLEAR), Rectangle(SA[0.0,0.0],SA[0.0,0.0]), speech)
    radius = SA[0.5, 0.05]
    for (i, sentence) = enumerate(sentences)
        center = [radius[1], (2i-1)*radius[2]]
        s = s ∪ Sprite(strip(sentence), center, radius)
    end
    s
end
function Sprite(speech::AbstractString, center, radius)
    _sprite = typst_sprite(speech)
    typst_ratio = _sprite.rectangle.radius[1] / _sprite.rectangle.radius[2]
    radius_height = radius[2]
    radius_width = radius_height * typst_ratio
    if radius[1] < radius_width
        radius_width=radius[1]
        radius_height=radius_width / typst_ratio
    end
    rectangle = Rectangle(center, SA[radius_width, radius_height], speech)
    @show _sprite.rectangle, radius_width, radius_height, rectangle
    Sprite(opaque ∘ black ∘ invert ∘ _sprite.drawing, rectangle, speech)
end
black(color) = color == WHITE ? BLACK : color

mutable struct Speaker <: OutputPeripheral
    sprite::Sprite{Float64, 2,2}
end
export Speaker
const SPEAKER = Speaker(Sprite(""))

Base.put!(::Type{Speaker},speech) = begin
    remove!(SPEAKER.sprite)
    SPEAKER.sprite = Sprite(speech)
    put!(SPEAKER.sprite, 1.0)
end

end
