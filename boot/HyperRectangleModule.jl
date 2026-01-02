module HyperRectangleModule

export Position

struct Position{N} coordinates::NTuple{N,Float64} end

"An N-dim hyperrectangle in a [0,1]^N hypercube"
struct HyperRectangle{N, T}
    id::String
    center::Position{N}
    radius::Position{N}
    value::Array{T,N}
end

"Check if point is inside the hyperrectangle on dimension d"
contains(h::HyperRectangle, d::Int, coordinate::Float64) = abs(coordinate - h.center[d]) <= h.radius[d]

"Check if point is inside the hyperrectangle on all given dimensions"
contains(h::HyperRectangle, coordinates::NTuple{N,Float64}) where N = all(d -> contains(h, d, coordinates[d]), 1:N)

"Sample values at normalized coordinates [0,1]^N"
function sample(value::Array{T,N}, coords::NTuple{N,Float64}) where {T,N}
    dims = size(value)
    indices = ntuple(d -> clamp(round(Int, coords[d] * dims[d] + 0.5), 1, dims[d]), N)
    value[indices...]
end

sample(h::HyperRectangle{N}, coordinates::NTuple{N,Float64}) where N = sample(h.value, coordinates)

end
