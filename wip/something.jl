using SHA

const CACHE = Dict{UInt64,Real}()

mutable struct Something{T<:Real}
    name::String
    origin::Vector{T}
    radius::Vector{T}
    active_dims::Vector{T}
    ∃::Function
    parent::Union{Something{T},Nothing}
    parenthash::Vector{UInt8}
    children::Vector{Something{T}}
end

function Base.hash(S::Something{T}) where {T}
    io = IOBuffer()
    write(io, S.name)
    for x in S.origin; write(io, string(x)); end
    for x in S.radius; write(io, string(x)); end
    for x in S.active_dims; write(io, string(x)); end
    write(io, S.parenthash)
    sha3_512(take!(io))
end

const NOWHERE = _ -> 0
const ORIGIN = 1 // 2
const EVERYWHERE = _ -> 1
const Ω = Something{Rational{BigInt}}(
    "Ω",
    Rational{BigInt}[],
    Rational{BigInt}[],
    Rational{BigInt}[],
    _ -> ORIGIN,
    nothing,
    sha3_512("Ω"),
    Something{Rational{BigInt}}[]
)
const GOD = const UNIVERSE = const WORLD = Ω

# ============================================================
# HELPERS
# ============================================================

"""
Extract the value at dimension d from ω.
"""
function get_dim(ω::Dict{T,T}, d::T)::T where {T<:Real}
    get(ω, d, T(ORIGIN))
end

# --- Tests for get_dim ---
@assert get_dim(Dict(0.0 => 0.3, 1.0 => 0.7), 0.0) == 0.3 "get_dim: active dim"
@assert get_dim(Dict(0.0 => 0.3, 1.0 => 0.7), 1.0) == 0.7 "get_dim: second dim"
@assert get_dim(Dict(0.0 => 0.3, 1.0 => 0.7), 2.0) == 0.5 "get_dim: missing dim returns ORIGIN"
@assert get_dim(Dict{Float64,Float64}(), 1.0) == 0.5 "get_dim: empty dict returns ORIGIN"
println("✓ get_dim")

"""
Check if ω is at ORIGIN in dimension d.
"""
function is_at_origin(ω::Dict{T,T}, d::T)::Bool where {T<:Real}
    get_dim(ω, d) == T(ORIGIN)
end

# --- Tests for is_at_origin ---
@assert is_at_origin(Dict(0.0 => 0.5, 1.0 => 0.3), 0.0) == true "is_at_origin: at 0.5"
@assert is_at_origin(Dict(0.0 => 0.5, 1.0 => 0.3), 1.0) == false "is_at_origin: not at origin"
@assert is_at_origin(Dict(0.0 => 0.3), 1.0) == true "is_at_origin: missing dim is at origin"
@assert is_at_origin(Dict{Float64,Float64}(), 0.0) == true "is_at_origin: empty is at origin"
println("✓ is_at_origin")

"""
Check if point ω is inside S's bounds.
"""
function inside(S::Something{T}, ω::Dict{T,T})::Bool where {T<:Real}
    for d in keys(ω)
        if d ∉ S.active_dims && !is_at_origin(ω, d)
            return false
        end
    end
    for (i, d) in enumerate(S.active_dims)
        val = get_dim(ω, d)
        lo, hi = S.origin[i] - S.radius[i], S.origin[i] + S.radius[i]
        (val < lo || val > hi) && return false
    end
    true
end

