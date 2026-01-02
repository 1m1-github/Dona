module CanvasHelpersModule

export circle, rect

import Colors: Colorant

import Main.CanvasModule: Position, Pixels, Sprite, CANVAS

circle(center::Position, radius::Real, color::Colorant)::Sprite = Sprite(center, circle_pixels(center, radius, color))
rect(pos::Position, width::Real, height::Real, color::Colorant)::Sprite = Sprite(pos, rect_pixels(width, height, color))

"0.0 ≤ radius ≤ 1.0"
function circle_pixels(center::Position, radius::Real, colorant::Colorant)::Pixels
    width, height = CANVAS[].width, CANVAS[].height
    d = rel2abs(2 * radius, max(width, height))
    d < 1 && return fill(color(colorant), 1, 1)
    pixels = fill(CLEAR, d, d)
    for y in 1:d, x in 1:d
        (x - center)^2 + (y - center)^2 <= radius^2 && ( pixels[y, x] = color(colorant) )
    end
    x = center[1] - radius * max(width, height) / width
    y = center[2] - radius * max(width, height) / height
end

"0.0 ≤ width,height ≤ 1.0"
function rect_pixels(width::Real, height::Real, c::Colorant)::Pixels
    w = rel2abs(width, CANVAS[].width)
    h = rel2abs(height, CANVAS[].height)
    fill(color(c), max(1, h), max(1, w))
end

end
