using .TheoryOfGod

const Ω = Something{Rational{BigInt}}(
    "Ω", Rational{BigInt}[], Rational{BigInt}[], Rational{BigInt}[],
    _ -> ORIGIN, nothing, sha3_512("Ω"), Something{Rational{BigInt}}[]
)

hash(Ω)

# --- Tests for get_dim ---
@assert get_dim(Dict(0.0 => 0.3, 1.0 => 0.7), 0.0) == 0.3 "get_dim: active dim"
@assert get_dim(Dict(0.0 => 0.3, 1.0 => 0.7), 1.0) == 0.7 "get_dim: second dim"
@assert get_dim(Dict(0.0 => 0.3, 1.0 => 0.7), 2.0) == 0.5 "get_dim: missing dim returns ORIGIN"
@assert get_dim(Dict{Float64,Float64}(), 1.0) == 0.5 "get_dim: empty dict returns ORIGIN"
println("✓ get_dim")


# --- Tests for is_at_origin ---
@assert is_at_origin(Dict(0.0 => 0.5, 1.0 => 0.3), 0.0) == true "is_at_origin: at 0.5"
@assert is_at_origin(Dict(0.0 => 0.5, 1.0 => 0.3), 1.0) == false "is_at_origin: not at origin"
@assert is_at_origin(Dict(0.0 => 0.3), 1.0) == true "is_at_origin: missing dim is at origin"
@assert is_at_origin(Dict{Float64,Float64}(), 0.0) == true "is_at_origin: empty is at origin"
println("✓ is_at_origin")


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
