module GraphicsModule

export Sprite, Rectangle

import Main: @install
@install StaticArrays
import StaticArrays: SVector
import Main.DrawingModule: Drawing
import Main.ColorModule: Color, CLEAR

import Main.StateModule: state
import Main: LoopOS

"""
An N dimensional rectangle inside an N dimensional unit square with 0=bottom-left.
`Rectangle`s are typically used in a `Sprite`.
E.g.: `full = Rectangle("full", [0.0, 0.0], [1.0, 1.0])`.
"""
struct Rectangle{N}
    id::String
    center::SVector{N,Float64}
    radius::SVector{N,Float64}
end
Rectangle(id::String, center::Vector, radius::Vector) = Rectangle(id, SVector{length(center)}(center), SVector{length(radius)}(radius))
Rectangle(id::String, center::NTuple{N,Float64}, radius::NTuple{N,Float64}) where N = Rectangle(id, SVector{N}(center...), SVector{N}(radius...))

function pad(rectangle::Rectangle{M}, N)::Rectangle{N} where M
    center = SVector{N}(i ≤ M ? rectangle.center[i] : 1.0 for i = 1:N)
    radius = SVector{N}(i ≤ M ? rectangle.radius[i] : 0.0 for i = 1:N)
    Rectangle(rectangle.id, center, radius)
end

"""
Imagine everything inside an N dimensional unit square, 0.0=bottom-left, 1.0=top-right.
Define the function mapping from coordinates to a Color (`Drawing`) and a `Rectangle`.
The Sprite lives in the perfectly precise digital world, yet can simply be `put!` onto a `Canvas` for actual display.
E.g.: `put!(BroadcastBrowserCanvas, sky_sprite)`
"""
struct Sprite{N,M}
    id::String
    drawing::Drawing{N}
    rectangle::Rectangle{M}
end

struct Canvas{N} <: LoopOS.OutputPeripheral
    id::String
    pixels::Array{Color,N}
    proportional_dimensions::Set{Int}
end

function index(canvas::Canvas{N}, rectangle::Rectangle{N})::CartesianIndices{N} where N
    bottom_left = rectangle.center .- rectangle.radius
    pixel_size = size(canvas.pixels) .- 1
    proportional_dimensions_scale = minimum(pixel_size[i] for i in canvas.proportional_dimensions)
    scales = ntuple(N) do i
        if i in canvas.proportional_dimensions
            proportional_dimensions_scale
        else
            pixel_size[i]
        end
    end
    start_index = floor.(Int, bottom_left .* scales .+ 0.5) .+ 1
    end_index = ceil.(Int, (bottom_left .+ 2*rectangle.radius) .* scales .+ 0.5)
    CartesianIndices(Tuple(UnitRange.(start_index, end_index)))
end
index(canvas::Canvas{N}, rectangle::Rectangle) where N = index(canvas, pad(rectangle, N))

function Δ(old::Canvas{N}, new::Canvas{N})::Canvas{N} where N
    pixels = fill(CLEAR, size(new.pixels))
    for i = eachindex(new.pixels)
        old.pixels[i] == new.pixels[i] && continue
        pixels[i] = new.pixels[i]
    end
    Canvas(new.id, pixels, new.proportional_dimensions)
end
function Δ(canvas::Canvas{N}, sprite::Sprite)::Vector{Tuple{CartesianIndex{N}, Color}} where N
    hyperrectangle_index = index(canvas, sprite.rectangle)
    start_index = SVector{N}([hyperrectangle_index[1][i] for i = 1:N])
    end_index = SVector{N}([hyperrectangle_index[end][i] for i = 1:N])
    index_length = end_index .- start_index .+ 1
    coordinate_dimension = (!isone).(index_length)
    δ = Tuple{CartesianIndex{N}, Color}[]
    for i = hyperrectangle_index
        coordinates = (SVector(i.I) .- start_index .+ 0.5) ./ index_length
        new_color = sprite.drawing(coordinates[coordinate_dimension])
        old_color = canvas.pixels[i]
        old_color == new_color && continue
        push!(δ, (i, new_color))
    end
    δ
end

import Base: put!
function put!(canvas::Canvas{N}, δ::Vector{Tuple{CartesianIndex{N}, Color}}) where N
    for i = δ canvas.pixels[i[1]] = i[2] end
