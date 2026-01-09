module CanvasModule

import Main: @install
@install StaticArrays
import StaticArrays: SVector

import Main.LoopOS: OutputPeripheral
import Main.ColorModule: Color, CLEAR
import Main.DrawingModule: Drawing
import Main.RectangleModule: Rectangle, pad
import Main.SpriteModule: Sprite

struct Canvas{N} <: OutputPeripheral
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

function Δ(old::Canvas{N}, new::Canvas{N})::Vector{Tuple{CartesianIndex{N}, Color}} where N
    δ = Tuple{CartesianIndex{N}, Color}[]
    for i = CartesianIndices(new.pixels)
        new_color = new.pixels[i]
        old.pixels[i] == new_color && continue
        push!(δ, (i, new_color))
    end
    δ
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
    for (i,color) = δ canvas.pixels[i] = color end
end
# function put!(canvas::Canvas{N}, sprite::Sprite, stretch::Bool=false)::Vector{CartesianIndex{N}} where N
#     δ = Δ(canvas, sprite, stretch)
#     for i = δ#         canvas.pixels[i[1]] = i[2]
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

import Main.ColorModule: opacity
function collapse(canvas::Canvas{N}, δ::Vector{Tuple{CartesianIndex{N}, Color}}, combine::Function)::Canvas{N} where N
    canvas_size = size(canvas.pixels)
    composite_size = (canvas_size[1:end-1]..., 1)
    pixels = fill(CLEAR, composite_size)
    frontal_indices = unique(i.I[1:N-1] for (i, _) in δ)
    for î in frontal_indices
        for z in canvas_size[end]:-1:1
            canvas_i = CartesianIndex{N}((î..., z))
            canvas_composite = CartesianIndex{N}((î..., 1))
            pixels[canvas_composite] = combine(canvas.pixels[canvas_i], pixels[canvas_composite])
            1.0 ≤ opacity(pixels[canvas_composite]) && break
        end
    end
    Canvas(canvas.id, pixels, canvas.proportional_dimensions)
end

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
    import Main.ColorModule: blend,WHITE,RED,GREEN,BLUE,BLACK
    tests = [
        # 1: single opaque front
        [(CartesianIndex(1,1,1,1), WHITE)] => WHITE,
        # 2: single opaque back
        [(CartesianIndex(1,1,1,3), GREEN)] => GREEN,
        # 3: opaque front occludes back (z=3 is front)
        [(CartesianIndex(1,1,1,1), RED), (CartesianIndex(1,1,1,3), GREEN)] => GREEN,
        # 4: opaque green (back) with 50% red on top
        [(CartesianIndex(1,1,1,1), Color(0,1,0,1)), (CartesianIndex(1,1,1,3), Color(1,0,0,0.5))] => Color(0.5,0.5,0,1),
        # 5: opaque blue (back) with transparent on top
        [(CartesianIndex(1,1,1,1), BLUE), (CartesianIndex(1,1,1,3), CLEAR)] => BLUE,
        # 6: opaque blue (z=1), 50% green (z=2), 50% red (z=3 front)
        [(CartesianIndex(1,1,1,1), Color(0,0,1,1)), (CartesianIndex(1,1,1,2), Color(0,1,0,0.5)), (CartesianIndex(1,1,1,3), Color(1,0,0,0.5))] => Color(0.5,0.25,0.25,1),
        # 7: all clear
        [(CartesianIndex(1,1,1,1), CLEAR)] => CLEAR,
        # 8: opaque black (back) with 25% white on top
        [(CartesianIndex(1,1,1,1), BLACK), (CartesianIndex(1,1,1,3), Color(1,1,1,0.25))] => Color(0.25,0.25,0.25,1),
        # 9: 50% blue (z=1 back), 50% red (z=2 front), no opaque back
        [(CartesianIndex(1,1,1,1), Color(0,0,1,0.5)), (CartesianIndex(1,1,1,2), Color(1,0,0,0.5))] => Color(0.5,0,0.25,0.75),
        # 10: opaque white (back) with opaque black on top
        [(CartesianIndex(1,1,1,1), WHITE), (CartesianIndex(1,1,1,3), BLACK)] => BLACK,
    ]

    for (i, test) in enumerate(tests)
        δ = test[1]
        expected = test[2]
        
        fill!(canvas.pixels, CLEAR)
        for (ix, color) in δ canvas.pixels[ix] = color end
        
        collapsed_canvas = collapse(canvas, δ, blend)
        @test collapsed_canvas.pixels[Tuple(δ[1][1])[1:3]..., 1] ≈ expected
    end
# Δ(old::Canvas{N}, new::Canvas{N})::Vector{Tuple{CartesianIndex{N}, Color}} where N
# function Δ(canvas::Canvas{N}, sprite::Sprite)::Vector{Tuple{CartesianIndex{N}, Color}} where N
    # tests = [
    #     (Sprite("",Drawing{1}("",_->RED),Rectangle{1}("",[0],[0]))) => [(CartesianIndex(1,1,1,1),RED)]
    # ]
    # for (i, test) in enumerate(tests)
    #     test=tests[1]
    #     fill!(canvas.pixels, CLEAR)
    #     sprite = test[1]
    #     δ = test[2]
    #     δ̂ = Δ(canvas, sprite)
    #     for 
            
    #     end
    #     @test  ≈ δ
    # end
end

end
