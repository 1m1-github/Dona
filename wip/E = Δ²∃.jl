# E = Δ²∃

const NOWHERE = _ -> 0
const ORIGIN = 1 / 2
const EVERYWHERE = _ -> 1
struct Rectangle
    origin::Real # [0,1] ∈ ∀
    radius::Real # [0,1] ∈ ∀
end
Rectangle() = Rectangle(ORIGIN, ORIGIN)
∘(outer::Rectangle, inner::Rectangle) = Rectangle(
    outer.origin - outer.radius + inner.origin * 2 * outer.radius,
    outer.radius * inner.radius)
∀(r::Rectangle) = r.origin == r.radius == ORIGIN

abstract type I end
struct N∃ <: I end
struct ∃ <: I # [0,1]^∞ -> [0,1]
    name::AbstractString
    ∀::I
    e::AbstractVector{∃} # first(e) is next dimension if this is a dimension
    ∇∃::Function # origin ∈ [0,1] -> (i ∈ [0,1] ->  d∃/di ∈ [0,1])
    origin::Rectangle
end
function isdimension(e)
    ∀(e) && return true
    first(e.∀.e) === e && isdimension(e.∀)
end
function origin(e)
    isdimension(e) && return e.origin
    isdimension(e.∀) && return e.origin
    origin(e.∀) ∘ e.origin
end
∃!(name, ∀, ∇∃, origin) = push!(∀.e, ∃(name, ∀, [], ∇∃, origin))
∀(e::∃) = e.∀ isa N∃
function dimension(e)
    ∀(e) && return 1
    isdimension(e) && return 1 + dimension(e.∀)
    dimension(e.∀)
end
struct Space
    origin::Dict{Integer,Rectangle}
end
Base.getindex(s::Space, i) = get(s.origin, i, Rectangle(ORIGIN, 0))
Space(e::∃) = Space(e, Dict())
function Space(e, s)
    s[dimension(e)] = origin(e)
    ∀(e) && return Space(s)
    Space(e.∀, s)
end
# Base.isempty(s::Space) = isempty()

God = Ω = Universe = World = d1 = ∃("Ω", N∃(), [], EVERYWHERE, Rectangle())
d = Ω
for i = 2:3
    ∃!("$i", d, EVERYWHERE, Rectangle())
    d = first(d.e)
end
Ω.∀
Ω.e
Ω.origin
function ∩(e, ω=Ω)
    space = Space(e)
    for ê in ω.e
        ê ∩ e && continue
    end
end
e=∃!("",Ω,NOWHERE,Rectangle(0.1,0.05))[end]
ω=Ω
e ∩ ω


1+1

# function ∩(e, ω=Ω)
#     sig = signature(e)
#     isempty(sig) && return ∃[]
#     ∩(sig, ω, 1)
# end
# function ∩(sig, node, depth)
#     isempty(node.e) && return ∃[]

#     dim_child = first(node.e)
#     others = @view node.e[2:end]
#     matches = ∃[]

#     if depth ≤ length(sig)
#         (_, o, r) = sig[depth]
#         for child in others
#             ∩̂(child.origin, child.radius, o, r) && push!(matches, child)
#         end
#         append!(matches, ∩(sig, dim_child, depth + 1))
#     else
#         append!(matches, others)
#         append!(matches, ∩(sig, dim_child, depth))
#     end

#     matches
# end

# δ(i) = î -> î == i ? 1 : 0
# function ∇∃(origin, i)
#     iszero(origin) && return δ(i)
#     NOWHERE
# end

# const ε = 1e-10
# Base.getindex(d::C, k) = get(d, k, ORIGIN)
# const ε = 1e-10
# ∩̂(o1, r1, o2, r2) = abs(o1 - o2) ≤ r1 + r2
# ∩̂(e, ê) = abs(e.origin - ê.origin) ≤ e.radius + ê.radius
# function ∩(e, ê, ω=Ω)
#     ω ∩̂ e && ω ∩̂ ê && !(e ∩̂ ê) && return false
#     for _e = ω.e
#         # _e = ω.e[1]
#         ∩(e, ê, _e) && return true
#     end
#     false
# end

# n=4
# e=Ω
# for i = 1:n
#     e=first(e.e)
# end
# observer = ∃("o",e,[],NOWHERE,1/2,1/2)



