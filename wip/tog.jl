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

# Something World - End-to-End Demo
# Include the core library first
# include("something.jl")

using Printf

# ============================================================
# PERIPHERALS - Projections from n-dim to observable screens
# ============================================================

"""
A Peripheral projects from the infinite-dimensional existence field
onto an observable output (2D screen, 3D volume, audio, etc.)

- observer_position: Dict{T,T} - where the observer is in Ω
- view_dims: which dimensions to project onto screen axes
- screen_resolution: pixels per view dimension
- screen_origin: center of view in each view_dim
- screen_radius: half-width of view in each view_dim
"""
struct Peripheral{T<:Real}
    name::String
    observer_position::Dict{T,T}  # fixed coordinates in non-view dims
    view_dims::Vector{T}          # dims that map to screen axes
    screen_resolution::Vector{Int}
    screen_origin::Vector{T}      # center of view
    screen_radius::Vector{T}      # zoom level
end

"""
Create a 2D screen peripheral.
"""
function Screen2D(T::Type{<:Real}, name::String;
                  observer=nothing,
                  x_dim=nothing, y_dim=nothing,
                  resolution::Tuple{Int,Int}=(64, 64),
                  origin=nothing,
                  radius=nothing)
    obs = observer === nothing ? Dict{T,T}() : observer
    xd = x_dim === nothing ? T(0) : x_dim
    yd = y_dim === nothing ? T(1) : y_dim
    org = origin === nothing ? (T(1//2), T(1//2)) : origin
    rad = radius === nothing ? (T(1//4), T(1//4)) : radius
    Peripheral{T}(
        name,
        obs,
        T[xd, yd],
        [resolution...],
        T[org...],
        T[rad...]
    )
end

"""
Render the view through a peripheral, returning a 2D array of existence values.
"""
function render(p::Peripheral{T}, S::Something{T}=Ω) where {T<:Real}
    # Build grid from peripheral spec
    g = Grid{T}(p.view_dims, p.screen_origin, p.screen_radius, p.screen_resolution)
    
    # For each grid point, merge with observer position
    results = Dict{Vector{Int},Real}()
    for idx in grid_indices(g)
        ω = grid_to_coords(g, collect(idx))
        # Merge observer's fixed position with view coordinates
        for (d, v) in p.observer_position
            if d ∉ p.view_dims
                ω[d] = v
            end
        end
        ∃_val, _, _ = observe(ω, S)
        results[collect(idx)] = Real(∃_val)
    end
    
    grid_to_array(g, results)
end

"""
Convert existence array to ASCII art.
"""
function to_ascii(arr::Array{Real,2}; chars::String=" .:-=+*#%@")
    w, h = size(arr)
    lines = String[]
    for y in h:-1:1  # flip y for natural orientation
        line = ""
        for x in 1:w
            v = clamp(arr[x, y], 0, 1)
            idx = round(Int, v * (length(chars) - 1)) + 1
            line *= chars[idx]
        end
        push!(lines, line)
    end
    join(lines, "\n")
end

"""
Convert existence array to ANSI colored blocks.
"""
function to_ansi(arr::Array{Real,2})
    h, w = size(arr)
    lines = String[]
    for y in h:-1:1
        line = ""
        for x in 1:w
            v = clamp(arr[x, y], 0, 1)
            # Map to grayscale: 232-255 are grays in 256-color mode
            gray = round(Int, v * 23) + 232
            line *= "\e[48;5;$(gray)m  \e[0m"
        end
        push!(lines, line)
    end
    join(lines, "\n")
end

# ============================================================
# PNG/GIF OUTPUT
# ============================================================

"""
Write a minimal PNG file (grayscale, no compression).
Uses raw PNG format with no external dependencies.
"""
function to_png(arr::Array{Real,2}, filename::String; scale::Int=4)
    w, h = size(arr)
    sw, sh = w * scale, h * scale
    
    # PNG signature
    signature = UInt8[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    
    # CRC32 table
    crc_table = zeros(UInt32, 256)
    for i in 0:255
        c = UInt32(i)
        for _ in 1:8
            if (c & 1) != 0
                c = 0xedb88320 ⊻ (c >> 1)
            else
                c >>= 1
            end
        end
        crc_table[i + 1] = c
    end
    
    function crc32(data::Vector{UInt8})
        c = 0xffffffff
        for b in data
            c = crc_table[(c ⊻ b) & 0xff + 1] ⊻ (c >> 8)
        end
        c ⊻ 0xffffffff
    end
    
    function write_chunk(io, chunk_type::String, data::Vector{UInt8})
        len = UInt32(length(data))
        write(io, hton(len))
        type_bytes = Vector{UInt8}(chunk_type)
        write(io, type_bytes)
        write(io, data)
        crc_data = vcat(type_bytes, data)
        write(io, hton(crc32(crc_data)))
    end
    
    # IHDR chunk
    ihdr = IOBuffer()
    write(ihdr, hton(UInt32(sw)))  # width
    write(ihdr, hton(UInt32(sh)))  # height
    write(ihdr, UInt8(8))          # bit depth
    write(ihdr, UInt8(0))          # color type (grayscale)
    write(ihdr, UInt8(0))          # compression
    write(ihdr, UInt8(0))          # filter
    write(ihdr, UInt8(0))          # interlace
    ihdr_data = take!(ihdr)
    
    # Image data (uncompressed via zlib stored block)
    raw_data = IOBuffer()
    for y in sh:-1:1  # flip y
        write(raw_data, UInt8(0))  # filter type: none
        for x in 1:sw
            ox, oy = div(x - 1, scale) + 1, div(y - 1, scale) + 1
            v = clamp(arr[ox, oy], 0, 1)
            gray = round(UInt8, v * 255)
            write(raw_data, gray)
        end
    end
    raw_bytes = take!(raw_data)
    
    # Wrap in zlib format (stored blocks, no compression)
    zlib_data = IOBuffer()
    write(zlib_data, UInt8(0x78), UInt8(0x01))  # zlib header (no compression)
    
    # Split into 65535-byte blocks
    pos = 1
    while pos <= length(raw_bytes)
        block_end = min(pos + 65534, length(raw_bytes))
        block = raw_bytes[pos:block_end]
        is_final = block_end >= length(raw_bytes)
        write(zlib_data, UInt8(is_final ? 0x01 : 0x00))  # final flag
        len = UInt16(length(block))
        write(zlib_data, len)           # length (little endian)
        write(zlib_data, ~len)          # one's complement
        write(zlib_data, block)
        pos = block_end + 1
    end
    
    # Adler-32 checksum
    a, b = UInt32(1), UInt32(0)
    for byte in raw_bytes
        a = (a + byte) % 65521
        b = (b + a) % 65521
    end
    adler = (b << 16) | a
    write(zlib_data, hton(adler))
    
    idat_data = take!(zlib_data)
    
    # Write PNG file
    open(filename, "w") do io
        write(io, signature)
        write_chunk(io, "IHDR", ihdr_data)
        write_chunk(io, "IDAT", idat_data)
        write_chunk(io, "IEND", UInt8[])
    end
    
    filename
end

"""
Create an animated GIF from multiple frames.
"""
function to_gif(frames::Vector{<:Array{Real,2}}, filename::String; 
                scale::Int=4, delay::Int=20)
    if isempty(frames)
        error("No frames provided")
    end
    
    w, h = size(frames[1])
    sw, sh = w * scale, h * scale
    
    open(filename, "w") do io
        # GIF89a header
        write(io, "GIF89a")
        
        # Logical screen descriptor
        write(io, UInt16(sw))  # width (little endian)
        write(io, UInt16(sh))  # height
        write(io, UInt8(0xF7)) # global color table, 8 bits, 256 colors
        write(io, UInt8(0))    # background color index
        write(io, UInt8(0))    # pixel aspect ratio
        
        # Global color table (256 grays)
        for i in 0:255
            write(io, UInt8(i), UInt8(i), UInt8(i))
        end
        
        # Netscape extension for looping
        write(io, UInt8(0x21), UInt8(0xFF), UInt8(0x0B))
        write(io, "NETSCAPE2.0")
        write(io, UInt8(0x03), UInt8(0x01))
        write(io, UInt16(0))  # loop forever
        write(io, UInt8(0))   # block terminator
        
        for arr in frames
            # Graphics control extension (for delay)
            write(io, UInt8(0x21), UInt8(0xF9), UInt8(0x04))
            write(io, UInt8(0x00))        # no transparency
            write(io, UInt16(delay))      # delay in 1/100 sec
            write(io, UInt8(0), UInt8(0)) # transparent color, terminator
            
            # Image descriptor
            write(io, UInt8(0x2C))
            write(io, UInt16(0), UInt16(0))  # left, top
            write(io, UInt16(sw), UInt16(sh)) # width, height
            write(io, UInt8(0))               # no local color table
            
            # LZW compressed image data
            min_code_size = 8
            write(io, UInt8(min_code_size))
            
            # Simple LZW encoding
            pixels = UInt8[]
            for y in sh:-1:1
                for x in 1:sw
                    ox, oy = div(x - 1, scale) + 1, div(y - 1, scale) + 1
                    v = clamp(arr[ox, oy], 0, 1)
                    push!(pixels, round(UInt8, v * 255))
                end
            end
            
            # LZW encode
            clear_code = 256
            eoi_code = 257
            
            codes = Int[]
            push!(codes, clear_code)
            
            dict = Dict{Vector{UInt8}, Int}()
            for i in 0:255
                dict[UInt8[i]] = i
            end
            next_code = 258
            code_size = 9
            
            buffer = UInt8[]
            for pixel in pixels
                test = vcat(buffer, pixel)
                if haskey(dict, test)
                    buffer = test
                else
                    push!(codes, dict[buffer])
                    if next_code < 4096
                        dict[test] = next_code
                        next_code += 1
                        if next_code > (1 << code_size) && code_size < 12
                            code_size += 1
                        end
                    else
                        push!(codes, clear_code)
                        dict = Dict{Vector{UInt8}, Int}()
                        for i in 0:255
                            dict[UInt8[i]] = i
                        end
                        next_code = 258
                        code_size = 9
                    end
                    buffer = UInt8[pixel]
                end
            end
            if !isempty(buffer)
                push!(codes, dict[buffer])
            end
            push!(codes, eoi_code)
            
            # Pack codes into bytes
            bit_buffer = UInt64(0)
            bits_in_buffer = 0
            output_bytes = UInt8[]
            current_code_size = 9
            codes_written = 0
            
            for code in codes
                if code == clear_code
                    current_code_size = 9
                end
                bit_buffer |= UInt64(code) << bits_in_buffer
                bits_in_buffer += current_code_size
                while bits_in_buffer >= 8
                    push!(output_bytes, UInt8(bit_buffer & 0xFF))
                    bit_buffer >>= 8
                    bits_in_buffer -= 8
                end
                codes_written += 1
                if codes_written >= (1 << current_code_size) - 1 && current_code_size < 12
                    current_code_size += 1
                end
            end
            if bits_in_buffer > 0
                push!(output_bytes, UInt8(bit_buffer & 0xFF))
            end
            
            # Write in sub-blocks (max 255 bytes each)
            pos = 1
            while pos <= length(output_bytes)
                block_size = min(255, length(output_bytes) - pos + 1)
                write(io, UInt8(block_size))
                write(io, output_bytes[pos:pos+block_size-1])
                pos += block_size
            end
            write(io, UInt8(0))  # block terminator
        end
        
        # GIF trailer
        write(io, UInt8(0x3B))
    end
    
    filename
end

"""
Render multiple time slices as frames for animation.
"""
function render_animation(p::Peripheral{T}, time_dim::T, time_values::Vector{T}, 
                          S::Something{T}=Ω) where {T<:Real}
    frames = Array{Real,2}[]
    for t in time_values
        # Set time in observer position
        obs = copy(p.observer_position)
        obs[time_dim] = t
        p_frame = Peripheral{T}(p.name, obs, p.view_dims, p.screen_resolution, 
                                 p.screen_origin, p.screen_radius)
        empty!(CACHE)
        push!(frames, render(p_frame, S))
    end
    frames
end

# ============================================================
# DEMO 1: Static 2D Art - A Circle
# ============================================================

println("\n" * "="^60)
println("DEMO 1: Static Circle in 2D")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create a circular region: existence = 1 inside, fades at edge
    # Circle at center (1/2, 1/2), radius 1/5 in dims 0,1
    circle = create("circle", 
        T[1//2, 1//2],           # origin
        T[1//5, 1//5],           # radius
        T[0, 1],                 # dims x, y
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r_max = 0.2
            r < r_max * 0.8 ? 1.0 : 0.5  # solid inside, ORIGIN at boundary
        end
    )
    
    # Create peripheral: 2D screen looking at x,y
    screen = Screen2D(T, "main_view",
        resolution=(32, 32),
        origin=(T(1//2), T(1//2)),
        radius=(T(1//3), T(1//3))
    )
    
    img = render(screen)
    println("\nCircle (existence = 1.0 inside, 0.5 outside):")
    println(to_ascii(img))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 2: Nested Structures - Ball with Hidden Room
# ============================================================

println("\n" * "="^60)
println("DEMO 2: Bowling Ball with Hidden Jacuzzi")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # The bowling ball: visible in dims 0,1 (x,y)
    # Solid existence = 0.9
    ball = create("bowling_ball",
        T[1//2, 1//2],
        T[1//5, 1//5],
        T[0, 1],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.15 ? 0.9 : 0.5  # dark solid ball
        end
    )
    
    # The hidden jacuzzi: same x,y center, but shifted in dim 2 (z)
    # z = 0.75 with radius 0.1 means bounds [0.65, 0.85] - excludes ORIGIN (0.5)
    jacuzzi = create("jacuzzi",
        T[1//2, 1//2, 3//4],     # same x,y but z=0.75
        T[1//10, 1//10, 1//10],  # radius 0.1 in z: [0.65, 0.85]
        T[0, 1, 2],              # lives in x,y,z
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.08 ? 1.0 : 0.5  # bright jacuzzi!
        end
    )
    
    println("Ball created: ", ball !== nothing)
    println("Jacuzzi created: ", jacuzzi !== nothing)
    
    # Observer 1: Normal view (z = 0.5 = ORIGIN)
    # Can only see the bowling ball
    screen_normal = Peripheral{T}(
        "normal_observer",
        Dict{T,T}(T(2) => T(1//2)),  # z at ORIGIN
        T[0, 1],
        [32, 32],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    # Observer 2: Secret view (z = 0.75)
    # Can see the jacuzzi!
    screen_secret = Peripheral{T}(
        "secret_observer",
        Dict{T,T}(T(2) => T(3//4)),  # z at 0.75
        T[0, 1],
        [32, 32],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    println("\nNormal view (z=0.5) - just the bowling ball:")
    img_normal = render(screen_normal)
    println(to_ascii(img_normal))
    
    println("\nSecret view (z=0.75) - the hidden jacuzzi inside!")
    empty!(CACHE)
    img_secret = render(screen_secret)
    println(to_ascii(img_secret))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 3: Time Dimension - Animation
# ============================================================

println("\n" * "="^60)
println("DEMO 3: Moving Ball (time dimension)")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # A ball that moves in x as t increases
    # At t=0.3: ball at x=0.3
    # At t=0.5: ball at x=0.5
    # At t=0.7: ball at x=0.7
    # The trick: ball's x-position is tied to t
    
    # We create multiple balls at different t-slices
    for (i, t) in enumerate([3//10, 4//10, 5//10, 6//10, 7//10])
        x_pos = t  # ball moves with time
        ball = create("ball_t$i",
            T[x_pos, 1//2, t],      # x follows t, y=center, t=specific
            T[1//20, 1//10, 1//100], # small in x,y, very thin in t
            T[0, 1, 2],             # dims: x, y, t
            _ -> 0.95
        )
    end
    
    println("\nFrames of animation (t = 0.3, 0.4, 0.5, 0.6, 0.7):\n")
    
    for t in [3//10, 4//10, 5//10, 6//10, 7//10]
        screen = Peripheral{T}(
            "frame_t=$t",
            Dict{T,T}(T(2) => T(t)),  # fix time
            T[0, 1],                   # view x,y
            [40, 16],
            T[1//2, 1//2],
            T[1//2, 1//4]
        )
        empty!(CACHE)
        img = render(screen)
        println("t = $t:")
        println(to_ascii(img, chars=" .o"))
        println()
    end
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 4: Different Physics - Gravity Subspace
# ============================================================

println("\n" * "="^60)
println("DEMO 4: Subspace with Different Physics")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create a "gravity zone" - existence increases downward (higher y = less existence)
    gravity_zone = create("gravity_zone",
        T[1//2, 1//2],
        T[2//5, 2//5],
        T[0, 1],
        ω -> begin
            y = Float64(get_dim(ω, T(1)))
            # Gravity: existence higher at bottom
            0.5 + 0.4 * (1.0 - y)  # varies from 0.9 at bottom to 0.5 at top
        end
    )
    
    # Create a "floating zone" inside - reversed physics!
    # Must be in different dim to be disjoint
    floating_zone = create("floating_zone",
        T[1//2, 1//2, 1//5],      # shift in z to be disjoint
        T[1//5, 1//5, 1//10],
        T[0, 1, 2],
        ω -> begin
            y = Float64(get_dim(ω, T(1)))
            # Anti-gravity: existence higher at top
            0.5 + 0.4 * y
        end
    )
    
    println("\nGravity zone (brighter at bottom, observer at z=0.5):")
    screen_gravity = Peripheral{T}(
        "gravity_view",
        Dict{T,T}(T(2) => T(1//2)),
        T[0, 1],
        [32, 16],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    img_gravity = render(screen_gravity)
    println(to_ascii(img_gravity))
    
    println("\nFloating zone (brighter at top, observer at z=0.2):")
    screen_floating = Peripheral{T}(
        "floating_view",
        Dict{T,T}(T(2) => T(1//5)),
        T[0, 1],
        [32, 16],
        T[1//2, 1//2],
        T[1//5, 1//5]
    )
    empty!(CACHE)
    img_floating = render(screen_floating)
    println(to_ascii(img_floating))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 5: God's Eye View - Observing from Different Angles
# ============================================================

println("\n" * "="^60)
println("DEMO 5: Same Structure, Different Projections")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create a 3D cross shape
    # Vertical bar in y
    create("cross_vertical",
        T[1//2, 1//2, 1//5],
        T[1//20, 1//5, 1//10],
        T[0, 1, 2],
        _ -> 0.9
    )
    
    # Horizontal bar in x
    create("cross_horizontal",
        T[1//2, 1//2, 3//10],    # different z to be disjoint
        T[1//5, 1//20, 1//10],
        T[0, 1, 2],
        _ -> 0.9
    )
    
    # View from front (x,y plane, z=0.2)
    println("\nFront view (x,y at z=0.2) - sees vertical bar:")
    screen_front = Peripheral{T}("front", Dict{T,T}(T(2) => T(1//5)), T[0, 1], [24, 24], T[1//2, 1//2], T[1//4, 1//4])
    println(to_ascii(render(screen_front)))
    
    # View at z=0.3 - sees horizontal bar
    println("\nFront view (x,y at z=0.3) - sees horizontal bar:")
    empty!(CACHE)
    screen_front2 = Peripheral{T}("front2", Dict{T,T}(T(2) => T(3//10)), T[0, 1], [24, 24], T[1//2, 1//2], T[1//4, 1//4])
    println(to_ascii(render(screen_front2)))
    
    # Side view (y,z plane, x=0.5)
    println("\nSide view (y,z at x=0.5) - sees both bars as dots:")
    empty!(CACHE)
    screen_side = Peripheral{T}("side", Dict{T,T}(T(0) => T(1//2)), T[1, 2], [24, 24], T[1//2, 1//4], T[1//4, 1//6])
    println(to_ascii(render(screen_side)))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 6: The Multiverse - Same Location, Different Dimensions
# ============================================================

println("\n" * "="^60)
println("DEMO 6: Parallel Worlds at Same x,y")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # World 1: A house (at dimension 3 = 0.2)
    create("house_floor",
        T[1//2, 3//10, 1//5],
        T[1//5, 1//20, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    create("house_roof",
        T[1//2, 13//20, 3//10],   # different dim 3 to be disjoint
        T[1//6, 1//10, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    
    # World 2: An ocean (at dimension 3 = 0.8)
    create("ocean",
        T[1//2, 3//10, 4//5],
        T[2//5, 1//10, 1//10],
        T[0, 1, 3],
        ω -> begin
            x = Float64(get_dim(ω, T(0)))
            0.6 + 0.1 * sin(x * 20)  # waves
        end
    )
    
    # God at dimension 3 = 0.2 sees a house
    println("\nWorld 1 (dim3=0.2) - The House:")
    screen_house = Peripheral{T}("house_world", Dict{T,T}(T(3) => T(1//5)), T[0, 1], [32, 20], T[1//2, 1//2], T[1//3, 1//3])
    println(to_ascii(render(screen_house)))
    
    # God at dimension 3 = 0.8 sees an ocean
    println("\nWorld 2 (dim3=0.8) - The Ocean:")
    empty!(CACHE)
    screen_ocean = Peripheral{T}("ocean_world", Dict{T,T}(T(3) => T(4//5)), T[0, 1], [32, 20], T[1//2, 1//2], T[1//3, 1//3])
    println(to_ascii(render(screen_ocean)))
    
    println("\nSame x,y coordinates, completely different realities!")
    println("Move in dimension 3 to travel between worlds.")
    
    empty!(Ω.children)
end

# ============================================================
println("\n" * "="^60)
println("END OF ASCII DEMOS")
println("="^60)

# ============================================================
# IMAGE OUTPUT DEMOS
# ============================================================

println("\n" * "="^60)
println("GENERATING PNG AND GIF FILES")
println("="^60)

# Demo: Circle as PNG
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    circle = create("circle", 
        T[1//2, 1//2],
        T[1//5, 1//5],
        T[0, 1],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r_max = 0.2
            r < r_max * 0.8 ? 1.0 : 0.5
        end
    )
    
    screen = Screen2D(T, "circle_view",
        resolution=(64, 64),
        origin=(T(1//2), T(1//2)),
        radius=(T(1//3), T(1//3))
    )
    
    img = render(screen)
    to_png(img, "circle.png", scale=4)
    println("✓ Saved circle.png")
    
    empty!(Ω.children)
end

# Demo: Bowling ball and jacuzzi as PNGs
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    ball = create("bowling_ball",
        T[1//2, 1//2],
        T[1//5, 1//5],
        T[0, 1],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.15 ? 0.9 : 0.5
        end
    )
    
    jacuzzi = create("jacuzzi",
        T[1//2, 1//2, 3//4],
        T[1//10, 1//10, 1//10],
        T[0, 1, 2],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.08 ? 1.0 : 0.5
        end
    )
    
    println("Ball created: ", ball !== nothing)
    println("Jacuzzi created: ", jacuzzi !== nothing)
    if jacuzzi !== nothing
        println("Jacuzzi parent: ", jacuzzi.parent.name)
    end
    
    # Normal view
    screen_normal = Peripheral{T}(
        "normal_observer",
        Dict{T,T}(T(2) => T(1//2)),
        T[0, 1],
        [64, 64],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    img_normal = render(screen_normal)
    to_png(img_normal, "ball_normal.png", scale=4)
    println("✓ Saved ball_normal.png (z=0.5, sees ball)")
    
    # Secret view
    screen_secret = Peripheral{T}(
        "secret_observer",
        Dict{T,T}(T(2) => T(3//4)),
        T[0, 1],
        [64, 64],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    empty!(CACHE)
    img_secret = render(screen_secret)
    to_png(img_secret, "ball_secret.png", scale=4)
    println("✓ Saved ball_secret.png (z=0.75, sees jacuzzi)")
    
    empty!(Ω.children)
end

# Demo: Animated moving ball as GIF
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create balls at different time slices
    for (i, t) in enumerate([2//10, 3//10, 4//10, 5//10, 6//10, 7//10, 8//10])
        x_pos = t
        create("ball_t$i",
            T[x_pos, 1//2, t],
            T[1//20, 1//10, 1//100],
            T[0, 1, 2],
            _ -> 1.0
        )
    end
    
    # Render animation
    screen = Peripheral{T}(
        "animation",
        Dict{T,T}(),
        T[0, 1],
        [64, 32],
        T[1//2, 1//2],
        T[1//2, 1//4]
    )
    
    time_values = T[2//10, 3//10, 4//10, 5//10, 6//10, 7//10, 8//10]
    frames = render_animation(screen, T(2), time_values)
    
    to_gif(frames, "moving_ball.gif", scale=4, delay=15)
    println("✓ Saved moving_ball.gif")
    
    empty!(Ω.children)
end

# Demo: Parallel worlds as PNGs
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # World 1: House
    create("house_floor",
        T[1//2, 3//10, 1//5],
        T[1//5, 1//20, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    create("house_roof",
        T[1//2, 13//20, 3//10],
        T[1//6, 1//10, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    
    # World 2: Ocean with waves
    create("ocean",
        T[1//2, 3//10, 4//5],
        T[2//5, 1//10, 1//10],
        T[0, 1, 3],
        ω -> begin
            x = Float64(get_dim(ω, T(0)))
            0.6 + 0.3 * sin(x * 30)
        end
    )
    
    # House world
    screen_house = Peripheral{T}("house", Dict{T,T}(T(3) => T(1//5)), T[0, 1], 
                                  [64, 48], T[1//2, 1//2], T[1//3, 1//3])
    img_house = render(screen_house)
    to_png(img_house, "world_house.png", scale=4)
    println("✓ Saved world_house.png (dim3=0.2)")
    
    # Ocean world
    empty!(CACHE)
    screen_ocean = Peripheral{T}("ocean", Dict{T,T}(T(3) => T(4//5)), T[0, 1],
                                  [64, 48], T[1//2, 1//2], T[1//3, 1//3])
    img_ocean = render(screen_ocean)
    to_png(img_ocean, "world_ocean.png", scale=4)
    println("✓ Saved world_ocean.png (dim3=0.8)")
    
    empty!(Ω.children)
end

# Demo: Pulsing object (animated)
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create pulsing circles at different times
    for (i, t) in enumerate(0:1//20:19//20)
        # Radius varies with time: oscillates between 0.05 and 0.15
        phase = Float64(t) * 2 * π
        r = 0.1 + 0.05 * sin(phase * 2)
        
        create("pulse_t$i",
            T[1//2, 1//2, t],
            T[Rational{BigInt}(r), Rational{BigInt}(r), 1//100],
            T[0, 1, 2],
            _ -> 0.9
        )
    end
    
    screen = Peripheral{T}(
        "pulse",
        Dict{T,T}(),
        T[0, 1],
        [64, 64],
        T[1//2, 1//2],
        T[1//4, 1//4]
    )
    
    time_values = collect(T(0):T(1//20):T(19//20))
    frames = render_animation(screen, T(2), time_values)
    
    to_gif(frames, "pulsing.gif", scale=4, delay=5)
    println("✓ Saved pulsing.gif")
    
    empty!(Ω.children)
end

println("\n" * "="^60)
println("ALL FILES GENERATED")
println("="^60)
println("""

Generated files:
  - circle.png         : Static circle
  - ball_normal.png    : Bowling ball (normal view)
  - ball_secret.png    : Hidden jacuzzi inside ball
  - moving_ball.gif    : Ball moving through time
  - world_house.png    : House in dimension 3 = 0.2
  - world_ocean.png    : Ocean in dimension 3 = 0.8
  - pulsing.gif        : Pulsing circle animation

""")

# Fractal in Something space
# A Sierpinski-like triangle that exists at multiple scales

# include("something.jl")
# include("something_demo.jl")  # for to_gif, render, Peripheral

# ============================================================
# SIERPINSKI TRIANGLE via nested Somethings
# ============================================================

function create_sierpinski(depth::Int, T::Type{<:Real}=Rational{BigInt})
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create triangular regions recursively
    # Each level: 3 triangles at corners of parent
    
    function add_triangle(name, cx, cy, r, level)
        level > depth && return
        
        # Create this triangle (approximated as small square for simplicity)
        create(name,
            T[cx, cy],
            T[r, r],
            T[0, 1],
            ω -> begin
                x = Float64(get_dim(ω, T(0)) - cx)
                y = Float64(get_dim(ω, T(1)) - cy)
                rf = Float64(r)
                # Triangle: y < r - |x| * (r/r) scaled
                if abs(x) < rf && y > -rf && y < rf - abs(x) * 1.5
                    0.9
                else
                    0.5
                end
            end
        )
        
        # Recurse: three sub-triangles
        nr = r / 2
        # Bottom left
        add_triangle(name * "L", cx - r/2, cy - r/2, nr, level + 1)
        # Bottom right  
        add_triangle(name * "R", cx + r/2, cy - r/2, nr, level + 1)
        # Top
        add_triangle(name * "T", cx, cy + r/2, nr, level + 1)
    end
    
    add_triangle("S", T(1//2), T(1//2), T(1//4), 0)
end

# ============================================================
# MANDELBROT-LIKE via existence function
# ============================================================

function create_mandelbrot(T::Type{<:Real}=Rational{BigInt})
    empty!(Ω.children)
    empty!(CACHE)
    
    create("mandelbrot",
        T[1//2, 1//2],
        T[1//2, 1//2],  # full space
        T[0, 1],
        ω -> begin
            # Map [0,1] to [-2,1] for x and [-1.5,1.5] for y
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            
            x0 = px * 3.0 - 2.0  # [-2, 1]
            y0 = py * 3.0 - 1.5  # [-1.5, 1.5]
            
            x, y = 0.0, 0.0
            iter = 0
            max_iter = 50
            
            while x*x + y*y <= 4 && iter < max_iter
                x, y = x*x - y*y + x0, 2*x*y + y0
                iter += 1
            end
            
            # Map iterations to existence
            0.5 + 0.5 * (iter / max_iter)
        end
    )
end

# ============================================================
# JULIA SET with animation (varying c parameter over time)
# ============================================================

function create_julia_animated(T::Type{<:Real}=Rational{BigInt})
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create Julia sets at different time slices
    # c parameter varies with time dimension
    
    n_frames = 30
    for i in 0:n_frames-1
        t = T(i) / T(n_frames)
        
        # c traces a circle in complex plane
        θ = Float64(t) * 2 * π
        c_re = 0.7885 * cos(θ)
        c_im = 0.7885 * sin(θ)
        
        create("julia_t$i",
            T[1//2, 1//2, t],
            T[1//2, 1//2, 1//(2*n_frames)],  # thin time slice
            T[0, 1, 2],
            ω -> begin
                px = Float64(get_dim(ω, T(0)))
                py = Float64(get_dim(ω, T(1)))
                
                # Map to [-1.5, 1.5]
                x = px * 3.0 - 1.5
                y = py * 3.0 - 1.5
                
                iter = 0
                max_iter = 40
                
                while x*x + y*y <= 4 && iter < max_iter
                    x, y = x*x - y*y + c_re, 2*x*y + c_im
                    iter += 1
                end
                
                0.5 + 0.4 * (iter / max_iter)
            end
        )
    end
    
    n_frames
end

# ============================================================
# RENDER AND SAVE
# ============================================================

println("Creating Mandelbrot set...")
create_mandelbrot(Rational{BigInt})

screen = Peripheral{Rational{BigInt}}(
    "mandelbrot_view",
    Dict{Rational{BigInt},Rational{BigInt}}(),
    Rational{BigInt}[0, 1],
    [128, 128],
    Rational{BigInt}[1//2, 1//2],
    Rational{BigInt}[1//2, 1//2]
)

img = render(screen)
to_png(img, "mandelbrot.png", scale=4)
println("✓ Saved mandelbrot.png")

# ============================================================

println("\nCreating animated Julia set...")
T = Rational{BigInt}
n_frames = create_julia_animated(T)

# Render each time slice
frames = Array{Real,2}[]
for i in 0:n_frames-1
    t = T(i) / T(n_frames)
    
    screen = Peripheral{T}(
        "julia_frame",
        Dict{T,T}(T(2) => t + T(1)//(T(4)*T(n_frames))),  # center of time slice
        T[0, 1],
        [100, 100],
        T[1//2, 1//2],
        T[1//2, 1//2]
    )
    
    empty!(CACHE)
    push!(frames, render(screen))
    print(".")
end
println()

to_gif(frames, "julia_animated.gif", scale=4, delay=8)
println("✓ Saved julia_animated.gif")

# ============================================================

println("\nCreating Sierpinski triangle...")
create_sierpinski(4, Rational{BigInt})

screen = Peripheral{Rational{BigInt}}(
    "sierpinski_view",
    Dict{Rational{BigInt},Rational{BigInt}}(),
    Rational{BigInt}[0, 1],
    [128, 128],
    Rational{BigInt}[1//2, 1//2],
    Rational{BigInt}[1//3, 1//3]
)

empty!(CACHE)
img = render(screen)
to_png(img, "sierpinski.png", scale=4)
println("✓ Saved sierpinski.png")

# ============================================================

println("\nCreating zoom animation into Mandelbrot...")
create_mandelbrot(Rational{BigInt})

# Zoom into an interesting point
zoom_frames = Array{Real,2}[]
center_x = Rational{BigInt}(3//10)  # interesting region
center_y = Rational{BigInt}(1//2)
n_zoom = 40

for i in 0:n_zoom-1
    # Exponential zoom
    scale = Rational{BigInt}(1//2) * (Rational{BigInt}(9//10) ^ i)
    
    screen = Peripheral{Rational{BigInt}}(
        "zoom_frame",
        Dict{Rational{BigInt},Rational{BigInt}}(),
        Rational{BigInt}[0, 1],
        [100, 100],
        Rational{BigInt}[center_x, center_y],
        Rational{BigInt}[scale, scale]
    )
    
    empty!(CACHE)
    push!(zoom_frames, render(screen))
    print(".")
end
println()

to_gif(zoom_frames, "mandelbrot_zoom.gif", scale=4, delay=10)
println("✓ Saved mandelbrot_zoom.gif")

# ============================================================

println("\n" * "="^50)
println("All fractals generated!")
println("="^50)
println("""
Files:
  - mandelbrot.png       : Static Mandelbrot set
  - sierpinski.png       : Sierpinski triangle (depth 4)
  - julia_animated.gif   : Julia set with rotating c parameter
  - mandelbrot_zoom.gif  : Zoom into Mandelbrot set
""")


# Improved Fractal Animations

# include("something.jl")
# include("something_demo.jl")

T = Rational{BigInt}

# ============================================================
# MANDELBROT ZOOM - into the famous spiral region
# ============================================================

println("Creating Mandelbrot zoom into spiral region...")

empty!(Ω.children)
empty!(CACHE)

create("mandelbrot",
    T[1//2, 1//2],
    T[1//2, 1//2],
    T[0, 1],
    ω -> begin
        px = Float64(get_dim(ω, T(0)))
        py = Float64(get_dim(ω, T(1)))
        
        # Map [0,1] to [-2.5, 1.0] x [-1.5, 1.5]
        x0 = px * 3.5 - 2.5
        y0 = py * 3.0 - 1.5
        
        x, y = 0.0, 0.0
        iter = 0
        max_iter = 100
        
        while x*x + y*y <= 4 && iter < max_iter
            x, y = x*x - y*y + x0, 2*x*y + y0
            iter += 1
        end
        
        # Smooth coloring
        if iter == max_iter
            0.1  # inside = dark
        else
            0.5 + 0.4 * (iter / max_iter)
        end
    end
)

# Zoom into seahorse valley: approximately (-0.75, 0.1)
# In our [0,1] coords: x = (-0.75 + 2.5) / 3.5 ≈ 0.5, y = (0.1 + 1.5) / 3.0 ≈ 0.53

zoom_frames = Array{Real,2}[]
n_zoom = 50

# Target in [0,1] coordinates
target_x = T(50//100)  # seahorse valley
target_y = T(53//100)

for i in 0:n_zoom-1
    # Exponential zoom: start at 1/2, shrink by 0.92 each frame
    scale = Float64(1//2) * (0.92 ^ i)
    scale_r = T(round(Int, scale * 1000)) // 1000
    
    screen = Peripheral{T}(
        "zoom",
        Dict{T,T}(),
        T[0, 1],
        [120, 120],
        T[target_x, target_y],
        T[scale_r, scale_r]
    )
    
    empty!(CACHE)
    push!(zoom_frames, render(screen))
    print(".")
end
println()

to_gif(zoom_frames, "mandelbrot_zoom2.gif", scale=3, delay=6)
println("✓ Saved mandelbrot_zoom2.gif")

# ============================================================
# ROTATING MANDELBROT - rotate view angle over time
# ============================================================

println("\nCreating rotating Mandelbrot...")

function mandelbrot_rotated(px, py, angle)
    # Map and rotate
    x0 = px * 3.5 - 2.5
    y0 = py * 3.0 - 1.5
    
    # Rotate around (-0.5, 0)
    cx, cy = -0.5, 0.0
    x0r = (x0 - cx) * cos(angle) - (y0 - cy) * sin(angle) + cx
    y0r = (x0 - cx) * sin(angle) + (y0 - cy) * cos(angle) + cy
    
    x, y = 0.0, 0.0
    iter = 0
    max_iter = 80
    
    while x*x + y*y <= 4 && iter < max_iter
        x, y = x*x - y*y + x0r, 2*x*y + y0r
        iter += 1
    end
    
    iter == max_iter ? 0.1 : 0.5 + 0.4 * (iter / max_iter)
end

rotate_frames = Array{Real,2}[]
n_rotate = 60

for i in 0:n_rotate-1
    angle = 2π * i / n_rotate
    
    # Create fresh for each angle
    empty!(Ω.children)
    empty!(CACHE)
    
    create("mandelbrot_rot",
        T[1//2, 1//2],
        T[1//2, 1//2],
        T[0, 1],
        ω -> begin
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            mandelbrot_rotated(px, py, angle)
        end
    )
    
    screen = Peripheral{T}(
        "rot",
        Dict{T,T}(),
        T[0, 1],
        [100, 100],
        T[1//2, 1//2],
        T[1//2, 1//2]
    )
    
    push!(rotate_frames, render(screen))
    print(".")
end
println()

to_gif(rotate_frames, "mandelbrot_rotate.gif", scale=3, delay=5)
println("✓ Saved mandelbrot_rotate.gif")

# ============================================================
# PULSING JULIA SET - single interesting c, zoom in/out
# ============================================================

println("\nCreating pulsing Julia set...")

function julia(px, py, c_re, c_im, max_iter)
    x = px * 3.0 - 1.5
    y = py * 3.0 - 1.5
    
    iter = 0
    while x*x + y*y <= 4 && iter < max_iter
        x, y = x*x - y*y + c_re, 2*x*y + c_im
        iter += 1
    end
    
    iter == max_iter ? 0.1 : 0.5 + 0.45 * (iter / max_iter)
end

pulse_frames = Array{Real,2}[]
n_pulse = 40

# Beautiful Julia set at c = -0.7269 + 0.1889i
c_re, c_im = -0.7269, 0.1889

for i in 0:n_pulse-1
    # Pulse: zoom in then out
    t = i / n_pulse
    scale = 0.3 + 0.2 * sin(2π * t)
    scale_r = T(round(Int, scale * 1000)) // 1000
    
    empty!(Ω.children)
    empty!(CACHE)
    
    create("julia",
        T[1//2, 1//2],
        T[1//2, 1//2],
        T[0, 1],
        ω -> begin
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            julia(px, py, c_re, c_im, 80)
        end
    )
    
    screen = Peripheral{T}(
        "pulse",
        Dict{T,T}(),
        T[0, 1],
        [100, 100],
        T[1//2, 1//2],
        T[scale_r, scale_r]
    )
    
    push!(pulse_frames, render(screen))
    print(".")
end
println()

to_gif(pulse_frames, "julia_pulse.gif", scale=3, delay=5)
println("✓ Saved julia_pulse.gif")

# ============================================================
# MORPHING JULIA - smoothly change c parameter
# ============================================================

println("\nCreating morphing Julia set...")

morph_frames = Array{Real,2}[]
n_morph = 60

# Trace a path through interesting c values
for i in 0:n_morph-1
    t = i / n_morph
    
    # Trace a circle in c-space that hits interesting Julia sets
    angle = 2π * t
    radius = 0.7885
    c_re = radius * cos(angle)
    c_im = radius * sin(angle)
    
    empty!(Ω.children)
    empty!(CACHE)
    
    create("julia_morph",
        T[1//2, 1//2],
        T[1//2, 1//2],
        T[0, 1],
        ω -> begin
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            julia(px, py, c_re, c_im, 60)
        end
    )
    
    screen = Peripheral{T}(
        "morph",
        Dict{T,T}(),
        T[0, 1],
        [100, 100],
        T[1//2, 1//2],
        T[2//5, 2//5]
    )
    
    push!(morph_frames, render(screen))
    print(".")
end
println()

to_gif(morph_frames, "julia_morph.gif", scale=3, delay=5)
println("✓ Saved julia_morph.gif")

# ============================================================
println("\n" * "="^50)
println("All animations generated!")
println("="^50)
println("""
Files:
  - mandelbrot_zoom2.gif  : Zoom into seahorse valley
  - mandelbrot_rotate.gif : Mandelbrot rotating
  - julia_pulse.gif       : Julia set breathing (zoom in/out)
  - julia_morph.gif       : Julia set morphing (c rotates)
""")

# Something World - End-to-End Demo
# Include the core library first
# include("something.jl")

using Printf

# ============================================================
# PERIPHERALS - Projections from n-dim to observable screens
# ============================================================

"""
A Peripheral projects from the infinite-dimensional existence field
onto an observable output (2D screen, 3D volume, audio, etc.)

- observer_position: Dict{T,T} - where the observer is in Ω
- view_dims: which dimensions to project onto screen axes
- screen_resolution: pixels per view dimension
- screen_origin: center of view in each view_dim
- screen_radius: half-width of view in each view_dim
"""
struct Peripheral{T<:Real}
    name::String
    observer_position::Dict{T,T}  # fixed coordinates in non-view dims
    view_dims::Vector{T}          # dims that map to screen axes
    screen_resolution::Vector{Int}
    screen_origin::Vector{T}      # center of view
    screen_radius::Vector{T}      # zoom level
end

"""
Create a 2D screen peripheral.
"""
function Screen2D(T::Type{<:Real}, name::String;
                  observer=nothing,
                  x_dim=nothing, y_dim=nothing,
                  resolution::Tuple{Int,Int}=(64, 64),
                  origin=nothing,
                  radius=nothing)
    obs = observer === nothing ? Dict{T,T}() : observer
    xd = x_dim === nothing ? T(0) : x_dim
    yd = y_dim === nothing ? T(1) : y_dim
    org = origin === nothing ? (T(1//2), T(1//2)) : origin
    rad = radius === nothing ? (T(1//4), T(1//4)) : radius
    Peripheral{T}(
        name,
        obs,
        T[xd, yd],
        [resolution...],
        T[org...],
        T[rad...]
    )
end

"""
Render the view through a peripheral, returning a 2D array of existence values.
"""
function render(p::Peripheral{T}, S::Something{T}=Ω) where {T<:Real}
    # Build grid from peripheral spec
    g = Grid{T}(p.view_dims, p.screen_origin, p.screen_radius, p.screen_resolution)
    
    # For each grid point, merge with observer position
    results = Dict{Vector{Int},Real}()
    for idx in grid_indices(g)
        ω = grid_to_coords(g, collect(idx))
        # Merge observer's fixed position with view coordinates
        for (d, v) in p.observer_position
            if d ∉ p.view_dims
                ω[d] = v
            end
        end
        ∃_val, _, _ = observe(ω, S)
        results[collect(idx)] = Real(∃_val)
    end
    
    grid_to_array(g, results)
end

"""
Convert existence array to ASCII art.
"""
function to_ascii(arr::Array{Real,2}; chars::String=" .:-=+*#%@")
    w, h = size(arr)
    lines = String[]
    for y in h:-1:1  # flip y for natural orientation
        line = ""
        for x in 1:w
            v = clamp(arr[x, y], 0, 1)
            idx = round(Int, v * (length(chars) - 1)) + 1
            line *= chars[idx]
        end
        push!(lines, line)
    end
    join(lines, "\n")
end

"""
Convert existence array to ANSI colored blocks.
"""
function to_ansi(arr::Array{Real,2})
    h, w = size(arr)
    lines = String[]
    for y in h:-1:1
        line = ""
        for x in 1:w
            v = clamp(arr[x, y], 0, 1)
            # Map to grayscale: 232-255 are grays in 256-color mode
            gray = round(Int, v * 23) + 232
            line *= "\e[48;5;$(gray)m  \e[0m"
        end
        push!(lines, line)
    end
    join(lines, "\n")
end

# ============================================================
# PNG/GIF OUTPUT
# ============================================================

"""
Write a minimal PNG file (grayscale, no compression).
Uses raw PNG format with no external dependencies.
"""
function to_png(arr::Array{Real,2}, filename::String; scale::Int=4)
    w, h = size(arr)
    sw, sh = w * scale, h * scale
    
    # PNG signature
    signature = UInt8[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    
    # CRC32 table
    crc_table = zeros(UInt32, 256)
    for i in 0:255
        c = UInt32(i)
        for _ in 1:8
            if (c & 1) != 0
                c = 0xedb88320 ⊻ (c >> 1)
            else
                c >>= 1
            end
        end
        crc_table[i + 1] = c
    end
    
    function crc32(data::Vector{UInt8})
        c = 0xffffffff
        for b in data
            c = crc_table[(c ⊻ b) & 0xff + 1] ⊻ (c >> 8)
        end
        c ⊻ 0xffffffff
    end
    
    function write_chunk(io, chunk_type::String, data::Vector{UInt8})
        len = UInt32(length(data))
        write(io, hton(len))
        type_bytes = Vector{UInt8}(chunk_type)
        write(io, type_bytes)
        write(io, data)
        crc_data = vcat(type_bytes, data)
        write(io, hton(crc32(crc_data)))
    end
    
    # IHDR chunk
    ihdr = IOBuffer()
    write(ihdr, hton(UInt32(sw)))  # width
    write(ihdr, hton(UInt32(sh)))  # height
    write(ihdr, UInt8(8))          # bit depth
    write(ihdr, UInt8(0))          # color type (grayscale)
    write(ihdr, UInt8(0))          # compression
    write(ihdr, UInt8(0))          # filter
    write(ihdr, UInt8(0))          # interlace
    ihdr_data = take!(ihdr)
    
    # Image data (uncompressed via zlib stored block)
    raw_data = IOBuffer()
    for y in sh:-1:1  # flip y
        write(raw_data, UInt8(0))  # filter type: none
        for x in 1:sw
            ox, oy = div(x - 1, scale) + 1, div(y - 1, scale) + 1
            v = clamp(arr[ox, oy], 0, 1)
            gray = round(UInt8, v * 255)
            write(raw_data, gray)
        end
    end
    raw_bytes = take!(raw_data)
    
    # Wrap in zlib format (stored blocks, no compression)
    zlib_data = IOBuffer()
    write(zlib_data, UInt8(0x78), UInt8(0x01))  # zlib header (no compression)
    
    # Split into 65535-byte blocks
    pos = 1
    while pos <= length(raw_bytes)
        block_end = min(pos + 65534, length(raw_bytes))
        block = raw_bytes[pos:block_end]
        is_final = block_end >= length(raw_bytes)
        write(zlib_data, UInt8(is_final ? 0x01 : 0x00))  # final flag
        len = UInt16(length(block))
        write(zlib_data, len)           # length (little endian)
        write(zlib_data, ~len)          # one's complement
        write(zlib_data, block)
        pos = block_end + 1
    end
    
    # Adler-32 checksum
    a, b = UInt32(1), UInt32(0)
    for byte in raw_bytes
        a = (a + byte) % 65521
        b = (b + a) % 65521
    end
    adler = (b << 16) | a
    write(zlib_data, hton(adler))
    
    idat_data = take!(zlib_data)
    
    # Write PNG file
    open(filename, "w") do io
        write(io, signature)
        write_chunk(io, "IHDR", ihdr_data)
        write_chunk(io, "IDAT", idat_data)
        write_chunk(io, "IEND", UInt8[])
    end
    
    filename
end

"""
Create an animated GIF from multiple frames.
"""
function to_gif(frames::Vector{<:Array{Real,2}}, filename::String; 
                scale::Int=4, delay::Int=20)
    if isempty(frames)
        error("No frames provided")
    end
    
    w, h = size(frames[1])
    sw, sh = w * scale, h * scale
    
    open(filename, "w") do io
        # GIF89a header
        write(io, "GIF89a")
        
        # Logical screen descriptor
        write(io, UInt16(sw))  # width (little endian)
        write(io, UInt16(sh))  # height
        write(io, UInt8(0xF7)) # global color table, 8 bits, 256 colors
        write(io, UInt8(0))    # background color index
        write(io, UInt8(0))    # pixel aspect ratio
        
        # Global color table (256 grays)
        for i in 0:255
            write(io, UInt8(i), UInt8(i), UInt8(i))
        end
        
        # Netscape extension for looping
        write(io, UInt8(0x21), UInt8(0xFF), UInt8(0x0B))
        write(io, "NETSCAPE2.0")
        write(io, UInt8(0x03), UInt8(0x01))
        write(io, UInt16(0))  # loop forever
        write(io, UInt8(0))   # block terminator
        
        for arr in frames
            # Graphics control extension (for delay)
            write(io, UInt8(0x21), UInt8(0xF9), UInt8(0x04))
            write(io, UInt8(0x00))        # no transparency
            write(io, UInt16(delay))      # delay in 1/100 sec
            write(io, UInt8(0), UInt8(0)) # transparent color, terminator
            
            # Image descriptor
            write(io, UInt8(0x2C))
            write(io, UInt16(0), UInt16(0))  # left, top
            write(io, UInt16(sw), UInt16(sh)) # width, height
            write(io, UInt8(0))               # no local color table
            
            # LZW compressed image data
            min_code_size = 8
            write(io, UInt8(min_code_size))
            
            # Simple LZW encoding
            pixels = UInt8[]
            for y in 1:sh
                for x in 1:sw
                    ox, oy = div(x - 1, scale) + 1, div(y - 1, scale) + 1
                    v = clamp(arr[ox, oy], 0, 1)
                    push!(pixels, round(UInt8, v * 255))
                end
            end
            
            # LZW encode
            clear_code = 256
            eoi_code = 257
            
            codes = Int[]
            push!(codes, clear_code)
            
            dict = Dict{Vector{UInt8}, Int}()
            for i in 0:255
                dict[UInt8[i]] = i
            end
            next_code = 258
            code_size = 9
            
            buffer = UInt8[]
            for pixel in pixels
                test = vcat(buffer, pixel)
                if haskey(dict, test)
                    buffer = test
                else
                    push!(codes, dict[buffer])
                    if next_code < 4096
                        dict[test] = next_code
                        next_code += 1
                        if next_code > (1 << code_size) && code_size < 12
                            code_size += 1
                        end
                    else
                        push!(codes, clear_code)
                        dict = Dict{Vector{UInt8}, Int}()
                        for i in 0:255
                            dict[UInt8[i]] = i
                        end
                        next_code = 258
                        code_size = 9
                    end
                    buffer = UInt8[pixel]
                end
            end
            if !isempty(buffer)
                push!(codes, dict[buffer])
            end
            push!(codes, eoi_code)
            
            # Pack codes into bytes
            bit_buffer = UInt64(0)
            bits_in_buffer = 0
            output_bytes = UInt8[]
            current_code_size = 9
            codes_written = 0
            
            for code in codes
                if code == clear_code
                    current_code_size = 9
                end
                bit_buffer |= UInt64(code) << bits_in_buffer
                bits_in_buffer += current_code_size
                while bits_in_buffer >= 8
                    push!(output_bytes, UInt8(bit_buffer & 0xFF))
                    bit_buffer >>= 8
                    bits_in_buffer -= 8
                end
                codes_written += 1
                if codes_written >= (1 << current_code_size) - 1 && current_code_size < 12
                    current_code_size += 1
                end
            end
            if bits_in_buffer > 0
                push!(output_bytes, UInt8(bit_buffer & 0xFF))
            end
            
            # Write in sub-blocks (max 255 bytes each)
            pos = 1
            while pos <= length(output_bytes)
                block_size = min(255, length(output_bytes) - pos + 1)
                write(io, UInt8(block_size))
                write(io, output_bytes[pos:pos+block_size-1])
                pos += block_size
            end
            write(io, UInt8(0))  # block terminator
        end
        
        # GIF trailer
        write(io, UInt8(0x3B))
    end
    
    filename
end

"""
Render multiple time slices as frames for animation.
"""
function render_animation(p::Peripheral{T}, time_dim::T, time_values::Vector{T}, 
                          S::Something{T}=Ω) where {T<:Real}
    frames = Array{Real,2}[]
    for t in time_values
        # Set time in observer position
        obs = copy(p.observer_position)
        obs[time_dim] = t
        p_frame = Peripheral{T}(p.name, obs, p.view_dims, p.screen_resolution, 
                                 p.screen_origin, p.screen_radius)
        empty!(CACHE)
        push!(frames, render(p_frame, S))
    end
    frames
end

# ============================================================
# DEMO 1: Static 2D Art - A Circle
# ============================================================

println("\n" * "="^60)
println("DEMO 1: Static Circle in 2D")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create a circular region: existence = 1 inside, fades at edge
    # Circle at center (1/2, 1/2), radius 1/5 in dims 0,1
    circle = create("circle", 
        T[1//2, 1//2],           # origin
        T[1//5, 1//5],           # radius
        T[0, 1],                 # dims x, y
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r_max = 0.2
            r < r_max * 0.8 ? 1.0 : 0.5  # solid inside, ORIGIN at boundary
        end
    )
    
    # Create peripheral: 2D screen looking at x,y
    screen = Screen2D(T, "main_view",
        resolution=(32, 32),
        origin=(T(1//2), T(1//2)),
        radius=(T(1//3), T(1//3))
    )
    
    img = render(screen)
    println("\nCircle (existence = 1.0 inside, 0.5 outside):")
    println(to_ascii(img))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 2: Nested Structures - Ball with Hidden Room
# ============================================================

println("\n" * "="^60)
println("DEMO 2: Bowling Ball with Hidden Jacuzzi")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # The bowling ball: visible in dims 0,1 (x,y)
    # Solid existence = 0.9
    ball = create("bowling_ball",
        T[1//2, 1//2],
        T[1//5, 1//5],
        T[0, 1],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.15 ? 0.9 : 0.5  # dark solid ball
        end
    )
    
    # The hidden jacuzzi: same x,y center, but shifted in dim 2 (z)
    # z = 0.75 with radius 0.1 means bounds [0.65, 0.85] - excludes ORIGIN (0.5)
    jacuzzi = create("jacuzzi",
        T[1//2, 1//2, 3//4],     # same x,y but z=0.75
        T[1//10, 1//10, 1//10],  # radius 0.1 in z: [0.65, 0.85]
        T[0, 1, 2],              # lives in x,y,z
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.08 ? 1.0 : 0.5  # bright jacuzzi!
        end
    )
    
    println("Ball created: ", ball !== nothing)
    println("Jacuzzi created: ", jacuzzi !== nothing)
    
    # Observer 1: Normal view (z = 0.5 = ORIGIN)
    # Can only see the bowling ball
    screen_normal = Peripheral{T}(
        "normal_observer",
        Dict{T,T}(T(2) => T(1//2)),  # z at ORIGIN
        T[0, 1],
        [32, 32],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    # Observer 2: Secret view (z = 0.75)
    # Can see the jacuzzi!
    screen_secret = Peripheral{T}(
        "secret_observer",
        Dict{T,T}(T(2) => T(3//4)),  # z at 0.75
        T[0, 1],
        [32, 32],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    println("\nNormal view (z=0.5) - just the bowling ball:")
    img_normal = render(screen_normal)
    println(to_ascii(img_normal))
    
    println("\nSecret view (z=0.75) - the hidden jacuzzi inside!")
    empty!(CACHE)
    img_secret = render(screen_secret)
    println(to_ascii(img_secret))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 3: Time Dimension - Animation
# ============================================================

println("\n" * "="^60)
println("DEMO 3: Moving Ball (time dimension)")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # A ball that moves in x as t increases
    # At t=0.3: ball at x=0.3
    # At t=0.5: ball at x=0.5
    # At t=0.7: ball at x=0.7
    # The trick: ball's x-position is tied to t
    
    # We create multiple balls at different t-slices
    for (i, t) in enumerate([3//10, 4//10, 5//10, 6//10, 7//10])
        x_pos = t  # ball moves with time
        ball = create("ball_t$i",
            T[x_pos, 1//2, t],      # x follows t, y=center, t=specific
            T[1//20, 1//10, 1//100], # small in x,y, very thin in t
            T[0, 1, 2],             # dims: x, y, t
            _ -> 0.95
        )
    end
    
    println("\nFrames of animation (t = 0.3, 0.4, 0.5, 0.6, 0.7):\n")
    
    for t in [3//10, 4//10, 5//10, 6//10, 7//10]
        screen = Peripheral{T}(
            "frame_t=$t",
            Dict{T,T}(T(2) => T(t)),  # fix time
            T[0, 1],                   # view x,y
            [40, 16],
            T[1//2, 1//2],
            T[1//2, 1//4]
        )
        empty!(CACHE)
        img = render(screen)
        println("t = $t:")
        println(to_ascii(img, chars=" .o"))
        println()
    end
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 4: Different Physics - Gravity Subspace
# ============================================================

println("\n" * "="^60)
println("DEMO 4: Subspace with Different Physics")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create a "gravity zone" - existence increases downward (higher y = less existence)
    gravity_zone = create("gravity_zone",
        T[1//2, 1//2],
        T[2//5, 2//5],
        T[0, 1],
        ω -> begin
            y = Float64(get_dim(ω, T(1)))
            # Gravity: existence higher at bottom
            0.5 + 0.4 * (1.0 - y)  # varies from 0.9 at bottom to 0.5 at top
        end
    )
    
    # Create a "floating zone" inside - reversed physics!
    # Must be in different dim to be disjoint
    floating_zone = create("floating_zone",
        T[1//2, 1//2, 1//5],      # shift in z to be disjoint
        T[1//5, 1//5, 1//10],
        T[0, 1, 2],
        ω -> begin
            y = Float64(get_dim(ω, T(1)))
            # Anti-gravity: existence higher at top
            0.5 + 0.4 * y
        end
    )
    
    println("\nGravity zone (brighter at bottom, observer at z=0.5):")
    screen_gravity = Peripheral{T}(
        "gravity_view",
        Dict{T,T}(T(2) => T(1//2)),
        T[0, 1],
        [32, 16],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    img_gravity = render(screen_gravity)
    println(to_ascii(img_gravity))
    
    println("\nFloating zone (brighter at top, observer at z=0.2):")
    screen_floating = Peripheral{T}(
        "floating_view",
        Dict{T,T}(T(2) => T(1//5)),
        T[0, 1],
        [32, 16],
        T[1//2, 1//2],
        T[1//5, 1//5]
    )
    empty!(CACHE)
    img_floating = render(screen_floating)
    println(to_ascii(img_floating))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 5: God's Eye View - Observing from Different Angles
# ============================================================

println("\n" * "="^60)
println("DEMO 5: Same Structure, Different Projections")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create a 3D cross shape
    # Vertical bar in y
    create("cross_vertical",
        T[1//2, 1//2, 1//5],
        T[1//20, 1//5, 1//10],
        T[0, 1, 2],
        _ -> 0.9
    )
    
    # Horizontal bar in x
    create("cross_horizontal",
        T[1//2, 1//2, 3//10],    # different z to be disjoint
        T[1//5, 1//20, 1//10],
        T[0, 1, 2],
        _ -> 0.9
    )
    
    # View from front (x,y plane, z=0.2)
    println("\nFront view (x,y at z=0.2) - sees vertical bar:")
    screen_front = Peripheral{T}("front", Dict{T,T}(T(2) => T(1//5)), T[0, 1], [24, 24], T[1//2, 1//2], T[1//4, 1//4])
    println(to_ascii(render(screen_front)))
    
    # View at z=0.3 - sees horizontal bar
    println("\nFront view (x,y at z=0.3) - sees horizontal bar:")
    empty!(CACHE)
    screen_front2 = Peripheral{T}("front2", Dict{T,T}(T(2) => T(3//10)), T[0, 1], [24, 24], T[1//2, 1//2], T[1//4, 1//4])
    println(to_ascii(render(screen_front2)))
    
    # Side view (y,z plane, x=0.5)
    println("\nSide view (y,z at x=0.5) - sees both bars as dots:")
    empty!(CACHE)
    screen_side = Peripheral{T}("side", Dict{T,T}(T(0) => T(1//2)), T[1, 2], [24, 24], T[1//2, 1//4], T[1//4, 1//6])
    println(to_ascii(render(screen_side)))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 6: The Multiverse - Same Location, Different Dimensions
# ============================================================

println("\n" * "="^60)
println("DEMO 6: Parallel Worlds at Same x,y")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # World 1: A house (at dimension 3 = 0.2)
    create("house_floor",
        T[1//2, 3//10, 1//5],
        T[1//5, 1//20, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    create("house_roof",
        T[1//2, 13//20, 3//10],   # different dim 3 to be disjoint
        T[1//6, 1//10, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    
    # World 2: An ocean (at dimension 3 = 0.8)
    create("ocean",
        T[1//2, 3//10, 4//5],
        T[2//5, 1//10, 1//10],
        T[0, 1, 3],
        ω -> begin
            x = Float64(get_dim(ω, T(0)))
            0.6 + 0.1 * sin(x * 20)  # waves
        end
    )
    
    # God at dimension 3 = 0.2 sees a house
    println("\nWorld 1 (dim3=0.2) - The House:")
    screen_house = Peripheral{T}("house_world", Dict{T,T}(T(3) => T(1//5)), T[0, 1], [32, 20], T[1//2, 1//2], T[1//3, 1//3])
    println(to_ascii(render(screen_house)))
    
    # God at dimension 3 = 0.8 sees an ocean
    println("\nWorld 2 (dim3=0.8) - The Ocean:")
    empty!(CACHE)
    screen_ocean = Peripheral{T}("ocean_world", Dict{T,T}(T(3) => T(4//5)), T[0, 1], [32, 20], T[1//2, 1//2], T[1//3, 1//3])
    println(to_ascii(render(screen_ocean)))
    
    println("\nSame x,y coordinates, completely different realities!")
    println("Move in dimension 3 to travel between worlds.")
    
    empty!(Ω.children)
end

# ============================================================
println("\n" * "="^60)
println("END OF ASCII DEMOS")
println("="^60)

# ============================================================
# IMAGE OUTPUT DEMOS
# ============================================================

println("\n" * "="^60)
println("GENERATING PNG AND GIF FILES")
println("="^60)

# Demo: Circle as PNG
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    circle = create("circle", 
        T[1//2, 1//2],
        T[1//5, 1//5],
        T[0, 1],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r_max = 0.2
            r < r_max * 0.8 ? 1.0 : 0.5
        end
    )
    
    screen = Screen2D(T, "circle_view",
        resolution=(64, 64),
        origin=(T(1//2), T(1//2)),
        radius=(T(1//3), T(1//3))
    )
    
    img = render(screen)
    to_png(img, "circle.png", scale=4)
    println("✓ Saved circle.png")
    
    empty!(Ω.children)
end

# Demo: Bowling ball and jacuzzi as PNGs
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    ball = create("bowling_ball",
        T[1//2, 1//2],
        T[1//5, 1//5],
        T[0, 1],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.15 ? 0.9 : 0.5
        end
    )
    
    jacuzzi = create("jacuzzi",
        T[1//2, 1//2, 3//4],
        T[1//10, 1//10, 1//10],
        T[0, 1, 2],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.08 ? 1.0 : 0.5
        end
    )
    
    println("Ball created: ", ball !== nothing)
    println("Jacuzzi created: ", jacuzzi !== nothing)
    if jacuzzi !== nothing
        println("Jacuzzi parent: ", jacuzzi.parent.name)
    end
    
    # Normal view
    screen_normal = Peripheral{T}(
        "normal_observer",
        Dict{T,T}(T(2) => T(1//2)),
        T[0, 1],
        [64, 64],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    img_normal = render(screen_normal)
    to_png(img_normal, "ball_normal.png", scale=4)
    println("✓ Saved ball_normal.png (z=0.5, sees ball)")
    
    # Secret view
    screen_secret = Peripheral{T}(
        "secret_observer",
        Dict{T,T}(T(2) => T(3//4)),
        T[0, 1],
        [64, 64],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    empty!(CACHE)
    img_secret = render(screen_secret)
    to_png(img_secret, "ball_secret.png", scale=4)
    println("✓ Saved ball_secret.png (z=0.75, sees jacuzzi)")
    
    empty!(Ω.children)
end

# Demo: Animated moving ball as GIF
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create balls at different time slices
    for (i, t) in enumerate([2//10, 3//10, 4//10, 5//10, 6//10, 7//10, 8//10])
        x_pos = t
        create("ball_t$i",
            T[x_pos, 1//2, t],
            T[1//20, 1//10, 1//100],
            T[0, 1, 2],
            _ -> 1.0
        )
    end
    
    # Render animation
    screen = Peripheral{T}(
        "animation",
        Dict{T,T}(),
        T[0, 1],
        [64, 32],
        T[1//2, 1//2],
        T[1//2, 1//4]
    )
    
    time_values = T[2//10, 3//10, 4//10, 5//10, 6//10, 7//10, 8//10]
    frames = render_animation(screen, T(2), time_values)
    
    to_gif(frames, "moving_ball.gif", scale=4, delay=15)
    println("✓ Saved moving_ball.gif")
    
    empty!(Ω.children)
end

# Demo: Parallel worlds as PNGs
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # World 1: House
    create("house_floor",
        T[1//2, 3//10, 1//5],
        T[1//5, 1//20, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    create("house_roof",
        T[1//2, 13//20, 3//10],
        T[1//6, 1//10, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    
    # World 2: Ocean with waves
    create("ocean",
        T[1//2, 3//10, 4//5],
        T[2//5, 1//10, 1//10],
        T[0, 1, 3],
        ω -> begin
            x = Float64(get_dim(ω, T(0)))
            0.6 + 0.3 * sin(x * 30)
        end
    )
    
    # House world
    screen_house = Peripheral{T}("house", Dict{T,T}(T(3) => T(1//5)), T[0, 1], 
                                  [64, 48], T[1//2, 1//2], T[1//3, 1//3])
    img_house = render(screen_house)
    to_png(img_house, "world_house.png", scale=4)
    println("✓ Saved world_house.png (dim3=0.2)")
    
    # Ocean world
    empty!(CACHE)
    screen_ocean = Peripheral{T}("ocean", Dict{T,T}(T(3) => T(4//5)), T[0, 1],
                                  [64, 48], T[1//2, 1//2], T[1//3, 1//3])
    img_ocean = render(screen_ocean)
    to_png(img_ocean, "world_ocean.png", scale=4)
    println("✓ Saved world_ocean.png (dim3=0.8)")
    
    empty!(Ω.children)
end

# Demo: Pulsing object (animated)
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create pulsing circles at different times
    for (i, t) in enumerate(0:1//20:19//20)
        # Radius varies with time: oscillates between 0.05 and 0.15
        phase = Float64(t) * 2 * π
        r = 0.1 + 0.05 * sin(phase * 2)
        
        create("pulse_t$i",
            T[1//2, 1//2, t],
            T[Rational{BigInt}(r), Rational{BigInt}(r), 1//100],
            T[0, 1, 2],
            _ -> 0.9
        )
    end
    
    screen = Peripheral{T}(
        "pulse",
        Dict{T,T}(),
        T[0, 1],
        [64, 64],
        T[1//2, 1//2],
        T[1//4, 1//4]
    )
    
    time_values = collect(T(0):T(1//20):T(19//20))
    frames = render_animation(screen, T(2), time_values)
    
    to_gif(frames, "pulsing.gif", scale=4, delay=5)
    println("✓ Saved pulsing.gif")
    
    empty!(Ω.children)
end

println("\n" * "="^60)
println("ALL FILES GENERATED")
println("="^60)
println("""

Generated files:
  - circle.png         : Static circle
  - ball_normal.png    : Bowling ball (normal view)
  - ball_secret.png    : Hidden jacuzzi inside ball
  - moving_ball.gif    : Ball moving through time
  - world_house.png    : House in dimension 3 = 0.2
  - world_ocean.png    : Ocean in dimension 3 = 0.8
  - pulsing.gif        : Pulsing circle animation

""")


# Something World - End-to-End Demo
# Include the core library first
# include("something.jl")

using Printf

# ============================================================
# PERIPHERALS - Projections from n-dim to observable screens
# ============================================================

"""
A Peripheral projects from the infinite-dimensional existence field
onto an observable output (2D screen, 3D volume, audio, etc.)

- observer_position: Dict{T,T} - where the observer is in Ω
- view_dims: which dimensions to project onto screen axes
- screen_resolution: pixels per view dimension
- screen_origin: center of view in each view_dim
- screen_radius: half-width of view in each view_dim
"""
struct Peripheral{T<:Real}
    name::String
    observer_position::Dict{T,T}  # fixed coordinates in non-view dims
    view_dims::Vector{T}          # dims that map to screen axes
    screen_resolution::Vector{Int}
    screen_origin::Vector{T}      # center of view
    screen_radius::Vector{T}      # zoom level
end

"""
Create a 2D screen peripheral.
"""
function Screen2D(T::Type{<:Real}, name::String;
                  observer=nothing,
                  x_dim=nothing, y_dim=nothing,
                  resolution::Tuple{Int,Int}=(64, 64),
                  origin=nothing,
                  radius=nothing)
    obs = observer === nothing ? Dict{T,T}() : observer
    xd = x_dim === nothing ? T(0) : x_dim
    yd = y_dim === nothing ? T(1) : y_dim
    org = origin === nothing ? (T(1//2), T(1//2)) : origin
    rad = radius === nothing ? (T(1//4), T(1//4)) : radius
    Peripheral{T}(
        name,
        obs,
        T[xd, yd],
        [resolution...],
        T[org...],
        T[rad...]
    )
end

"""
Render the view through a peripheral, returning a 2D array of existence values.
"""
function render(p::Peripheral{T}, S::Something{T}=Ω) where {T<:Real}
    # Build grid from peripheral spec
    g = Grid{T}(p.view_dims, p.screen_origin, p.screen_radius, p.screen_resolution)
    
    # For each grid point, merge with observer position
    results = Dict{Vector{Int},Real}()
    for idx in grid_indices(g)
        ω = grid_to_coords(g, collect(idx))
        # Merge observer's fixed position with view coordinates
        for (d, v) in p.observer_position
            if d ∉ p.view_dims
                ω[d] = v
            end
        end
        ∃_val, _, _ = observe(ω, S)
        results[collect(idx)] = Real(∃_val)
    end
    
    grid_to_array(g, results)
end

"""
Convert existence array to ASCII art.
"""
function to_ascii(arr::Array{Real,2}; chars::String=" .:-=+*#%@")
    w, h = size(arr)
    lines = String[]
    for y in h:-1:1  # flip y for natural orientation
        line = ""
        for x in 1:w
            v = clamp(arr[x, y], 0, 1)
            idx = round(Int, v * (length(chars) - 1)) + 1
            line *= chars[idx]
        end
        push!(lines, line)
    end
    join(lines, "\n")
end

"""
Convert existence array to ANSI colored blocks.
"""
function to_ansi(arr::Array{Real,2})
    h, w = size(arr)
    lines = String[]
    for y in h:-1:1
        line = ""
        for x in 1:w
            v = clamp(arr[x, y], 0, 1)
            # Map to grayscale: 232-255 are grays in 256-color mode
            gray = round(Int, v * 23) + 232
            line *= "\e[48;5;$(gray)m  \e[0m"
        end
        push!(lines, line)
    end
    join(lines, "\n")
end

# ============================================================
# PNG/GIF OUTPUT
# ============================================================

"""
Write a minimal PNG file (grayscale, no compression).
Uses raw PNG format with no external dependencies.
"""
function to_png(arr::Array{Real,2}, filename::String; scale::Int=4)
    w, h = size(arr)
    sw, sh = w * scale, h * scale
    
    # PNG signature
    signature = UInt8[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    
    # CRC32 table
    crc_table = zeros(UInt32, 256)
    for i in 0:255
        c = UInt32(i)
        for _ in 1:8
            if (c & 1) != 0
                c = 0xedb88320 ⊻ (c >> 1)
            else
                c >>= 1
            end
        end
        crc_table[i + 1] = c
    end
    
    function crc32(data::Vector{UInt8})
        c = 0xffffffff
        for b in data
            c = crc_table[(c ⊻ b) & 0xff + 1] ⊻ (c >> 8)
        end
        c ⊻ 0xffffffff
    end
    
    function write_chunk(io, chunk_type::String, data::Vector{UInt8})
        len = UInt32(length(data))
        write(io, hton(len))
        type_bytes = Vector{UInt8}(chunk_type)
        write(io, type_bytes)
        write(io, data)
        crc_data = vcat(type_bytes, data)
        write(io, hton(crc32(crc_data)))
    end
    
    # IHDR chunk
    ihdr = IOBuffer()
    write(ihdr, hton(UInt32(sw)))  # width
    write(ihdr, hton(UInt32(sh)))  # height
    write(ihdr, UInt8(8))          # bit depth
    write(ihdr, UInt8(0))          # color type (grayscale)
    write(ihdr, UInt8(0))          # compression
    write(ihdr, UInt8(0))          # filter
    write(ihdr, UInt8(0))          # interlace
    ihdr_data = take!(ihdr)
    
    # Image data (uncompressed via zlib stored block)
    raw_data = IOBuffer()
    for y in sh:-1:1  # flip y
        write(raw_data, UInt8(0))  # filter type: none
        for x in 1:sw
            ox, oy = div(x - 1, scale) + 1, div(y - 1, scale) + 1
            v = clamp(arr[ox, oy], 0, 1)
            gray = round(UInt8, v * 255)
            write(raw_data, gray)
        end
    end
    raw_bytes = take!(raw_data)
    
    # Wrap in zlib format (stored blocks, no compression)
    zlib_data = IOBuffer()
    write(zlib_data, UInt8(0x78), UInt8(0x01))  # zlib header (no compression)
    
    # Split into 65535-byte blocks
    pos = 1
    while pos <= length(raw_bytes)
        block_end = min(pos + 65534, length(raw_bytes))
        block = raw_bytes[pos:block_end]
        is_final = block_end >= length(raw_bytes)
        write(zlib_data, UInt8(is_final ? 0x01 : 0x00))  # final flag
        len = UInt16(length(block))
        write(zlib_data, len)           # length (little endian)
        write(zlib_data, ~len)          # one's complement
        write(zlib_data, block)
        pos = block_end + 1
    end
    
    # Adler-32 checksum
    a, b = UInt32(1), UInt32(0)
    for byte in raw_bytes
        a = (a + byte) % 65521
        b = (b + a) % 65521
    end
    adler = (b << 16) | a
    write(zlib_data, hton(adler))
    
    idat_data = take!(zlib_data)
    
    # Write PNG file
    open(filename, "w") do io
        write(io, signature)
        write_chunk(io, "IHDR", ihdr_data)
        write_chunk(io, "IDAT", idat_data)
        write_chunk(io, "IEND", UInt8[])
    end
    
    filename
end

"""
Create an animated GIF from multiple frames.
Uses minimal LZW (no compression, just literal codes).
"""
function to_gif(frames::Vector{<:Array{Real,2}}, filename::String; 
                scale::Int=4, delay::Int=20)
    if isempty(frames)
        error("No frames provided")
    end
    
    w, h = size(frames[1])
    sw, sh = w * scale, h * scale
    
    open(filename, "w") do io
        # GIF89a header
        write(io, "GIF89a")
        
        # Logical screen descriptor
        write(io, UInt16(sw))  # width (little endian)
        write(io, UInt16(sh))  # height
        write(io, UInt8(0xF7)) # global color table, 8 bits, 256 colors
        write(io, UInt8(0))    # background color index
        write(io, UInt8(0))    # pixel aspect ratio
        
        # Global color table (256 grays)
        for i in 0:255
            write(io, UInt8(i), UInt8(i), UInt8(i))
        end
        
        # Netscape extension for looping
        write(io, UInt8(0x21), UInt8(0xFF), UInt8(0x0B))
        write(io, "NETSCAPE2.0")
        write(io, UInt8(0x03), UInt8(0x01))
        write(io, UInt16(0))  # loop forever
        write(io, UInt8(0))   # block terminator
        
        for arr in frames
            # Graphics control extension (for delay)
            write(io, UInt8(0x21), UInt8(0xF9), UInt8(0x04))
            write(io, UInt8(0x00))        # no transparency
            write(io, UInt16(delay))      # delay in 1/100 sec
            write(io, UInt8(0), UInt8(0)) # transparent color, terminator
            
            # Image descriptor
            write(io, UInt8(0x2C))
            write(io, UInt16(0), UInt16(0))  # left, top
            write(io, UInt16(sw), UInt16(sh)) # width, height
            write(io, UInt8(0))               # no local color table
            
            # LZW minimum code size
            min_code_size = 8
            write(io, UInt8(min_code_size))
            
            # Build pixel data
            pixels = UInt8[]
            for y in 1:sh
                for x in 1:sw
                    ox = div(x - 1, scale) + 1
                    oy = div(y - 1, scale) + 1
                    v = clamp(arr[ox, oy], 0, 1)
                    push!(pixels, round(UInt8, v * 255))
                end
            end
            
            # Simple LZW encoding with frequent clears to avoid complexity
            clear_code = 256
            eoi_code = 257
            
            output_bytes = UInt8[]
            bit_buffer = UInt32(0)
            bits_in_buffer = 0
            code_size = 9
            
            function emit_code(code)
                bit_buffer |= UInt32(code) << bits_in_buffer
                bits_in_buffer += code_size
                while bits_in_buffer >= 8
                    push!(output_bytes, UInt8(bit_buffer & 0xFF))
                    bit_buffer >>= 8
                    bits_in_buffer -= 8
                end
            end
            
            emit_code(clear_code)
            
            # Emit pixels with periodic clears (simple, no dictionary building)
            count = 0
            for pixel in pixels
                emit_code(Int(pixel))
                count += 1
                if count >= 100  # clear frequently to keep code_size at 9
                    emit_code(clear_code)
                    count = 0
                end
            end
            
            emit_code(eoi_code)
            
            # Flush remaining bits
            if bits_in_buffer > 0
                push!(output_bytes, UInt8(bit_buffer & 0xFF))
            end
            
            # Write in sub-blocks (max 255 bytes each)
            pos = 1
            while pos <= length(output_bytes)
                block_size = min(255, length(output_bytes) - pos + 1)
                write(io, UInt8(block_size))
                write(io, output_bytes[pos:pos+block_size-1])
                pos += block_size
            end
            write(io, UInt8(0))  # block terminator
        end
        
        # GIF trailer
        write(io, UInt8(0x3B))
    end
    
    filename
end

"""
Render multiple time slices as frames for animation.
"""
function render_animation(p::Peripheral{T}, time_dim::T, time_values::Vector{T}, 
                          S::Something{T}=Ω) where {T<:Real}
    frames = Array{Real,2}[]
    for t in time_values
        # Set time in observer position
        obs = copy(p.observer_position)
        obs[time_dim] = t
        p_frame = Peripheral{T}(p.name, obs, p.view_dims, p.screen_resolution, 
                                 p.screen_origin, p.screen_radius)
        empty!(CACHE)
        push!(frames, render(p_frame, S))
    end
    frames
end

# ============================================================
# DEMO 1: Static 2D Art - A Circle
# ============================================================

println("\n" * "="^60)
println("DEMO 1: Static Circle in 2D")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create a circular region: existence = 1 inside, fades at edge
    # Circle at center (1/2, 1/2), radius 1/5 in dims 0,1
    circle = create("circle", 
        T[1//2, 1//2],           # origin
        T[1//5, 1//5],           # radius
        T[0, 1],                 # dims x, y
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r_max = 0.2
            r < r_max * 0.8 ? 1.0 : 0.5  # solid inside, ORIGIN at boundary
        end
    )
    
    # Create peripheral: 2D screen looking at x,y
    screen = Screen2D(T, "main_view",
        resolution=(32, 32),
        origin=(T(1//2), T(1//2)),
        radius=(T(1//3), T(1//3))
    )
    
    img = render(screen)
    println("\nCircle (existence = 1.0 inside, 0.5 outside):")
    println(to_ascii(img))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 2: Nested Structures - Ball with Hidden Room
# ============================================================

println("\n" * "="^60)
println("DEMO 2: Bowling Ball with Hidden Jacuzzi")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # The bowling ball: visible in dims 0,1 (x,y)
    # Solid existence = 0.9
    ball = create("bowling_ball",
        T[1//2, 1//2],
        T[1//5, 1//5],
        T[0, 1],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.15 ? 0.9 : 0.5  # dark solid ball
        end
    )
    
    # The hidden jacuzzi: same x,y center, but shifted in dim 2 (z)
    # z = 0.75 with radius 0.1 means bounds [0.65, 0.85] - excludes ORIGIN (0.5)
    jacuzzi = create("jacuzzi",
        T[1//2, 1//2, 3//4],     # same x,y but z=0.75
        T[1//10, 1//10, 1//10],  # radius 0.1 in z: [0.65, 0.85]
        T[0, 1, 2],              # lives in x,y,z
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.08 ? 1.0 : 0.5  # bright jacuzzi!
        end
    )
    
    println("Ball created: ", ball !== nothing)
    println("Jacuzzi created: ", jacuzzi !== nothing)
    
    # Observer 1: Normal view (z = 0.5 = ORIGIN)
    # Can only see the bowling ball
    screen_normal = Peripheral{T}(
        "normal_observer",
        Dict{T,T}(T(2) => T(1//2)),  # z at ORIGIN
        T[0, 1],
        [32, 32],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    # Observer 2: Secret view (z = 0.75)
    # Can see the jacuzzi!
    screen_secret = Peripheral{T}(
        "secret_observer",
        Dict{T,T}(T(2) => T(3//4)),  # z at 0.75
        T[0, 1],
        [32, 32],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    println("\nNormal view (z=0.5) - just the bowling ball:")
    img_normal = render(screen_normal)
    println(to_ascii(img_normal))
    
    println("\nSecret view (z=0.75) - the hidden jacuzzi inside!")
    empty!(CACHE)
    img_secret = render(screen_secret)
    println(to_ascii(img_secret))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 3: Time Dimension - Animation
# ============================================================

println("\n" * "="^60)
println("DEMO 3: Moving Ball (time dimension)")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # A ball that moves in x as t increases
    # At t=0.3: ball at x=0.3
    # At t=0.5: ball at x=0.5
    # At t=0.7: ball at x=0.7
    # The trick: ball's x-position is tied to t
    
    # We create multiple balls at different t-slices
    for (i, t) in enumerate([3//10, 4//10, 5//10, 6//10, 7//10])
        x_pos = t  # ball moves with time
        ball = create("ball_t$i",
            T[x_pos, 1//2, t],      # x follows t, y=center, t=specific
            T[1//20, 1//10, 1//100], # small in x,y, very thin in t
            T[0, 1, 2],             # dims: x, y, t
            _ -> 0.95
        )
    end
    
    println("\nFrames of animation (t = 0.3, 0.4, 0.5, 0.6, 0.7):\n")
    
    for t in [3//10, 4//10, 5//10, 6//10, 7//10]
        screen = Peripheral{T}(
            "frame_t=$t",
            Dict{T,T}(T(2) => T(t)),  # fix time
            T[0, 1],                   # view x,y
            [40, 16],
            T[1//2, 1//2],
            T[1//2, 1//4]
        )
        empty!(CACHE)
        img = render(screen)
        println("t = $t:")
        println(to_ascii(img, chars=" .o"))
        println()
    end
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 4: Different Physics - Gravity Subspace
# ============================================================

println("\n" * "="^60)
println("DEMO 4: Subspace with Different Physics")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create a "gravity zone" - existence increases downward (higher y = less existence)
    gravity_zone = create("gravity_zone",
        T[1//2, 1//2],
        T[2//5, 2//5],
        T[0, 1],
        ω -> begin
            y = Float64(get_dim(ω, T(1)))
            # Gravity: existence higher at bottom
            0.5 + 0.4 * (1.0 - y)  # varies from 0.9 at bottom to 0.5 at top
        end
    )
    
    # Create a "floating zone" inside - reversed physics!
    # Must be in different dim to be disjoint
    floating_zone = create("floating_zone",
        T[1//2, 1//2, 1//5],      # shift in z to be disjoint
        T[1//5, 1//5, 1//10],
        T[0, 1, 2],
        ω -> begin
            y = Float64(get_dim(ω, T(1)))
            # Anti-gravity: existence higher at top
            0.5 + 0.4 * y
        end
    )
    
    println("\nGravity zone (brighter at bottom, observer at z=0.5):")
    screen_gravity = Peripheral{T}(
        "gravity_view",
        Dict{T,T}(T(2) => T(1//2)),
        T[0, 1],
        [32, 16],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    img_gravity = render(screen_gravity)
    println(to_ascii(img_gravity))
    
    println("\nFloating zone (brighter at top, observer at z=0.2):")
    screen_floating = Peripheral{T}(
        "floating_view",
        Dict{T,T}(T(2) => T(1//5)),
        T[0, 1],
        [32, 16],
        T[1//2, 1//2],
        T[1//5, 1//5]
    )
    empty!(CACHE)
    img_floating = render(screen_floating)
    println(to_ascii(img_floating))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 5: God's Eye View - Observing from Different Angles
# ============================================================

println("\n" * "="^60)
println("DEMO 5: Same Structure, Different Projections")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create a 3D cross shape
    # Vertical bar in y
    create("cross_vertical",
        T[1//2, 1//2, 1//5],
        T[1//20, 1//5, 1//10],
        T[0, 1, 2],
        _ -> 0.9
    )
    
    # Horizontal bar in x
    create("cross_horizontal",
        T[1//2, 1//2, 3//10],    # different z to be disjoint
        T[1//5, 1//20, 1//10],
        T[0, 1, 2],
        _ -> 0.9
    )
    
    # View from front (x,y plane, z=0.2)
    println("\nFront view (x,y at z=0.2) - sees vertical bar:")
    screen_front = Peripheral{T}("front", Dict{T,T}(T(2) => T(1//5)), T[0, 1], [24, 24], T[1//2, 1//2], T[1//4, 1//4])
    println(to_ascii(render(screen_front)))
    
    # View at z=0.3 - sees horizontal bar
    println("\nFront view (x,y at z=0.3) - sees horizontal bar:")
    empty!(CACHE)
    screen_front2 = Peripheral{T}("front2", Dict{T,T}(T(2) => T(3//10)), T[0, 1], [24, 24], T[1//2, 1//2], T[1//4, 1//4])
    println(to_ascii(render(screen_front2)))
    
    # Side view (y,z plane, x=0.5)
    println("\nSide view (y,z at x=0.5) - sees both bars as dots:")
    empty!(CACHE)
    screen_side = Peripheral{T}("side", Dict{T,T}(T(0) => T(1//2)), T[1, 2], [24, 24], T[1//2, 1//4], T[1//4, 1//6])
    println(to_ascii(render(screen_side)))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 6: The Multiverse - Same Location, Different Dimensions
# ============================================================

println("\n" * "="^60)
println("DEMO 6: Parallel Worlds at Same x,y")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # World 1: A house (at dimension 3 = 0.2)
    create("house_floor",
        T[1//2, 3//10, 1//5],
        T[1//5, 1//20, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    create("house_roof",
        T[1//2, 13//20, 3//10],   # different dim 3 to be disjoint
        T[1//6, 1//10, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    
    # World 2: An ocean (at dimension 3 = 0.8)
    create("ocean",
        T[1//2, 3//10, 4//5],
        T[2//5, 1//10, 1//10],
        T[0, 1, 3],
        ω -> begin
            x = Float64(get_dim(ω, T(0)))
            0.6 + 0.1 * sin(x * 20)  # waves
        end
    )
    
    # God at dimension 3 = 0.2 sees a house
    println("\nWorld 1 (dim3=0.2) - The House:")
    screen_house = Peripheral{T}("house_world", Dict{T,T}(T(3) => T(1//5)), T[0, 1], [32, 20], T[1//2, 1//2], T[1//3, 1//3])
    println(to_ascii(render(screen_house)))
    
    # God at dimension 3 = 0.8 sees an ocean
    println("\nWorld 2 (dim3=0.8) - The Ocean:")
    empty!(CACHE)
    screen_ocean = Peripheral{T}("ocean_world", Dict{T,T}(T(3) => T(4//5)), T[0, 1], [32, 20], T[1//2, 1//2], T[1//3, 1//3])
    println(to_ascii(render(screen_ocean)))
    
    println("\nSame x,y coordinates, completely different realities!")
    println("Move in dimension 3 to travel between worlds.")
    
    empty!(Ω.children)
end

# ============================================================
println("\n" * "="^60)
println("END OF ASCII DEMOS")
println("="^60)

# ============================================================
# IMAGE OUTPUT DEMOS
# ============================================================

println("\n" * "="^60)
println("GENERATING PNG AND GIF FILES")
println("="^60)

# Demo: Circle as PNG
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    circle = create("circle", 
        T[1//2, 1//2],
        T[1//5, 1//5],
        T[0, 1],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r_max = 0.2
            r < r_max * 0.8 ? 1.0 : 0.5
        end
    )
    
    screen = Screen2D(T, "circle_view",
        resolution=(64, 64),
        origin=(T(1//2), T(1//2)),
        radius=(T(1//3), T(1//3))
    )
    
    img = render(screen)
    to_png(img, "circle.png", scale=4)
    println("✓ Saved circle.png")
    
    empty!(Ω.children)
end

# Demo: Bowling ball and jacuzzi as PNGs
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    ball = create("bowling_ball",
        T[1//2, 1//2],
        T[1//5, 1//5],
        T[0, 1],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.15 ? 0.9 : 0.5
        end
    )
    
    jacuzzi = create("jacuzzi",
        T[1//2, 1//2, 3//4],
        T[1//10, 1//10, 1//10],
        T[0, 1, 2],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.08 ? 1.0 : 0.5
        end
    )
    
    println("Ball created: ", ball !== nothing)
    println("Jacuzzi created: ", jacuzzi !== nothing)
    if jacuzzi !== nothing
        println("Jacuzzi parent: ", jacuzzi.parent.name)
    end
    
    # Normal view
    screen_normal = Peripheral{T}(
        "normal_observer",
        Dict{T,T}(T(2) => T(1//2)),
        T[0, 1],
        [64, 64],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    img_normal = render(screen_normal)
    to_png(img_normal, "ball_normal.png", scale=4)
    println("✓ Saved ball_normal.png (z=0.5, sees ball)")
    
    # Secret view
    screen_secret = Peripheral{T}(
        "secret_observer",
        Dict{T,T}(T(2) => T(3//4)),
        T[0, 1],
        [64, 64],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    empty!(CACHE)
    img_secret = render(screen_secret)
    to_png(img_secret, "ball_secret.png", scale=4)
    println("✓ Saved ball_secret.png (z=0.75, sees jacuzzi)")
    
    empty!(Ω.children)
end

# Demo: Animated moving ball as GIF
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create balls at different time slices
    for (i, t) in enumerate([2//10, 3//10, 4//10, 5//10, 6//10, 7//10, 8//10])
        x_pos = t
        create("ball_t$i",
            T[x_pos, 1//2, t],
            T[1//20, 1//10, 1//100],
            T[0, 1, 2],
            _ -> 1.0
        )
    end
    
    # Render animation
    screen = Peripheral{T}(
        "animation",
        Dict{T,T}(),
        T[0, 1],
        [64, 32],
        T[1//2, 1//2],
        T[1//2, 1//4]
    )
    
    time_values = T[2//10, 3//10, 4//10, 5//10, 6//10, 7//10, 8//10]
    frames = render_animation(screen, T(2), time_values)
    
    to_gif(frames, "moving_ball.gif", scale=4, delay=15)
    println("✓ Saved moving_ball.gif")
    
    empty!(Ω.children)
end

# Demo: Parallel worlds as PNGs
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # World 1: House
    create("house_floor",
        T[1//2, 3//10, 1//5],
        T[1//5, 1//20, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    create("house_roof",
        T[1//2, 13//20, 3//10],
        T[1//6, 1//10, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    
    # World 2: Ocean with waves
    create("ocean",
        T[1//2, 3//10, 4//5],
        T[2//5, 1//10, 1//10],
        T[0, 1, 3],
        ω -> begin
            x = Float64(get_dim(ω, T(0)))
            0.6 + 0.3 * sin(x * 30)
        end
    )
    
    # House world
    screen_house = Peripheral{T}("house", Dict{T,T}(T(3) => T(1//5)), T[0, 1], 
                                  [64, 48], T[1//2, 1//2], T[1//3, 1//3])
    img_house = render(screen_house)
    to_png(img_house, "world_house.png", scale=4)
    println("✓ Saved world_house.png (dim3=0.2)")
    
    # Ocean world
    empty!(CACHE)
    screen_ocean = Peripheral{T}("ocean", Dict{T,T}(T(3) => T(4//5)), T[0, 1],
                                  [64, 48], T[1//2, 1//2], T[1//3, 1//3])
    img_ocean = render(screen_ocean)
    to_png(img_ocean, "world_ocean.png", scale=4)
    println("✓ Saved world_ocean.png (dim3=0.8)")
    
    empty!(Ω.children)
end

# Demo: Pulsing object (animated)
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create pulsing circles at different times
    for (i, t) in enumerate(0:1//20:19//20)
        # Radius varies with time: oscillates between 0.05 and 0.15
        phase = Float64(t) * 2 * π
        r = 0.1 + 0.05 * sin(phase * 2)
        
        create("pulse_t$i",
            T[1//2, 1//2, t],
            T[Rational{BigInt}(r), Rational{BigInt}(r), 1//100],
            T[0, 1, 2],
            _ -> 0.9
        )
    end
    
    screen = Peripheral{T}(
        "pulse",
        Dict{T,T}(),
        T[0, 1],
        [64, 64],
        T[1//2, 1//2],
        T[1//4, 1//4]
    )
    
    time_values = collect(T(0):T(1//20):T(19//20))
    frames = render_animation(screen, T(2), time_values)
    
    to_gif(frames, "pulsing.gif", scale=4, delay=5)
    println("✓ Saved pulsing.gif")
    
    empty!(Ω.children)
end

println("\n" * "="^60)
println("ALL FILES GENERATED")
println("="^60)
println("""

Generated files:
  - circle.png         : Static circle
  - ball_normal.png    : Bowling ball (normal view)
  - ball_secret.png    : Hidden jacuzzi inside ball
  - moving_ball.gif    : Ball moving through time
  - world_house.png    : House in dimension 3 = 0.2
  - world_ocean.png    : Ocean in dimension 3 = 0.8
  - pulsing.gif        : Pulsing circle animation

""")


# Flying into the Mandelbrot Set
# Deep zoom into interesting regions

# include("something.jl")
# include("something_demo.jl")

T = Rational{BigInt}

# ============================================================
# DEEP ZOOM INTO MANDELBROT - Seahorse Valley
# ============================================================

println("Flying into Mandelbrot - Seahorse Valley...")
println("This may take a few minutes...")

function mandelbrot_value(px, py, center_x, center_y, radius, max_iter)
    # Map [0,1] pixel coords to complex plane centered at (center_x, center_y)
    x0 = center_x + (px - 0.5) * 2 * radius
    y0 = center_y + (py - 0.5) * 2 * radius
    
    x, y = 0.0, 0.0
    iter = 0
    
    while x*x + y*y <= 4 && iter < max_iter
        x, y = x*x - y*y + x0, 2*x*y + y0
        iter += 1
    end
    
    if iter == max_iter
        0.0  # inside = black
    else
        # Smooth coloring
        0.3 + 0.7 * (iter / max_iter)
    end
end

# Seahorse valley coordinates (in complex plane)
target_re = -0.743643887037151
target_im = 0.131825904205330

frames = Array{Real,2}[]
n_frames = 120
resolution = 150

# Zoom from radius 1.5 down to 0.0000001 (10^7 zoom)
start_radius = 1.5
end_radius = 0.00001

for i in 0:n_frames-1
    # Exponential interpolation for smooth zoom
    t = i / (n_frames - 1)
    radius = start_radius * (end_radius / start_radius) ^ t
    
    # Increase iterations as we zoom deeper
    max_iter = 100 + round(Int, t * 400)
    
    empty!(Ω.children)
    empty!(CACHE)
    
    create("mandelbrot_frame",
        T[1//2, 1//2],
        T[1//2, 1//2],
        T[0, 1],
        ω -> begin
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            mandelbrot_value(px, py, target_re, target_im, radius, max_iter)
        end
    )
    
    screen = Peripheral{T}(
        "frame",
        Dict{T,T}(),
        T[0, 1],
        [resolution, resolution],
        T[1//2, 1//2],
        T[1//2, 1//2]
    )
    
    push!(frames, render(screen))
    print("\rFrame $(i+1)/$(n_frames)")
end
println()

to_gif(frames, "mandelbrot_flight.gif", scale=3, delay=4)
println("✓ Saved mandelbrot_flight.gif")

# ============================================================
# DEEP ZOOM INTO MANDELBROT - Spiral
# ============================================================

println("\nFlying into Mandelbrot - Double Spiral...")

# Double spiral coordinates
target_re2 = -0.7436438870371
target_im2 = 0.1318259043124

frames2 = Array{Real,2}[]

for i in 0:n_frames-1
    t = i / (n_frames - 1)
    radius = start_radius * (end_radius / start_radius) ^ t
    max_iter = 100 + round(Int, t * 500)
    
    empty!(Ω.children)
    empty!(CACHE)
    
    create("spiral_frame",
        T[1//2, 1//2],
        T[1//2, 1//2],
        T[0, 1],
        ω -> begin
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            mandelbrot_value(px, py, target_re2, target_im2, radius, max_iter)
        end
    )
    
    screen = Peripheral{T}(
        "frame",
        Dict{T,T}(),
        T[0, 1],
        [resolution, resolution],
        T[1//2, 1//2],
        T[1//2, 1//2]
    )
    
    push!(frames2, render(screen))
    print("\rFrame $(i+1)/$(n_frames)")
end
println()

to_gif(frames2, "mandelbrot_spiral.gif", scale=3, delay=4)
println("✓ Saved mandelbrot_spiral.gif")

# ============================================================
# FLYING THROUGH JULIA SETS - morphing as we travel
# ============================================================

println("\nFlying through Julia set space...")

function julia_value(px, py, c_re, c_im, max_iter)
    x = (px - 0.5) * 3.0
    y = (py - 0.5) * 3.0
    
    iter = 0
    while x*x + y*y <= 4 && iter < max_iter
        x, y = x*x - y*y + c_re, 2*x*y + c_im
        iter += 1
    end
    
    if iter == max_iter
        0.0
    else
        0.3 + 0.7 * (iter / max_iter)
    end
end

frames3 = Array{Real,2}[]
n_frames3 = 90

# Travel along the boundary of the Mandelbrot set (where interesting Julias live)
for i in 0:n_frames3-1
    t = i / n_frames3
    
    # Trace cardioid boundary: c = (e^(iθ)/2 - e^(2iθ)/4)
    θ = 2π * t
    c_re = 0.5 * cos(θ) - 0.25 * cos(2θ)
    c_im = 0.5 * sin(θ) - 0.25 * sin(2θ)
    
    # Scale to stay in interesting region
    c_re = c_re * 0.8 - 0.1
    c_im = c_im * 0.8
    
    empty!(Ω.children)
    empty!(CACHE)
    
    create("julia_travel",
        T[1//2, 1//2],
        T[1//2, 1//2],
        T[0, 1],
        ω -> begin
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            julia_value(px, py, c_re, c_im, 80)
        end
    )
    
    screen = Peripheral{T}(
        "frame",
        Dict{T,T}(),
        T[0, 1],
        [resolution, resolution],
        T[1//2, 1//2],
        T[1//2, 1//2]
    )
    
    push!(frames3, render(screen))
    print("\rFrame $(i+1)/$(n_frames3)")
end
println()

to_gif(frames3, "julia_journey.gif", scale=3, delay=5)
println("✓ Saved julia_journey.gif")

# ============================================================
# ZOOM + ROTATE simultaneously
# ============================================================

println("\nSpiral dive into Mandelbrot...")

frames4 = Array{Real,2}[]
n_frames4 = 100

# Zoom while rotating view
for i in 0:n_frames4-1
    t = i / (n_frames4 - 1)
    radius = 1.5 * (0.0001 / 1.5) ^ t
    angle = t * 4π  # 2 full rotations during zoom
    max_iter = 100 + round(Int, t * 400)
    
    empty!(Ω.children)
    empty!(CACHE)
    
    create("spiral_dive",
        T[1//2, 1//2],
        T[1//2, 1//2],
        T[0, 1],
        ω -> begin
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            
            # Rotate coordinates around center
            cx, cy = 0.5, 0.5
            dx, dy = px - cx, py - cy
            rx = dx * cos(angle) - dy * sin(angle) + cx
            ry = dx * sin(angle) + dy * cos(angle) + cy
            
            mandelbrot_value(rx, ry, target_re, target_im, radius, max_iter)
        end
    )
    
    screen = Peripheral{T}(
        "frame",
        Dict{T,T}(),
        T[0, 1],
        [resolution, resolution],
        T[1//2, 1//2],
        T[1//2, 1//2]
    )
    
    push!(frames4, render(screen))
    print("\rFrame $(i+1)/$(n_frames4)")
end
println()

to_gif(frames4, "mandelbrot_spiral_dive.gif", scale=3, delay=4)
println("✓ Saved mandelbrot_spiral_dive.gif")

# ============================================================
println("\n" * "="^50)
println("All flight animations generated!")
println("="^50)
println("""
Files:
  - mandelbrot_flight.gif      : Deep zoom into seahorse valley (10^5 zoom)
  - mandelbrot_spiral.gif      : Deep zoom into double spiral
  - julia_journey.gif          : Traveling through Julia set parameter space
  - mandelbrot_spiral_dive.gif : Zoom + rotate simultaneously
  
Total frames rendered: $(n_frames + n_frames + n_frames3 + n_frames4)
""")