end
# function put!(canvas::Canvas{N}, sprite::Sprite, stretch::Bool=false)::Vector{CartesianIndex{N}} where N
#     δ = Δ(canvas, sprite, stretch)
#     for i = δ
#         canvas.pixels[i[1]] = i[2]
#     end
# end
# function put!(new::Canvas{N}, old::Canvas{N}, Δ_index::Vector{CartesianIndex{N}}) where N
#     for i = Δ_index
#         old_color = old.pixels[i]
#         new_color = new.pixels[i]
#         old_color == new_color && continue
#         new.pixels[i] = new_color
#     end
# end

import Main.ColorModule: blend, opacity
# function composite_z!(result::Array{Color,N}, pixels::Array{Color,N}, δ::Vector{Tuple{CartesianIndex{N}, Color}}) where N
function collapse(canvas::Canvas{N},δ::Vector{Tuple{CartesianIndex{N}, Color}}, combine::Function)::Canvas{N} where N
    # δ=[(CartesianIndex(1,1,1,1), Color(1,0,0,1))]
    # canvas,δ=δ2,blend
    # combine=blend
    # N=4
    # CartesianIndex(1,1,1,1)[3]
    frontal_indices = [CartesianIndex(ntuple(i -> i < N ? d[1][i] : 1, N-1)) for d in δ]
    # d=δ[1]
    # ntuple(i -> i < N ? d[1][i] : 1, N-1)
    pixels = fill(CLEAR, size(frontal_indices)) # todo faster?
    for i in frontal_indices
        top = CLEAR
        î = Tuple(i)
        for z in axes(canvas.pixels, N)
            top = combine(canvas.pixels[î..., z], top)
            1.0 ≤ opacity(top) && break
        end
        pixels[î..., 1] = top
    end
    Canvas(canvas.id, pixels, canvas.proportional_dimensions)
end

# function collapse(canvas::Canvas{N}, δ::Vector{Tuple{CartesianIndex{N}, Color}}, combine::Function)::Canvas{N} where N
#     canvas_size = size(canvas.pixels)
#     composite_size = (canvas_size[1:end-1]..., 1)
#     pixels = fill(CLEAR, composite_size)
#     for i = δ
#         for composite_index = canvas_size[end]:-1:1
#             î = i[1].I[1:N-1]
#             canvas_i = CartesianIndex{N}((î..., composite_index))
#             canvas_composite = CartesianIndex{N}((î..., 1))
#             pixels[canvas_composite] = combine(pixels[canvas_composite], canvas.pixels[canvas_i])
#             1.0 ≤ pixels[canvas_composite].alpha && break
#         end
#     end
#     Canvas(canvas.id, pixels, canvas.proportional_dimensions)
# end

using Test
begin
canvas = Canvas("",fill(CLEAR,200,100,2,3),Set([1,2]))
tests = [
    Rectangle("",[0.5,0.5],[0.5,0.5]) => CartesianIndices((1:100, 1:100, 2:2, 3:3)),
    Rectangle("",[0.05,0.5],[0.05,0.5]) => CartesianIndices((1:11, 1:100, 2:2, 3:3)),
    Rectangle("",[0.05,0.25],[0.05,0.25]) => CartesianIndices((1:11, 1:50, 2:2, 3:3)),
    Rectangle("",[0.5,0.1],[0.5,0.1]) => CartesianIndices((1:100, 1:21, 2:2, 3:3)),
    Rectangle("",[0.0,0.0],[0.0,0.0]) => CartesianIndices((1:1, 1:1, 2:2, 3:3)),
    Rectangle("",[1.0,1.0],[0.0,0.0]) => CartesianIndices((100:100, 100:100, 2:2, 3:3)), # i thought: CartesianIndices((200:200, 100:100, 2:2, 3:3))
    Rectangle("",[0.5,0.5,1.0,0.0],[0.5,0.5,0.0,0.0]) => CartesianIndices((1:100, 1:100, 2:2, 1:1)),
    Rectangle("",[0.5,0.5,1.0,0.5],[0.5,0.5,0.0,0.0]) => CartesianIndices((1:100, 1:100, 2:2, 2:2)),
    Rectangle("",[0.2,0.25,0.25,1.0],[0.1,0.05,0.5,0.0]) => CartesianIndices((11:31, 21:31, 1:2, 3:3)), # i thought: CartesianIndices((20:40, 20:30, 1:2, 3:3))
    Rectangle("",[0.55,0.55,0.55,0.55],[0.05,0.05,0.05,0.05]) => CartesianIndices((51:60, 51:60, 2:2, 2:2)), # i thought: CartesianIndices((100:110, 50:60, 1:1, 2:2))
]
tests = map(p -> pad(p[1], 4) => p[2], tests)
for test in tests
    rectangle, i = test
    @test index(canvas, rectangle) == i