# function signature(e)
#     dims = Tuple{Int, Real, Real}[]
#     current = e
#     d = 0
#     while !(current.∀ isa N∃)
#         current.radius > 0 && pushfirst!(dims, (d, current.origin, current.radius))
#         !isempty(current.∀.e) && first(current.∀.e) === current && (d += 1)
#         current = current.∀
#     end
#     dims
# end
# signature(observer)
# function ∩(e, ω=Ω)
#     sig = signature(e)
#     isempty(sig) && return ∃[]
#     ∩(sig, ω, 1)
# end
# function ∩(sig, node, depth)
#     isempty(node.e) && return ∃[]

#     dim_child = first(node.e)
#     others = @view node.e[2:end]
#     matches = ∃[]

#     if depth ≤ length(sig)
#         (_, o, r) = sig[depth]
#         for child in others
#             ∩̂(child.origin, child.radius, o, r) && push!(matches, child)
#         end
#         append!(matches, ∩(sig, dim_child, depth + 1))
#     else
#         append!(matches, others)
#         append!(matches, ∩(sig, dim_child, depth))
#     end

#     matches
# end

# Ω
# e=∃!(Ω, NOWHERE, 0.1, 0.05)[end]
# ê=∃!(Ω, NOWHERE, 0.3, 0.16)[end]
# e ∩̂ ê
# e ∩ ê
# ω=_e
# e=∃!(Ω.e[1], origin -> ∇∃(origin, i), 1/2, 1/2)[end]



# function globaloriginradius(e)
#     e.∀ isa N∃ && return e.origin,e.radius
#     ∀e∀origin,∀e∀radius = globaloriginradius(e.∀)
#     ∀left = ∀e∀origin - ∀e∀radius
#     ∀diameter = 2 * ∀e∀radius
#     ∀eorigin = ∀left + e.origin * ∀diameter
#     ∀eradius = e.radius * ∀diameter
#     ∀eorigin,∀eradius
# end    

# C = Dict{<:Real,<:Real}
# Base.getindex(d::C, k) = get(d, k, 1/2)
# const ε = 1e-10
# function ∈(i, e)
#     origin, radius = globaloriginradius(e)
#     î = i[dimension(e)]
#     return (origin - radius - ε) ≤ î ≤ (origin + radius + ε)
# end




# function ∈(e,origin,radius,discretization,projection_dimensions)
#     # todo return coordinates and ∃ values found via integration of ∇∃ over prisms in observed but not projected_dimensions where box (origin+radius) discretization intersects (∋)
# end

# root(e) = e.∀ isa N∃ ? e : root(e.∀)
# origin(e::N∃) = 0
# origin(e::∃) = e.origin + origin(e.∀)

δ(i, î) = abs(i - î)
∈(::Any, ::N∃) = false
# in01(i) = min(max(i,0),1)
∀originradius(e) = e.∀.origin - e.∀.radius + e.∀.radius * 2 * e.origin, 2 * e.∀.radius * e.radius
eoriginradius(∀) = (i - e.∀.origin + e.∀.radius) / e.∀.radius / 2, e.radius / e.∀.radius / 2
# function ∈(i, e)
e.∀ isa N∃ && return true
d = dimension(e)
d∀ = dimension(e.∀)
id∀ = i[d∀]
i isa C
∀origin, ∀radius = ∀originradius(e)
∀radius < δ(id∀, ∀origin) && return false
î = deepcopy(i)
id = i[d]
start = d ≠ d∀ ? 2 : 1
for ie = start:length(e.e)
    # ie = (start:length(e.e))[1]
    _e = e.e[ie]
    î[d], _ = eoriginradius(e)
    î ∉ _e && return false
end
true
# end
∉ = !∈


using Test
@test globaloriginradius(Ω) == (0.5, 0.5)
@test globaloriginradius(Ω.e[1]) == (0.1, 0)
@test globaloriginradius(Ω.e[2]) == (0.2, 0)
∃!(Ω.e[1], NOWHERE, 0.2, 0.1)
@test globaloriginradius(Ω.e[1].e[1]) == (0.1, 0) # ?
∃!(Ω.e[1].e[1], NOWHERE, 0.5, 0.5)
@test globaloriginradius(Ω.e[1].e[1].e[1]) == (0.1, 0)

