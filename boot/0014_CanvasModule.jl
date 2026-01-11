module CanvasModule

import StaticArrays: SVector

import Main.LoopOS: OutputPeripheral
import Main.ColorModule: Color, CLEAR
import Main.DrawingModule: Drawing
import Main.RectangleModule: Rectangle, pad
import Main.SpriteModule: Sprite

struct Canvas{N} <: OutputPeripheral
    pixels::AbstractArray{Color,N}
    proportional_dimensions::Set{Int}
end
import Base.size
size(c::Canvas) = size(c.pixels)

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

import Base.put!
function put!(canvas::Canvas{N}, sprite::Sprite{M,K})::Vector{Tuple{CartesianIndex{N}, Color}} where {N,M,K}
    δ = Tuple{CartesianIndex{N}, Color}[]
    hyperrectangle_index::CartesianIndices{N} = index(canvas, sprite.rectangle)
    isempty(hyperrectangle_index) && return δ
    start_index = SVector{N}([hyperrectangle_index[1][i] for i = 1:N])
    end_index = SVector{N}([hyperrectangle_index[end][i] for i = 1:N])
    index_length = end_index .- start_index .+ 1
    for i = hyperrectangle_index
        coordinates = (SVector(i.I) .- start_index .+ 0.5) ./ index_length
        new_color = sprite.drawing(coordinates[1:M]) # first M dim
        old_color = canvas.pixels[i]
        old_color == new_color && continue
        canvas.pixels[i] = new_color
        push!(δ, (i, new_color))
    end
    δ
end
function Δ(old::Canvas{N}, new::Canvas{N})::Vector{Tuple{CartesianIndex{N}, Color}} where N
    δ = Tuple{CartesianIndex{N}, Color}[]
    for i = CartesianIndices(new.pixels)
        new_color = new.pixels[i]
        old.pixels[i] == new_color && continue
        push!(δ, (i, new_color))
    end
    δ
end

import Main.ColorModule: opacity
function collapse!(collapsed::Canvas{N}, canvas::Canvas{N}, δ::Vector{Tuple{CartesianIndex{N}, Color}}, combine::Function, collapse_dimension::Int64=N)::Vector{Tuple{CartesianIndex{N}, Color}} where N
    collapse_dimension_size = size(canvas.pixels, collapse_dimension)
    δ̂ = Tuple{CartesianIndex{N}, Color}[]
    non_collapse_dimensions = setdiff(1:N, collapse_dimension)
    non_collapse_index = unique(i.I[non_collapse_dimensions] for (i, _) in δ)
    for i = non_collapse_index
        pixel = CLEAR
        for collapse_index = collapse_dimension_size:-1:1
            canvas_i = CartesianIndex{N}(ntuple(j -> j < collapse_dimension ? i[j] : (j == collapse_dimension ? collapse_index : i[j-1]), N))
            pixel = combine(canvas.pixels[canvas_i], pixel)
            1.0 ≤ opacity(pixel) && break
        end
        î = CartesianIndex{N}((i..., 1))
        collapsed.pixels[î] == pixel && continue
        collapsed.pixels[î] = pixel
        push!(δ̂, (î, pixel))
    end
    δ̂
end

