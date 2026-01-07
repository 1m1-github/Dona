module DrawingModule

import StaticArrays: SVector

import Main.ColorModule: Color, average, CLEAR

"""
Draw inside a unit hypercube, 0.0=bottom-left, 1.0=top-right.
`Drawing`s are typically used in a `Sprite`.
E.g.:
sky = Drawing("sky", coordinates -> Color(0.0, 0.0, 1.0, 1.0))
upper_half = Region("upper half", [0.5, 0.75], [0.5, 0.25])
sky_sprite = Sprite("sky in upper half", sky, upper_half)
put!(BroadcastBrowserCanvas, sky_sprite)
"""
struct Drawing{N}
    id::String
    f::Function # N-dim unit hypercube vector -> Color
end
export Drawing
(d::Drawing)(x::SVector) = d.f(x)
(d::Drawing)(x::Vector) = d.f(SVector{length(x)}(x))
(d::Drawing)(x::NTuple) = d.f(SVector(x...))
import Base.∘
"weighted by alpha average"
∘(a::Drawing, b::Drawing) = Drawing(a.id * b.id, x -> average(a(x), b(x)))
export ∘

export circle
"""`circle_drawing::Drawing = circle("sun", [0.5, 0.5], 0.5, Color.YELLOW)`"""
circle(id, c, r, color) = Drawing{length(c)}(id, x -> hypot((x .- c)...) < r ? color : CLEAR)

# cloud = circle("cloud", (0.5, 0.8), 0.1, WHITE)
# sun = circle("sun", (0.5, 0.5), 0.5, YELLOW)
# scene = sun ∘ cloud ∘ sky  # sun on top of cloud on top of sky
# drawing = sun
# region = Region("tr", (0.6, 0.5), (0.2, 0.2))
# sprite = Sprite("s1", drawing, region)
# canvas = Canvas(fill(CLEAR, (10,20,10,2))) # x, y, z, t
# Δ_index = put!(canvas, sprite)
# composite_dimension = 3
# new_composite_canvas = composite(canvas, Δ_index, composite_dimension)
# new_composite_canvas = Canvas(new_composite_canvas.pixels[:,:,end,end])
# composite_canvas = Canvas(fill(CLEAR, (size(canvas.pixels, 1), size(canvas.pixels, 2))))
# composite_Δ_index = [CartesianIndex((i[1], i[2])) for i in Δ_index]
# GraphicsModule.put!(composite_canvas, new_composite_canvas, composite_Δ_index)
# size(composite_canvas.pixels)
# size(new_composite_canvas.pixels)
# using Plots
# plot(composite_canvas.pixels[:,:,end,end])
# plot(canvas.pixels[:,:,end,end])

# export Color, Sprite, put!, move!, delete!, clear!, CANVAS_ADVICE, CANVAS
# export @colorant_str

# const CANVAS_ADVICE = """
# This module allows you to do graphical presentation.
# Create a Sprite and then `put!` it to the `CANVAS[]` or `Canvas()`. You can also `move!` a Sprite or `delete!` it.
# The Canvas goes from top-left (0.0,0.0) to bottom-right (1.0,1.0).
# `@colorant_str` is exported so you can use `colorant"red"` for example if you want to.
# Use this Canvas as your main visual communications peripheral.
# """

end
using .DrawingModule
