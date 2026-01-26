using SHA

const ORIGIN = 1//2
const CACHE = Dict{UInt64,Real}()

mutable struct Something{T<:Real}
    name::String
    origin::Vector{T}
    radius::Vector{T}
    active_dims::Vector{T}
    closed::Vector{Bool}
    ∃::Function
    parent::Union{Something{T},Nothing}
    parenthash::Vector{UInt8}
    children::Vector{Something{T}}
end

function Base.hash(S::Something)
    io = IOBuffer()
    write(io, S.name)
    for x in S.origin; write(io, string(x)); end
    for x in S.radius; write(io, string(x)); end
    for x in S.active_dims; write(io, string(x)); end
    for x in S.closed; write(io, string(x)); end
    write(io, S.parenthash)
    sha3_512(take!(io))
end

get_dim(ω::Dict{T,T}, d::T) where {T<:Real} = get(ω, d, T(ORIGIN))

function in_bounds(S::Something{T}, ω::Dict{T,T}) where {T<:Real}
    for (i, d) in enumerate(S.active_dims)
        val = get_dim(ω, d)
        lo, hi = S.origin[i] - S.radius[i], S.origin[i] + S.radius[i]
        (val < lo || val > hi) && return false
    end
    true
end

function inside(S::Something{T}, ω::Dict{T,T}) where {T<:Real}
    for d in keys(ω)
        d ∉ S.active_dims && get_dim(ω, d) != T(ORIGIN) && return false
    end
    for (i, d) in enumerate(S.active_dims)
        val = get_dim(ω, d)
        lo, hi = S.origin[i] - S.radius[i], S.origin[i] + S.radius[i]
        if S.closed[i]
            (val < lo || val > hi) && return false
        else
            (val <= lo || val >= hi) && return false
        end
    end
    true
end

function at_boundary(S::Something{T}, ω::Dict{T,T}) where {T<:Real}
    for (i, d) in enumerate(S.active_dims)
        S.radius[i] == 0 && continue
        val = get_dim(ω, d)
        lo, hi = S.origin[i] - S.radius[i], S.origin[i] + S.radius[i]
        (val == lo || val == hi) && return true
    end
    false
end

function intervals_disjoint(lo1, hi1, c1::Bool, lo2, hi2, c2::Bool)
    (c1 && c2) ? (hi1 < lo2 || hi2 < lo1) : (hi1 <= lo2 || hi2 <= lo1)
end

function disjoint(S::Something{T}, S′::Something{T}) where {T<:Real}
    orig = T(ORIGIN)
    for (j, d) in enumerate(S′.active_dims)
        if d ∉ S.active_dims
            lo, hi = S′.origin[j] - S′.radius[j], S′.origin[j] + S′.radius[j]
            if S′.closed[j]
                (orig < lo || orig > hi) && return true
            else
                (orig <= lo || orig >= hi) && return true
            end
        end
    end
    for (i, d) in enumerate(S.active_dims)
        j = findfirst(==(d), S′.active_dims)
        j === nothing && continue
        lo1, hi1 = S.origin[i] - S.radius[i], S.origin[i] + S.radius[i]
        lo2, hi2 = S′.origin[j] - S′.radius[j], S′.origin[j] + S′.radius[j]
        intervals_disjoint(lo1, hi1, S.closed[i], lo2, hi2, S′.closed[j]) && return true
    end
    false
end

function contained_in(S::Something{T}, S′::Something{T}) where {T<:Real}
    orig = T(ORIGIN)
    for (i, d) in enumerate(S.active_dims)
        lo, hi = S.origin[i] - S.radius[i], S.origin[i] + S.radius[i]
        j = findfirst(==(d), S′.active_dims)
        if j === nothing
            (orig < lo || orig > hi) && return false
        else
            lo′, hi′ = S′.origin[j] - S′.radius[j], S′.origin[j] + S′.radius[j]
            (lo′ < lo || hi′ > hi) && return false
        end
    end
    true
end

function find_parent(S::Something{T}, S′::Something{T}) where {T<:Real}
    for c in S.children
        contained_in(c, S′) && return find_parent(c, S′)
    end
    S
end

function valid_bounds(origin::Vector{T}, radius::Vector{T}) where {T<:Real}
    for (o, r) in zip(origin, radius)
        r < 0 && return false
        o - r < 0 && return false
        o + r > 1 && return false
    end
    true
end

function create(parent::Something{T}, name::String, origin::Vector{T}, radius::Vector{T},
                active_dims::Vector{T}, closed::Vector{Bool}, ∃::Function) where {T<:Real}
    !valid_bounds(origin, radius) && return nothing
    S′ = Something{T}(name, origin, radius, active_dims, closed, ∃, nothing, UInt8[], Something{T}[])
    p = find_parent(parent, S′)
    p !== parent && !disjoint(p, S′) && return nothing
    any(sib -> !disjoint(sib, S′), p.children) && return nothing
    S = Something{T}(name, origin, radius, active_dims, closed, ∃, p, hash(p), Something{T}[])
    push!(p.children, S)
    S
end

function valid_point(ω::Dict{T,T}) where {T<:Real}
    all(v -> 0 <= v <= 1, values(ω))
end

function observe(ω::Dict{T,T}, S::Something{T}) where {T<:Real}
    !valid_point(ω) && return (T(ORIGIN), S, false)
    for c in S.children
        if in_bounds(c, ω)
            result = observe(ω, c)
            result[2] !== S && return result
        end
    end
    inside(S, ω) || return (T(ORIGIN), S, true)
    at_boundary(S, ω) && return (T(ORIGIN), S, true)
    h = hash(ω)
    haskey(CACHE, h) && return (CACHE[h], S, true)
    CACHE[h] = S.∃(ω)
    (CACHE[h], S, true)
end

struct Grid{T<:Real}
    dims::Vector{T}
    origin::Vector{T}
    radius::Vector{T}
    resolution::Vector{Int}
end

function grid_to_coords(g::Grid{T}, idx::Vector{Int}) where {T<:Real}
    coords = Dict{T,T}()
    for (i, d) in enumerate(g.dims)
        n = g.resolution[i]
        lo, hi = g.origin[i] - g.radius[i], g.origin[i] + g.radius[i]
        coords[d] = n == 1 ? g.origin[i] : lo + T(idx[i] - 1) / T(n - 1) * (hi - lo)
    end
    coords
end

function grid_indices(g::Grid)
    (collect(idx) for idx in Iterators.product((1:n for n in g.resolution)...))
end

function observe_grid(g::Grid{T}, S::Something{T}) where {T<:Real}
    Dict(collect(idx) => Real(observe(grid_to_coords(g, collect(idx)), S)[1]) 
         for idx in grid_indices(g))
end

function grid_to_array(g::Grid, results::Dict{Vector{Int},Real})
    [results[[i,j]] for i in 1:g.resolution[1], j in 1:g.resolution[2]]
end