end
# h, w, d, z_depth=2,2,2,3
# pixel_data, δ_indices=[((1,1,1,1), Color(1,0,0,1))], [((1,1,1,1), Color(1,0,0,1))]
for i in eachindex(canvas.pixels) canvas.pixels[i] = CLEAR end
# function test_composite(x, y, t, z, pixel_data, δ)
#     canvas = Canvas("",fill(Color(0,0,0,0), x, y, t, z), Set([1,2]))
#     for (i, color) in pixel_data
#         canvas.pixels[i...] = color
#     end
#     # result = fill(Color(0,0,0,0), h, w, d, 1)
#     # δ = [(CartesianIndex(i), color) for (i, color) in δ_indices]
#     # composite_z!(result, pixels, δ)
#     result = collapse(canvas,δ,blend)
#     result.pixels[Tuple(δ[1][1])[1:3]..., 1]
# end
for (i, test) in enumerate(tests)
    @test collapse(canvas,[test[1][1]],blend).pixels[test[1][1][1:end-1]...,1] ≈ test[2]
end
tests = [
    # (pixel_data, δ_indices) => expected
    
    # 1: single opaque front
    (CartesianIndex(1,1,1,1), ColorModule.WHITE) => Color(1,0,0,1),
    # (2,2,2,3, [((1,1,1,1), Color(1,0,0,1))], [((1,1,1,1), Color(1,0,0,1))]) => Color(1,0,0,1),
    
    # # 2: single opaque back
    # (2,2,2,3, [((1,1,1,3), Color(0,1,0,1))], [((1,1,1,3), Color(0,1,0,1))]) => Color(0,1,0,1),
    
    # # 3: front occludes back
    # (2,2,2,3, [((1,1,1,1), Color(1,0,0,1)), ((1,1,1,3), Color(0,1,0,1))], [((1,1,1,1), Color(1,0,0,1))]) => Color(1,0,0,1),
    
    # # 4: 50% red over opaque green
    # (2,2,2,2, [((1,1,1,1), Color(1,0,0,0.5)), ((1,1,1,2), Color(0,1,0,1))], [((1,1,1,1), Color(1,0,0,0.5))]) => Color(0.5,0.5,0,1),
    
    # # 5: transparent over opaque
    # (2,2,2,2, [((1,1,1,1), Color(1,0,0,0)), ((1,1,1,2), Color(0,1,0,1))], [((1,1,1,1), Color(1,0,0,0))]) => Color(0,1,0,1),
    
    # # 6: 50% red over 50% green over opaque blue
    # (2,2,2,3, [((1,1,1,1), Color(1,0,0,0.5)), ((1,1,1,2), Color(0,1,0,0.5)), ((1,1,1,3), Color(0,0,1,1))], [((1,1,1,1), Color(1,0,0,0.5))]) => Color(0.5,0.25,0.25,1),
    
    # # 7: all clear
    # (2,2,2,3, [((1,1,1,1), Color(0,0,0,0))], [((1,1,1,1), Color(0,0,0,0))]) => Color(0,0,0,0),
    
    # # 8: 25% alpha
    # (2,2,2,2, [((1,1,1,1), Color(1,1,1,0.25)), ((1,1,1,2), Color(0,0,0,1))], [((1,1,1,1), Color(1,1,1,0.25))]) => Color(0.25,0.25,0.25,1),
    
    # # 9: two 50% layers, no back
    # (2,2,2,2, [((1,1,1,1), Color(1,0,0,0.5)), ((1,1,1,2), Color(0,0,1,0.5))], [((1,1,1,1), Color(1,0,0,0.5))]) => Color(0.5,0,0.25,0.75),
    
    # # 10: opaque black over opaque white
    # (2,2,2,2, [((1,1,1,1), Color(0,0,0,1)), ((1,1,1,2), Color(1,1,1,1))], [((1,1,1,1), Color(0,0,0,1))]) => Color(0,0,0,1),
]
end

end # todo use views?