using Test
begin
    old_canvas = Canvas(fill(CLEAR, 200, 100, 4, 3), Set([1, 2]))
    new_canvas = Canvas(fill(CLEAR, 200, 100, 4, 3), Set([1, 2]))
    tests = [
        Rectangle([0.5,0.5],[0.5,0.5]) => CartesianIndices((1:100, 1:100, 1:1, 1:1)),
        Rectangle([0.05,0.5],[0.05,0.5]) => CartesianIndices((1:11, 1:100, 1:1, 1:1)),
        Rectangle([0.05,0.25],[0.05,0.25]) => CartesianIndices((1:11, 1:50, 1:1, 1:1)),
        Rectangle([0.5,0.1],[0.5,0.1]) => CartesianIndices((1:100, 1:21, 1:1, 1:1)),
        Rectangle([0.0,0.0],[0.0,0.0]) => CartesianIndices((1:1, 1:1, 1:1, 1:1)),
        Rectangle([1.0,1.0],[0.0,0.0]) => CartesianIndices((100:100, 100:100, 1:1, 1:1)),
        Rectangle([0.5,0.5,1.0,0.0],[0.5,0.5,0.0,0.0]) => CartesianIndices((1:100, 1:100, 4:4, 1:1)),
        Rectangle([0.5,0.5,1.0,0.5],[0.5,0.5,0.0,0.0]) => CartesianIndices((1:100, 1:100, 4:4, 2:2)),
        Rectangle([0.2,0.25,0.25,1.0],[0.1,0.25,0.25,0.0]) => CartesianIndices((11:31, 1:50, 1:2, 3:3)),
        Rectangle([0.55,0.55,0.55,0.55],[0.05,0.05,0.05,0.05]) => CartesianIndices((51:60, 51:60, 3:3, 2:2)),
    ]
    tests = map(p -> pad(p[1], 4) => p[2], tests)
    for test in tests
        rectangle, i = test
        @test index(old_canvas, rectangle) == i
    end
    import Main.ColorModule: blend,WHITE,RED,GREEN,BLUE,BLACK,YELLOW,PINK,TURQUOISE
    tests = [
        # 1: single opaque front
        [(CartesianIndex(1,1,1,1), WHITE)] => WHITE,
        # 2: single opaque back
        [(CartesianIndex(1,1,1,3), GREEN)] => GREEN,
        # # 3: opaque front occludes back (z=3 is front)
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
        # test=tests[2]
        δ = test[1]
        expected = test[2]
        
        fill!(old_canvas.pixels, CLEAR)
        fill!(new_canvas.pixels, CLEAR)
        for (ix, color) in δ old_canvas.pixels[ix] = color end
        
        collapse!(new_canvas,old_canvas, δ, blend)
        @test new_canvas.pixels[Tuple(δ[1][1])[1:3]..., 1] ≈ expected
    end

    tests = [
        # Test 1: Single pixel at origin
        Sprite(Drawing{2}(_ -> RED), Rectangle([0.0, 0.0], [0.0, 0.0])) => 
            [(CartesianIndex(1, 1, 1, 1), RED)],
        # Test 2: Single pixel at bottom-right of proportional dims
        Sprite(Drawing{2}(_ -> BLUE), Rectangle([1.0, 1.0], [0.0, 0.0])) => 
            [(CartesianIndex(100, 100, 1, 1), BLUE)],
        # Test 3: Single pixel top-left (x=0, y=1)
        Sprite(Drawing{2}(_ -> GREEN), Rectangle([0.0, 1.0], [0.0, 0.0])) => 
            [(CartesianIndex(1, 100, 1, 1), GREEN)],
        # Test 4: Single pixel bottom-right (x=1, y=0)
        Sprite(Drawing{2}(_ -> YELLOW), Rectangle([1.0, 0.0], [0.0, 0.0])) => 
            [(CartesianIndex(100, 1, 1, 1), YELLOW)],
        # Test 5: Clear sprite produces no delta
        Sprite(Drawing{2}(_ -> CLEAR), Rectangle([0.5, 0.5], [0.1, 0.1])) => 
            Tuple{CartesianIndex{4}, Color}[],
        # Test 6: 1D drawing (horizontal line at y=0)
        Sprite(Drawing{1}(_ -> PINK), Rectangle([0.5, 0.0], [0.5, 0.0])) => 
            [(CartesianIndex(i, 1, 1, 1), PINK) for i in 1:100],
        # Test 7: 1D drawing (vertical line at x=0)
        Sprite(Drawing{1}(_ -> TURQUOISE), Rectangle([0.0, 0.5], [0.0, 0.5])) => 
            [(CartesianIndex(1, i, 1, 1), TURQUOISE) for i in 1:100],
        # Test 8: Small 2x2 patch near origin
        Sprite(Drawing{2}(_ -> WHITE), Rectangle([0.01, 0.01], [0.01, 0.01])) => 
            [(CartesianIndex(i, j, 1, 1), WHITE) for i in 1:3 for j in 1:3],
        # Test 9: Center pixel
        Sprite(Drawing{2}(_ -> RED), Rectangle([0.5, 0.5], [0.0, 0.0])) => 
            [],
        # Test 10: 3D rectangle (should pad to 4D with z=2, w=3)
        Sprite(Drawing{3}(_ -> BLUE), Rectangle([0.0, 0.0, 0.5], [0.0, 0.0, 0.5])) => 
            [(CartesianIndex(1, 1, z, 1), BLUE) for z in 1:4],
    ]
    for (i, test) in enumerate(tests)
        fill!(old_canvas.pixels, CLEAR)
        sprite = test[1]
        δ_expected = test[2]
        δ_actual = put!(old_canvas, sprite)
        @test Set(δ_actual) == Set(δ_expected)
    end

    tests = [
        # Test 1: No change when both canvases are CLEAR
        (
            () -> (fill!(old_canvas.pixels, CLEAR); fill!(new_canvas.pixels, CLEAR))
        ) => Tuple{CartesianIndex{4}, Color}[],
        # Test 2: Single pixel changed
        (
            () -> (fill!(old_canvas.pixels, CLEAR); fill!(new_canvas.pixels, CLEAR); new_canvas.pixels[1, 1, 1, 1] = RED)
        ) => [(CartesianIndex(1, 1, 1, 1), RED)],
        # Test 3: No change when both canvases are same color
        (
            () -> (fill!(old_canvas.pixels, RED); fill!(new_canvas.pixels, RED))
        ) => Tuple{CartesianIndex{4}, Color}[],
        # Test 4: All pixels changed (CLEAR to RED)
        (
            () -> (fill!(old_canvas.pixels, CLEAR); fill!(new_canvas.pixels, RED))
        ) => [(CartesianIndex(i, j, k, l), RED) for i in 1:200 for j in 1:100 for k in 1:4 for l in 1:3],
        # Test 5: Single pixel at corner changed
        (
            () -> (fill!(old_canvas.pixels, CLEAR); fill!(new_canvas.pixels, CLEAR); new_canvas.pixels[200, 100, 2, 3] = BLUE)
        ) => [(CartesianIndex(200, 100, 2, 3), BLUE)],
        # Test 6: Multiple scattered pixels changed
        (
            () -> (fill!(old_canvas.pixels, CLEAR); fill!(new_canvas.pixels, CLEAR);
                   new_canvas.pixels[1, 1, 1, 1] = RED;
                   new_canvas.pixels[100, 50, 1, 2] = GREEN;
                   new_canvas.pixels[200, 100, 2, 3] = BLUE)
        ) => [(CartesianIndex(1, 1, 1, 1), RED), (CartesianIndex(100, 50, 1, 2), GREEN), (CartesianIndex(200, 100, 2, 3), BLUE)],
        # Test 7: Color changed from one to another
        (
            () -> (fill!(old_canvas.pixels, RED); fill!(new_canvas.pixels, RED); new_canvas.pixels[50, 50, 1, 1] = BLUE)
        ) => [(CartesianIndex(50, 50, 1, 1), BLUE)],
        # Test 8: Change to CLEAR
        (
            () -> (fill!(old_canvas.pixels, WHITE); fill!(new_canvas.pixels, WHITE); new_canvas.pixels[10, 10, 1, 1] = CLEAR)
        ) => [(CartesianIndex(10, 10, 1, 1), CLEAR)],
        # Test 9: Row of pixels changed
        (
            () -> (fill!(old_canvas.pixels, CLEAR); fill!(new_canvas.pixels, CLEAR);
                   for i in 1:10 new_canvas.pixels[i, 1, 1, 1] = YELLOW end)
        ) => [(CartesianIndex(i, 1, 1, 1), YELLOW) for i in 1:10],
        # Test 10: Checkerboard pattern in small region
        (
            () -> (fill!(old_canvas.pixels, CLEAR); fill!(new_canvas.pixels, CLEAR);
                   for i in 1:4, j in 1:4
                       if (i + j) % 2 == 0
                           new_canvas.pixels[i, j, 1, 1] = BLACK
                       end
                   end))
        => [(CartesianIndex(i, j, 1, 1), BLACK) for i in 1:4 for j in 1:4 if (i + j) % 2 == 0],
    ]
    for (i, test) in enumerate(tests)
        setup = test[1]
        δ_expected = test[2]
        setup()
        δ_actual = Δ(old_canvas, new_canvas)
        @test Set(δ_actual) == Set(δ_expected)
    end
end

end
