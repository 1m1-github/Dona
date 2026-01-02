module CanvasHelpersModule

export circle, rect

import Colors: Colorant

import Main.CanvasModule: Position, Pixels, Sprite

circle(pos::Position, radius::Real, c::Colorant) = Sprite(pos, circle_pixels(radius, c))
rect(pos::Position, w::Real, h::Real, c::Colorant) = Sprite(pos, rect_pixels(w, h, c))

"0.0 ≤ radius ≤ 1.0"
function circle_pixels(center_pos::Position, radius::Real, c::Colorant)::Pixels
    d = rel2abs(2 * radius, max(CANVAS[].width, CANVAS[].height))
    d < 1 && return fill(color(c), 1, 1)
    pixels = fill(CLEAR, d, d)
    center = d / 2
    r² = center^2
    for y in 1:d, x in 1:d
        (x - center)^2 + (y - center)^2 <= r² && (pixels[y, x] = color(c))
    end
    canvas = CANVAS[]
    x = center_pos[1] - radius * max(canvas.width, canvas.height) / canvas.width
    y = center_pos[2] - radius * max(canvas.width, canvas.height) / canvas.height
end

"0.0 ≤ width,height ≤ 1.0"
function rect_pixels(width::Real, height::Real, c::Colorant)::Pixels
    w = rel2abs(width, CANVAS[].width)
    h = rel2abs(height, CANVAS[].height)
    fill(color(c), max(1, h), max(1, w))
end

end
