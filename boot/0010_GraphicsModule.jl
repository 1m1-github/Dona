module GraphicsModule

export Sprite, Region

import Main: @install
@install StaticArrays
import StaticArrays: SVector
import Main.DrawingModule: Drawing
import Main.ColorModule: Color, CLEAR

import Main.StateModule: state
import Main: LoopOS

"""
A hyperrectangular area inside a unit hypercube, 0.0=bottom-left, 1.0=top-right.
`Region`s are typically used in a `Sprite`.
E.g.: `bullseye = Region("full", [0.0, 0.0], [1.0, 1.0])`
"""
struct Region{N}
    id::String
    corner::SVector{N,Float64} # bottom left
    width::SVector{N,Float64}
end
Region(id::String, corner::Vector, width::Vector) = Region(id, SVector{length(corner)}(corner), SVector{length(corner)}(width))
Region(id::String, corner::NTuple, width::NTuple) = Region(id, SVector(corner...), SVector(width...))

function pad(region::Region{M}, N)::Region{N} where M
    corner = SVector{N}(i ≤ M ? region.corner[i] : 1.0 for i in 1:N)
    width = SVector{N}(i ≤ M ? region.width[i] : 0.0 for i in 1:N)
    Region(region.id, corner, width)
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


function Δ(old::Canvas, new::Canvas)
    pixels = fill(CLEAR, size(new.pixels))
    for i in eachindex(new.pixels)
        old.pixels[i] == new.pixels[i] && continue
        pixels[i] = new.pixels[i]
    end
    Canvas(new.id, pixels)
end

function index(canvas::Canvas{N}, region::Region{N}, strech::Bool=false)::CartesianIndices{N} where N
    canvas_size = size(canvas.pixels)
    active = region.width .≠ 0.0
    canvas_size_active = canvas_size[active]
    width_active = region.width[active]
    available = width_active .* canvas_size_active
    scale = available ./ width_active
    if !strech
        m = minimum(scale)
        scale .= m
    end
    used = width_active .* scale
    corner_active = region.corner[active] .* canvas_size_active
    start_index = max.(round.(Int, corner_active), 1)
    end_index = min.(round.(Int, corner_active .+ used), canvas_size_active)
    end_index = max.(start_index, end_index)
    ranges = Vector{UnitRange{Int}}(undef, N)
    j = 1
    for i in 1:N
        if active[i]
            ranges[i] = start_index[j]:end_index[j]
            j += 1
        else
            ranges[i] = canvas_size[i]:canvas_size[i]  # single pixel in fixed dim
        end
    end
    CartesianIndices(Tuple(ranges))
end
function index(canvas::Canvas{N}, region::Region{N})::CartesianIndices{N} where N
    region_index = region.width .≠ 0.0
    region_widths = region.width[region_index]
    w = first(region_widths)
    strech = any(!=(w), region_widths)
    index(canvas, region, strech)
end
index(canvas::Canvas{N}, region::Region, strech::Bool=false) where N = index(canvas, pad(region, N), strech)

import Base: put!
function put!(canvas::Canvas{N}, sprite::Sprite, strech::Bool=false)::Vector{CartesianIndex{N}} where N
    hyperrectangle_index = index(canvas, sprite.region, strech)
    start_index = SVector{N}([hyperrectangle_index[1][i] for i in 1:N])
    end_index = SVector{N}([hyperrectangle_index[end][i] for i in 1:N])
    width = end_index .- start_index .+ 1
    coordinate_dimension = (!isone).(width)
    δ = CartesianIndex[]
    for i in hyperrectangle_index
        coordinates = (SVector(i.I) .- start_index .+ 0.5) ./ width
        new_color = sprite.drawing(coordinates[coordinate_dimension])
        old_color = canvas.pixels[i]
        old_color == new_color && continue
        canvas.pixels[i] = new_color
        push!(δ, i)
    end
    δ
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
    for i in Δ_index
        for composite_index in canvas_size[end]:-1:1
            î = i.I[1:N-1]
            canvas_i = CartesianIndex((î..., composite_index))
            canvas_composite = CartesianIndex((î..., 1))
            pixels[canvas_composite] = combine(pixels[canvas_composite], canvas.pixels[canvas_i])
            1.0 ≤ pixels[canvas_composite].alpha && break
        end
    end
    Canvas(canvas.id, pixels)
end

end # todo use views?
