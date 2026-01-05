module GraphicsModule

export Color, Drawing, ∘, Region, put!

import Main: @install
@install Colors, FixedPointNumbers, StaticArrays
import Colors: RGBA
import FixedPointNumbers: N0f8
import StaticArrays: SVector

import Main.StateModule: state
import Main: LoopOS

const Color = RGBA{N0f8}
const CLEAR = Color(0.0, 0.0, 0.0, 0.0)
function average(a::Color, b::Color)
    total = 0.5 * a.alpha + 0.5 * b.alpha
    total == 0.0 && return CLEAR
    wa, wb = 0.5 * a.alpha / total, 0.5 * b.alpha / total
    Color(
        a.r * wa + b.r * wb,
        a.g * wa + b.g * wb,
        a.b * wa + b.b * wb,
        a.alpha + b.alpha - a.alpha * b.alpha
    )
end
function blend(a::Color, b::Color)
    b.alpha == 1.0 && return b
    b.alpha == 0.0 && return a
    α = Float64(b.alpha)
    β = 1.0 - α
    Color(α * b.r + β * a.r, α * b.g + β * a.g, α * b.b + β * a.b, 1.0)
end

struct Drawing{N}
    id::String
    f::Function # N-dim hypercube vector -> Color
end
(d::Drawing)(x::SVector) = d.f(x)
(d::Drawing)(x::Vector) = d.f(SVector{length(x)}(x))
(d::Drawing)(x::NTuple) = d.f(SVector(x...))
import Base.∘
∘(a::Drawing, b::Drawing) = Drawing(a.id * b.id, x -> average(a(x), b(x)))

struct Region{N}
    id::String
    center::SVector{N,Float64}
    radius::SVector{N,Float64}
end
Region(id::String, center::Vector, radius::Vector) = Region(id, SVector{length(center)}(center), SVector{length(center)}(radius))
Region(id::String, center::NTuple, radius::NTuple) = Region(id, SVector(center...), SVector(radius...))

struct Canvas{N} <: LoopOS.OutputPeripheral
    id::String
    pixels::Array{Color,N}
end
import Base.size
size(c::Canvas) = size(c.pixels)

function index(canvas::Canvas{N}, region::Region{N})::CartesianIndices{N} where N
    canvas_size = size(canvas.pixels)
    available = 2 .* region.radius .* canvas_size
    scale = minimum(filter(!isnan, available ./ region.radius))
    used = region.radius .* scale
    center = region.center .* canvas_size
    start_index = round.(Int, center .- used ./ 2)
    end_index = round.(Int, center .+ used ./ 2)
    start_index = max.(start_index, 1)
    end_index = min.(end_index, canvas_size)
    CartesianIndices(Tuple(UnitRange.(start_index, end_index)))
end
index(canvas::Canvas{N}, region::Region)::CartesianIndices{N} where N = index(canvas, pad!(region, N))
function pad!(region::Region{M}, N)::Region{M} where M
    center = SVector{N}(i <= M ? region.center[i] : 1.0 for i in 1:N)
    radius = SVector{N}(i <= M ? region.radius[i] : 0.0 for i in 1:N)
    Region(region.id, center, radius)
end
# function remove_dimension!(canvas::Canvas{N}, dimension) # todo
#     Canvas(canvas.id, canvas.pixels[])
# end

struct Sprite{N,M}
    id::String
    drawing::Drawing{N}
    region::Region{M}
end
import Base: put!
function put!(canvas::Canvas{N}, sprite::Sprite)::Vector{CartesianIndex{N}} where N
    hyperrectangle_index = index(canvas, sprite.region)
    start_index = SVector{N}([hyperrectangle_index[1][i] for i in 1:N])
    end_index = SVector{N}([hyperrectangle_index[end][i] for i in 1:N])
    radius = end_index .- start_index .+ 1
    coordinate_dimension = (!iszero).(radius)
    Δ = CartesianIndex[]
    for i in hyperrectangle_index
        coordinates = (SVector(i.I) .- start_index + 0.5) ./ radius
        new_color = sprite.drawing(coordinates[coordinate_dimension])
        old_color = canvas.pixels[i]
        old_color == new_color && continue
        canvas.pixels[i] = new_color
        push!(Δ, i)
    end
    Δ
end

function put!(new_canvas::Canvas{N}, old_canvas::Canvas{N}, Δ_index::Vector{CartesianIndex{N}}) where N
    for i in Δ_index
        old_color = old_canvas.pixels[i]
        new_color = new_canvas.pixels[i]
        old_color == new_color && continue
        new_canvas[i] = new_color
    end
end

function collapse(canvas::Canvas{N}, Δ_index::Vector{CartesianIndex}, combine::Function) where N
    canvas_size = size(canvas.pixels)
    composite_size = (canvas_size[1:end-1]..., 1)
    pixels = fill(CLEAR, composite_size)
    for i in Δ_index, composite_index in canvas_size[end]:-1:1
        î = i[1:end-1]
        canvas_i = CartesianIndex((î..., composite_index))
        canvas_composite = CartesianIndex((î..., 1))
        pixels[canvas_composite] = combine(pixels[canvas_composite], canvas.pixels[canvas_i])
        1.0 ≤ pixels[canvas_composite].alpha && break
    end
    Canvas(canvas.id, pixels)
end

end # todo use views?
using .GraphicsModule
