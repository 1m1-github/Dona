module GraphicsModule

export Sprite, Region

import Main: @install
@install StaticArrays
import StaticArrays: SVector
import DrawingModule: Drawing
import Main.ColorModule: Color, CLEAR

import Main.StateModule: state
import Main: LoopOS

"""
A hyperrectangular area inside a unit hypercube, 0.0=bottom-left, 1.0=top-right.
`Region`s are typically used in a `Sprite`.
E.g.: `bullseye = Region("center one percent", [0.5, 0.5], [0.05, 0.05])`
"""
struct Region{N}
    id::String
    center::SVector{N,Float64}
    radius::SVector{N,Float64}
end
Region(id::String, center::Vector, radius::Vector) = Region(id, SVector{length(center)}(center), SVector{length(center)}(radius))
Region(id::String, center::NTuple, radius::NTuple) = Region(id, SVector(center...), SVector(radius...))

function pad(region::Region{M}, N)::Region{N} where M
    center = SVector{N}(i ≤ M ? region.center[i] : 1.0 for i in 1:N)
    radius = SVector{N}(i ≤ M ? region.radius[i] : 0.0 for i in 1:N)
    Region(region.id, center, radius)
end


"""
Imagine everything inside a unit hypercube, 0.0=bottom-left, 1.0=top-right.
Define the function mapping from coordinates to a Color (`Drawing`) and a hyrectangular `Region`.
The Sprite lives in the perfectly precise digital world, yet can simply be `put!` onto a `Canvas` for actual display.
E.g.: `put!(BroadcastBrowserCanvas, sky_sprite)`
"""
struct Sprite{N,M}
    id::String
    drawing::Drawing{N}
    region::Region{M}
end

struct Canvas{N} <: LoopOS.OutputPeripheral
    id::String
    pixels::Array{Color,N}
end

function index(canvas::Canvas{N}, region::Region{N})::CartesianIndices{N} where N
    canvas_size = size(canvas.pixels)
    available = 2 .* region.radius .* canvas_size
    scale = minimum(filter(!isnan, available ./ region.radius))
    used = region.radius .* scale
    center = region.center .* canvas_size
    start_index = round.(Int, center .- used ./ 2)
    end_index = round.(Int, center .+ used ./ 2)
    start_index = max.(start_index, 1)
    end_index = max.(start_index, min.(end_index, canvas_size))
    CartesianIndices(Tuple(UnitRange.(start_index, end_index)))
end
index(canvas::Canvas{N}, region::Region) where N = index(canvas, pad(region, N))

import Base: put!
function put!(canvas::Canvas{N}, sprite::Sprite)::Vector{CartesianIndex{N}} where N
    hyperrectangle_index = index(canvas, sprite.region)
    start_index = SVector{N}([hyperrectangle_index[1][i] for i in 1:N])
    end_index = SVector{N}([hyperrectangle_index[end][i] for i in 1:N])
    radius = end_index .- start_index .+ 1
    coordinate_dimension = (!iszero).(radius)
    Δ = CartesianIndex[]
    for i in hyperrectangle_index
        coordinates = (SVector(i.I) .- start_index .+ 0.5) ./ radius
        new_color = sprite.drawing(coordinates[coordinate_dimension])
        old_color = canvas.pixels[i]
        old_color == new_color && continue
        canvas.pixels[i] = new_color
        push!(Δ, i)
    end
    Δ
end
function put!(new::Canvas{N}, old::Canvas{N}, Δ_index::Vector{CartesianIndex{N}}) where N
    for i in Δ_index
        old_color = old.pixels[i]
        new_color = new.pixels[i]
        old_color == new_color && continue
        new.pixels[i] = new_color
    end
end

function collapse(canvas::Canvas{N}, Δ_index::Vector{CartesianIndex{N}}, combine::Function) where N
    canvas_size = size(canvas.pixels)
    composite_size = (canvas_size[1:end-1]..., 1)
    pixels = fill(CLEAR, composite_size)
    for i in Δ_index, composite_index in canvas_size[end]:-1:1
        î = i.I[1:N-1]
        canvas_i = CartesianIndex((î..., composite_index))
        canvas_composite = CartesianIndex((î..., 1))
        pixels[canvas_composite] = combine(pixels[canvas_composite], canvas.pixels[canvas_i])
        1.0 ≤ pixels[canvas_composite].alpha && break
    end
    Canvas(canvas.id, pixels)
end

end # todo use views?