# --- Tests for inside ---
let T = Rational{BigInt}
    @assert inside(Ω, Dict{T,T}(T(0) => T(1//2), T(1) => T(1//2))) == true "inside: Ω contains all-origin point"
    @assert inside(Ω, Dict{T,T}(T(0) => T(3//10))) == false "inside: Ω rejects non-origin"
    S = Something{T}("test", T[1//2], T[1//5], T[0], _ -> 1//2, Ω, hash(Ω), Something{T}[])
    @assert inside(S, Dict{T,T}(T(0) => T(1//2))) == true "inside: center of S"
    @assert inside(S, Dict{T,T}(T(0) => T(4//5))) == false "inside: outside S bounds"
    @assert inside(S, Dict{T,T}(T(0) => T(1//2), T(1) => T(3//10))) == false "inside: non-origin in inactive dim"
    @assert inside(S, Dict{T,T}(T(0) => T(1//2), T(1) => T(1//2))) == true "inside: origin in inactive dim ok"
end
println("✓ inside")

"""
Check if ω is within S's bounds in S's active dims only.
Does NOT check if ω is at ORIGIN in other dims.
Used for tree traversal - children might still contain the point.
"""
function in_bounds(S::Something{T}, ω::Dict{T,T})::Bool where {T<:Real}
    for (i, d) in enumerate(S.active_dims)
        val = get_dim(ω, d)
        lo, hi = S.origin[i] - S.radius[i], S.origin[i] + S.radius[i]
        (val < lo || val > hi) && return false
    end
    true
end

# --- Tests for in_bounds ---
let T = Rational{BigInt}
    S = Something{T}("test", T[1//2], T[1//5], T[0], _ -> 1//2, Ω, hash(Ω), Something{T}[])
    # S has bounds [0.3, 0.7] in dim 0
    @assert in_bounds(S, Dict{T,T}(T(0) => T(1//2))) == true "in_bounds: center"
    @assert in_bounds(S, Dict{T,T}(T(0) => T(1//5))) == false "in_bounds: outside"
    # Extra dims don't matter for in_bounds
    @assert in_bounds(S, Dict{T,T}(T(0) => T(1//2), T(1) => T(1//5))) == true "in_bounds: extra dim ignored"
    @assert in_bounds(S, Dict{T,T}(T(0) => T(1//2), T(1) => T(3//4))) == true "in_bounds: extra dim any value"
end
println("✓ in_bounds")

"""
Check if ω is exactly at the boundary of S.
"""
function at_boundary(S::Something{T}, ω::Dict{T,T})::Bool where {T<:Real}
    for (i, d) in enumerate(S.active_dims)
        val = get_dim(ω, d)
        lo, hi = S.origin[i] - S.radius[i], S.origin[i] + S.radius[i]
        (val == lo || val == hi) && return true
    end
    false
end

# --- Tests for at_boundary ---
let T = Rational{BigInt}
    S = Something{T}("test", T[1//2], T[1//5], T[0], _ -> 1//2, Ω, hash(Ω), Something{T}[])
    # bounds are [3/10, 7/10]
    @assert at_boundary(S, Dict{T,T}(T(0) => T(3//10))) == true "at_boundary: at lo"
    @assert at_boundary(S, Dict{T,T}(T(0) => T(7//10))) == true "at_boundary: at hi"
    @assert at_boundary(S, Dict{T,T}(T(0) => T(1//2))) == false "at_boundary: center"
    @assert at_boundary(S, Dict{T,T}(T(0) => T(31//100))) == false "at_boundary: near but not at"
end
println("✓ at_boundary")

"""
Check if S′ is disjoint from S in Ω.
"""
function disjoint(S::Something{T}, S′::Something{T})::Bool where {T<:Real}
    orig = T(ORIGIN)
    for (j, d) in enumerate(S′.active_dims)
        if d ∉ S.active_dims
            lo_S′ = S′.origin[j] - S′.radius[j]
            hi_S′ = S′.origin[j] + S′.radius[j]
            (orig <= lo_S′ || orig >= hi_S′) && return true
        end
    end
    for (i, d) in enumerate(S.active_dims)
        j = findfirst(==(d), S′.active_dims)
        j === nothing && continue
        lo_S, hi_S = S.origin[i] - S.radius[i], S.origin[i] + S.radius[i]
        lo_S′, hi_S′ = S′.origin[j] - S′.radius[j], S′.origin[j] + S′.radius[j]
        (hi_S′ < lo_S || hi_S < lo_S′) && return true
    end
    false
end

# --- Tests for disjoint ---
let T = Rational{BigInt}
    S1 = Something{T}("S1", T[1//2], T[1//5], T[0], _ -> 1//2, Ω, hash(Ω), Something{T}[])
    S2_overlaps = Something{T}("S2", T[1//2], T[1//5], T[1], _ -> 1//2, Ω, hash(Ω), Something{T}[])
    S2_disjoint = Something{T}("S2", T[4//5], T[1//10], T[1], _ -> 1//2, Ω, hash(Ω), Something{T}[])
    S3 = Something{T}("S3", T[1//2, 4//5], T[1//10, 1//10], T[0, 1], _ -> 1//2, Ω, hash(Ω), Something{T}[])
    S4 = Something{T}("S4", T[9//10], T[1//20], T[0], _ -> 1//2, Ω, hash(Ω), Something{T}[])
    @assert disjoint(S1, S2_overlaps) == false "disjoint: new dim but includes ORIGIN"
    @assert disjoint(S1, S2_disjoint) == true "disjoint: new dim excludes ORIGIN"
    @assert disjoint(S1, S3) == true "disjoint: S3 has dim 1 excluding ORIGIN"
    @assert disjoint(S1, S4) == true "disjoint: same dim, non-overlapping"
    @assert disjoint(S1, S1) == false "disjoint: self not disjoint"
end
println("✓ disjoint")

"""
Check if S′ is contained in S's active dim bounds.
"""
function contained_in(S::Something{T}, S′::Something{T})::Bool where {T<:Real}
    orig = T(ORIGIN)
    for (i, d) in enumerate(S.active_dims)
        j = findfirst(==(d), S′.active_dims)
        if j === nothing
            lo, hi = S.origin[i] - S.radius[i], S.origin[i] + S.radius[i]
            (orig < lo || orig > hi) && return false
        else
            lo_S, hi_S = S.origin[i] - S.radius[i], S.origin[i] + S.radius[i]
            lo_S′, hi_S′ = S′.origin[j] - S′.radius[j], S′.origin[j] + S′.radius[j]
            (lo_S′ < lo_S || hi_S′ > hi_S) && return false
        end
    end
    true
end

# --- Tests for contained_in ---
let T = Rational{BigInt}
    S1 = Something{T}("S1", T[1//2], T[2//5], T[0], _ -> 1//2, Ω, hash(Ω), Something{T}[])
    S2 = Something{T}("S2", T[1//2], T[1//10], T[0], _ -> 1//2, Ω, hash(Ω), Something{T}[])
    S3 = Something{T}("S3", T[1//2], T[1//10], T[1], _ -> 1//2, Ω, hash(Ω), Something{T}[])
    @assert contained_in(Ω, S1) == true "contained_in: everything in Ω"
    @assert contained_in(S1, S2) == true "contained_in: narrower interval"
    @assert contained_in(S2, S1) == false "contained_in: wider not in narrower"
    @assert contained_in(S1, S3) == true "contained_in: different dim, S3 at ORIGIN in dim 0"
end
println("✓ contained_in")

"""
Find the deepest Something that contains S′ in shared active dims.
Tree structure is based on spatial containment, not disjointness.
A child's bounds must fit within parent's bounds in shared dims.
"""
function find_parent(S::Something{T}, S′::Something{T})::Something{T} where {T<:Real}
    for child in S.children
        if contained_in(child, S′)
            return find_parent(child, S′)
        end
    end
    S
end

# --- Tests for find_parent ---
let T = Rational{BigInt}
    @assert find_parent(Ω, Something{T}("test", T[1//2], T[1//10], T[0], _ -> 1//2, nothing, UInt8[], Something{T}[])) === Ω "find_parent: direct child of Ω"
    
    S1 = Something{T}("S1", T[1//2], T[2//5], T[0], _ -> 1//2, Ω, hash(Ω), Something{T}[])
    push!(Ω.children, S1)
    # S2 fits within S1's dim 0 bounds, so becomes child of S1
    S2_spec = Something{T}("S2", T[1//2, 4//5], T[1//10, 1//10], T[0, 1], _ -> 1//2, nothing, UInt8[], Something{T}[])
    @assert find_parent(Ω, S2_spec) === S1 "find_parent: S2 nested under S1"
    empty!(Ω.children)
    
    @assert find_parent(Ω, Something{T}("test", T[1//2], T[1//10], T[5], _ -> 1//2, nothing, UInt8[], Something{T}[])) === Ω "find_parent: new dim only goes to Ω"
end
println("✓ find_parent")

# ============================================================
# CREATE
# ============================================================

"""
Create a new Something as child of appropriate parent.
"""
function create(
    name::String,
    origin::Vector{T},
    radius::Vector{T},
    active_dims::Vector{T},
    ∃::Function
)::Union{Something{T},Nothing} where {T<:Real}
    S′ = Something{T}(name, origin, radius, active_dims, ∃, nothing, UInt8[], Something{T}[])
    
    parent = find_parent(Ω, S′)
    
    if parent !== Ω && !disjoint(parent, S′)
        return nothing
    end
    
    for sibling in parent.children
        !disjoint(sibling, S′) && return nothing
    end
    
    S = Something{T}(name, origin, radius, active_dims, ∃, parent, hash(parent), Something{T}[])
    push!(parent.children, S)
    S
end

# --- Tests for create ---
let T = Rational{BigInt}
    empty!(Ω.children)
    S = create("S1", T[1//2], T[1//5], T[0], ω -> get_dim(ω, T(0)))
    @assert S !== nothing "create: should succeed"
    @assert S.parent === Ω "create: parent is Ω"
    @assert length(Ω.children) == 1 "create: added to Ω"
    empty!(Ω.children)
end
println("✓ create: direct child of Ω")

let T = Rational{BigInt}
    empty!(Ω.children)
    S1 = create("S1", T[4//5], T[1//10], T[0], _ -> 3//10)
    S2 = create("S2", T[1//5], T[1//10], T[1], _ -> 7//10)
    @assert S1 !== nothing "create: S1 succeeds"
    @assert S2 !== nothing "create: S2 succeeds"
    @assert length(Ω.children) == 2 "create: both are Ω children"
    empty!(Ω.children)
end
println("✓ create: disjoint siblings")

let T = Rational{BigInt}
    empty!(Ω.children)
    S1 = create("S1", T[1//2], T[1//5], T[0], _ -> 3//10)
    S2 = create("S2", T[1//2], T[1//10], T[0], _ -> 7//10)
    @assert S1 !== nothing "create: S1 succeeds"
    @assert S2 === nothing "create: S2 rejected"
    @assert length(Ω.children) == 1 "create: only S1"
    empty!(Ω.children)
end
println("✓ create: reject overlapping siblings")

let T = Rational{BigInt}
    empty!(Ω.children)
    S1 = create("S1", T[1//2], T[3//10], T[0], _ -> 1//2)
    # S2 fits within S1's dim 0 bounds, becomes child even though disjoint in points
    S2 = create("S2", T[1//2, 4//5], T[1//10, 1//10], T[0, 1], _ -> 4//5)
    @assert S1 !== nothing "create: S1 succeeds"
    @assert S2 !== nothing "create: S2 succeeds"
    @assert S2.parent === S1 "create: S2 is child of S1 (contained in bounds)"
    @assert length(S1.children) == 1 "create: S2 in S1.children"
    empty!(Ω.children)
end
println("✓ create: nested child (contained in parent bounds)")

# ============================================================
# OBSERVE
# ============================================================

"""
Observe existence at point ω.
Tree traversal uses in_bounds (active dims only).
Ownership uses inside (full check including ORIGIN requirement).
Boundary is always ORIGIN by definition.
Returns (∃_value, owning_Something, valid).
"""
function observe(ω::Dict{T,T}, S::Something{T}=Ω)::Tuple{Real,Something{T},Bool} where {T<:Real}
    # Tree traversal: check children that might contain ω
    for child in S.children
        if in_bounds(child, ω)
            # Child's bounds contain ω in child's active dims
            # Recurse to find deeper owner
            result = observe(ω, child)
            if result[2] !== S
                # Found owner in subtree
                return result
            end
        end
    end
    
    # Check if S itself owns this point
    if inside(S, ω)
        # Boundary is ORIGIN by definition
        if at_boundary(S, ω)
            return (T(ORIGIN), S, true)
        end
        
        # Check cache
        ω_hash = hash(ω)
        haskey(CACHE, ω_hash) && return (CACHE[ω_hash], S, true)
        
        # Compute and cache
        ∃_val = S.∃(ω)
        CACHE[ω_hash] = ∃_val
        return (∃_val, S, true)
    end
    
    # S doesn't own it, return S as placeholder (will be replaced by parent's result)
    (T(ORIGIN), S, true)
end

# --- Tests for observe ---
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    ∃_val, owner, valid = observe(Dict{T,T}(T(0) => T(1//2), T(1) => T(1//2)))
    @assert ∃_val == ORIGIN "observe: Ω returns ORIGIN"
    @assert owner === Ω "observe: owner is Ω"
    @assert valid == true "observe: valid"
    empty!(Ω.children)
end
println("✓ observe: ground state Ω")

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    S = create("S1", T[1//2], T[1//5], T[0], ω -> get_dim(ω, T(0)))
    ∃_val, owner, _ = observe(Dict{T,T}(T(0) => T(1//2)))
    @assert ∃_val == 1//2 "observe: S1 returns ω[0]"
    @assert owner === S "observe: owner is S1"
    empty!(Ω.children)
end
println("✓ observe: inside Something")

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    # S returns 0.9 everywhere, but boundary should still be ORIGIN
    S = create("S1", T[1//2], T[1//5], T[0], _ -> 9//10)
    # Observe at boundary (lo = 3/10)
    ∃_val, owner, _ = observe(Dict{T,T}(T(0) => T(3//10)))
    @assert ∃_val == ORIGIN "observe: boundary is ORIGIN regardless of S.∃"
    @assert owner === S "observe: S still owns the boundary"
    # Observe inside
    empty!(CACHE)
    ∃_val_inside, _, _ = observe(Dict{T,T}(T(0) => T(1//2)))
    @assert ∃_val_inside == 9//10 "observe: inside returns S.∃"
    empty!(Ω.children)
end
println("✓ observe: boundary is ORIGIN by definition")

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    call_count = Ref(0)
    S = create("S1", T[1//2], T[1//5], T[0], ω -> begin
        call_count[] += 1
        get_dim(ω, T(0))
    end)
    observe(Dict{T,T}(T(0) => T(1//2)))
    observe(Dict{T,T}(T(0) => T(1//2)))
    @assert call_count[] == 1 "observe: second call uses cache"
    empty!(Ω.children)
    empty!(CACHE)
end
println("✓ observe: caching works")

# ============================================================
# GRID OBSERVATION
# ============================================================

"""
A Grid maps n-dimensional cartesian indices to continuous coordinates.
- dims: which dimensions in Ω this grid covers
- origin: center of the grid in each dim
- radius: half-width of the grid in each dim
- resolution: number of points in each dim (including corners)
"""
struct Grid{T<:Real}
    dims::Vector{T}
    origin::Vector{T}
    radius::Vector{T}
    resolution::Vector{Int}
end

"""
Convert cartesian indices (1-indexed) to continuous coordinates.
Returns a Dict{T,T} mapping dim -> value.
"""
function grid_to_coords(g::Grid{T}, indices::Vector{Int})::Dict{T,T} where {T<:Real}
    @assert length(indices) == length(g.dims) "indices must match grid dimensions"
    coords = Dict{T,T}()
    for (i, d) in enumerate(g.dims)
        n = g.resolution[i]
        if n == 1
            coords[d] = g.origin[i]
        else
            # Map index 1..n to [origin-radius, origin+radius]
            lo = g.origin[i] - g.radius[i]
            hi = g.origin[i] + g.radius[i]
            t = T(indices[i] - 1) / T(n - 1)
            coords[d] = lo + t * (hi - lo)
        end
    end
    coords
end

# --- Tests for grid_to_coords ---
let T = Rational{BigInt}
    g = Grid{T}(T[0], T[1//2], T[1//2], [5])  # dim 0, origin 0.5, radius 0.5, 5 points -> [0, 0.25, 0.5, 0.75, 1]
    @assert grid_to_coords(g, [1]) == Dict{T,T}(T(0) => T(0)) "grid_to_coords: first point"
    @assert grid_to_coords(g, [3]) == Dict{T,T}(T(0) => T(1//2)) "grid_to_coords: middle point"
    @assert grid_to_coords(g, [5]) == Dict{T,T}(T(0) => T(1)) "grid_to_coords: last point"
end
println("✓ grid_to_coords: 1D")

let T = Rational{BigInt}
    g = Grid{T}(T[0, 1], T[1//2, 1//2], T[1//4, 1//4], [3, 3])  # 3x3 grid
    # corners: [1/4, 1/4] to [3/4, 3/4]
    @assert grid_to_coords(g, [1, 1]) == Dict{T,T}(T(0) => T(1//4), T(1) => T(1//4)) "grid_to_coords: corner (1,1)"
    @assert grid_to_coords(g, [3, 3]) == Dict{T,T}(T(0) => T(3//4), T(1) => T(3//4)) "grid_to_coords: corner (3,3)"
    @assert grid_to_coords(g, [2, 2]) == Dict{T,T}(T(0) => T(1//2), T(1) => T(1//2)) "grid_to_coords: center"
end
println("✓ grid_to_coords: 2D")

let T = Rational{BigInt}
    g = Grid{T}(T[0], T[1//2], T[1//4], [1])  # single point
    @assert grid_to_coords(g, [1]) == Dict{T,T}(T(0) => T(1//2)) "grid_to_coords: single point at origin"
end
println("✓ grid_to_coords: single point")

let T = Float64
    g = Grid{T}(T[0.0, 1.0, 2.0], T[0.5, 0.5, 0.5], T[0.25, 0.1, 0.05], [3, 5, 2])
    coords = grid_to_coords(g, [1, 1, 1])
    @assert coords[0.0] == 0.25 "grid_to_coords: 3D dim 0"
    @assert coords[1.0] == 0.4 "grid_to_coords: 3D dim 1"
    @assert coords[2.0] == 0.45 "grid_to_coords: 3D dim 2"
end
println("✓ grid_to_coords: 3D Float64")

"""
Iterate over all cartesian indices in the grid.
Returns an iterator of Vector{Int}.
"""
function grid_indices(g::Grid{T}) where {T<:Real}
    ranges = [1:n for n in g.resolution]
    (collect(idx) for idx in Iterators.product(ranges...))
end

# --- Tests for grid_indices ---
let T = Rational{BigInt}
    g = Grid{T}(T[0], T[1//2], T[1//2], [3])
    indices = collect(grid_indices(g))
    @assert length(indices) == 3 "grid_indices: 1D count"
    @assert indices[1] == [1] "grid_indices: first"
    @assert indices[3] == [3] "grid_indices: last"
end
println("✓ grid_indices: 1D")

let T = Rational{BigInt}
    g = Grid{T}(T[0, 1], T[1//2, 1//2], T[1//4, 1//4], [2, 3])
    indices = collect(grid_indices(g))
    @assert length(indices) == 6 "grid_indices: 2x3 count"
end
println("✓ grid_indices: 2D")

"""
Observe the entire grid, returning a Dict mapping indices to ∃ values.
Can be parallelized since each observation is independent.
"""
function observe_grid(g::Grid{T}, S::Something{T}=Ω; parallel::Bool=false)::Dict{Vector{Int},Real} where {T<:Real}
    results = Dict{Vector{Int},Real}()
    indices_list = collect(grid_indices(g))
    
    if parallel && length(indices_list) > 1
        # Parallel observation
        tasks = [Threads.@spawn observe(grid_to_coords(g, idx), S)[1] for idx in indices_list]
        for (i, idx) in enumerate(indices_list)
            results[idx] = Real(fetch(tasks[i]))
        end
    else
        # Sequential observation
        for idx in indices_list
            ω = grid_to_coords(g, idx)
            ∃_val, _, _ = observe(ω, S)
            results[idx] = Real(∃_val)
        end
    end
    
    results
end

# --- Tests for observe_grid ---
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    g = Grid{T}(T[0], T[1//2], T[1//4], [3])  # [1/4, 1/2, 3/4] in dim 0
    results = observe_grid(g)
    # All points outside any S, so all ORIGIN
    @assert results[[1]] == ORIGIN "observe_grid: point 1"
    @assert results[[2]] == ORIGIN "observe_grid: point 2"
    @assert results[[3]] == ORIGIN "observe_grid: point 3"
    empty!(Ω.children)
end
println("✓ observe_grid: empty world")

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    # S covers [3/10, 7/10] in dim 0, returns the coordinate value
    S = create("S1", T[1//2], T[1//5], T[0], ω -> get_dim(ω, T(0)))
    g = Grid{T}(T[0], T[1//2], T[1//5], [5])  # [3/10, 4/10, 5/10, 6/10, 7/10]
    results = observe_grid(g)
    @assert results[[1]] == ORIGIN "observe_grid: boundary lo is ORIGIN"
    @assert results[[3]] == 1//2 "observe_grid: center"
    @assert results[[5]] == ORIGIN "observe_grid: boundary hi is ORIGIN"
    empty!(Ω.children)
    empty!(CACHE)
end
println("✓ observe_grid: with Something")

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    S = create("S1", T[1//2], T[1//5], T[0], ω -> get_dim(ω, T(0)))
    g = Grid{T}(T[0, 1], T[1//2, 1//2], T[1//5, 1//10], [3, 3])
    results = observe_grid(g)
    # Only points at ORIGIN in dim 1 are inside S
    # dim 1 values: [4/10, 5/10, 6/10] -> only middle (5/10) is ORIGIN
    @assert results[[2, 2]] == 1//2 "observe_grid: 2D center in S"
    @assert results[[1, 2]] == ORIGIN "observe_grid: 2D boundary in S"
    @assert results[[2, 1]] == ORIGIN "observe_grid: 2D outside S (dim 1 not at ORIGIN)"
    empty!(Ω.children)
    empty!(CACHE)
end
println("✓ observe_grid: 2D with Something")

"""
Convert grid observation results to an n-dimensional array.
"""
function grid_to_array(g::Grid{T}, results::Dict{Vector{Int},Real})::Array{Real} where {T<:Real}
    arr = Array{Real}(undef, g.resolution...)
    for (idx, val) in results
        arr[idx...] = val
    end
    arr
end

# --- Tests for grid_to_array ---
let T = Rational{BigInt}
    g = Grid{T}(T[0], T[1//2], T[1//4], [3])
    results = Dict{Vector{Int},Real}([1] => 1//10, [2] => 1//2, [3] => 9//10)
    arr = grid_to_array(g, results)
    @assert size(arr) == (3,) "grid_to_array: 1D size"
    @assert arr[1] == 1//10 "grid_to_array: 1D values"
    @assert arr[2] == 1//2 "grid_to_array: 1D values"
    @assert arr[3] == 9//10 "grid_to_array: 1D values"
end
println("✓ grid_to_array: 1D")

let T = Rational{BigInt}
    g = Grid{T}(T[0, 1], T[1//2, 1//2], T[1//4, 1//4], [2, 3])
    results = Dict{Vector{Int},Real}([1,1] => 1//10, [1,2] => 2//10, [1,3] => 3//10,
                                      [2,1] => 4//10, [2,2] => 5//10, [2,3] => 6//10)
    arr = grid_to_array(g, results)
    @assert size(arr) == (2, 3) "grid_to_array: 2D size"
    @assert arr[1, 1] == 1//10 "grid_to_array: 2D values"
    @assert arr[2, 3] == 6//10 "grid_to_array: 2D values"
end
println("✓ grid_to_array: 2D")

# ============================================================
println("\n" * "="^50)
println("All tests passed!")
println("="^50)