@test dimension(Ω) ≈ 0
@test dimension(Ω.e[1]) ≈ 0.1
@test dimension(Ω.e[1].e[1]) ≈ 0.2
@test dimension(Ω.e[1].e[1].e[1]) ≈ 0.3
@test dimension(Ω.e[1].e[1].e[1].e[1]) ≈ 0.4
@test Dict([0 => 0.2]) ∈ Ω
@test Dict([0 => 0.2]) ∉ Ω.e[1]
@test Dict([0 => 0.2, 0.15 => 0.1]) ∈ Ω
@test Dict([0 => 0.2, 0.15 => 0.1]) ∉ Ω.e[1]
@test Dict([0 => 0.1]) ∈ Ω.e[1]
@test Dict([0 => 0.1, 0.1 => 0.1]) ∈ Ω.e[1]
e = ∃!(Ω, _ -> 0, 1 / 2, 1 / 4)[end]
@test dimension(e) ≈ 0
@test Dict([0 => 0.2]) ∉ e
@test Dict([0 => 0.25]) ∈ e
i, e = Dict([0 => 0.25]), e
@test Dict([0 => 0.3, 0.1 => 0.1]) ∈ e
@test Dict([0 => 0.3, 0.15 => 0.1]) ∈ e
@test Dict([0 => 0.2, 0.1 => 0.1]) ∉ e
@test Dict([0 => 0.2, 0.15 => 0.1]) ∉ e
e2 = ∃!(e, _ -> 0, 0.8, 0.1)[end]
@test dimension(e2) ≈ 0
@test Dict([0 => 0.2]) ∉ e2
@test Dict([0 => 0.25]) ∉ e2
@test Dict([0 => 0.61]) ∈ e2
@test Dict([0 => 0.61, 0.1 => 0.1]) ∈ e2
@test Dict([0 => 0.61, 0.75 => 0.1]) ∈ e2
@test Dict([0 => 0.61, 0.15 => 0.1]) ∈ e2
@test Dict([0 => 0.61, 0.1 => 0.1]) ∈ e2
@test Dict([0 => 0.61, 0.15 => 0.1]) ∈ e2
e3 = ∃!(Ω.e[1], _ -> 0, 0.2, 0.05)[end]
@test dimension(e3) ≈ 0.1
@test Dict([0 => 0.2]) ∉ e3
@test Dict([0 => 0.1]) ∉ e3
@test Dict([0 => 0.1, 0.1 => 0.1]) ∈ e3
@test Dict([0 => 0.1, 0.1 => 0.09]) ∈ e3
@test Dict([0 => 0.1, 0.1 => 0.11]) ∈ e3
i, e = Dict([0 => 0.1, 0.1 => 0.11]), e3
@test Dict([0 => 0.9, 0.1 => 0.1]) ∈ e3
@test Dict([0 => 0.1, 0.1 => 0.101]) ∉ e3
@test Dict([0 => 0.1, 0.1 => 0.2]) ∉ e3
@test Dict([0 => 0.1, 0.1 => 0.5]) ∉ e3
@test Dict([0 => 0.1, 0.1 => 0.1]) ∈ e3

# function E(e, i)
#     ∈(e, i) || return 0
#     _E = e.∇∃(i[dimension(e)])
#     for _e in e.e
#         __E = E(_e, i)
#         __E == 0 && return 0
#         _E *= __E
#     end
#     _E
# end

# function ∫(e, origin, radius, discretization, projection_dimensions)
#     dims = sort(collect(keys(discretization)))
#     ranges = Dict(di => collect(range(origin[di] - radius[di], origin[di] + radius[di], length=discretization[di])) for di in dims)
#     ΔV = prod(2 * radius[di] / discretization[di] for di in dims)

#     projection_dimensions_sorted = sort(projection_dimensions)
#     proj_shape = Tuple(discretization[di] for di in projection_dimensions_sorted)
#     result = zeros(Float64, proj_shape...)

#     for idx in Iterators.product([1:discretization[di] for di in dims]...)
#         c = Dict{Float64,Float64}(dims[i] => ranges[dims[i]][idx[i]] for i in 1:length(dims))

#         v = E(e, c) * ΔV
#         v == 0 && continue

#         proj_idx = Tuple(idx[findfirst(==(di), dims)] for di in projection_dimensions_sorted)
#         result[proj_idx...] += v
#     end

#     result
# end

# red_circle = ∃!(dim1,∃(NE(),[],d->iszero(d)&&,1/2,1/2))

# ∇sphere(c, r) = x -> δ(x, c) < r ? 1.0 : 0.0
# const ∇1 = _ -> 1.0
# ∇sphere(c, r) = x -> δ(x, c) < r ? 1.0 : 0.0
# world = ∃(∇1, 0.5, 0.5)
# dim1 = ∃!(world, ∇1, 0.5, 0.5)
