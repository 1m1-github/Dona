module TheoryOfGod

# ΔI = [0,1]^∞ # d1,d2,d3,d4,... dimensions of change, d1 as numeraire
# E = Δ²I

abstract type AbstractInformation end
struct NoInformation <: AbstractInformation end
struct Information <: AbstractInformation
    (⊂)::Function # [0,1]
    (<)::Function # [0,1] # todo results from functor from ⊂-space to <-space
end

abstract type AbstractDimension <: AbstractInformation end
⊂(d1::AbstractDimension, d2::AbstractDimension) = d1.parent == d2 || d1.parent ⊂ d2
<(d1::AbstractDimension, d2::AbstractDimension) = d1 ⊂ d2
struct NoDimension <: AbstractDimension end
⊂(::AbstractDimension, ::NoDimension) = true
struct Dimension <: AbstractDimension
    parent::AbstractDimension
    information::AbstractInformation # value
end
Dimension(parent) = Dimension(parent,Information(⊂, <))
depth(d::NoDimension) = 0
depth(d::Dimension) = depth(d.parent) + 1
dt = Dimension(NoDimension())
dx = Dimension(dt)
dy = Dimension(dx)
@assert depth(dy) == 3
dimensions = [dt,dx,dy]

abstract type AbstractArea <: AbstractInformation end
struct Area <: AbstractArea
    center::AbstractVector
    radius::AbstractVector
    information::AbstractInformation
    Area(center::AbstractVector,radius::AbstractVector) = new(center,radius,Information(⊂, <))
end
⊂(a1::AbstractArea, a2::AbstractArea) = (a1 ∩ a2) / a1
<(a1::AbstractArea, a2::AbstractArea) = a1 ⊂ a2
struct NoArea <: AbstractArea end
⊂(x::AbstractArea, ::NoArea) = one(eltype(x))

T=Float64
# const GOD = Information((_,i) -> i == GOD ? 1 : 0,(_,i) -> 1)
# ⊂(i1::AbstractInformation, i2::AbstractInformation) = 
# <(i1::AbstractDimension, i2::AbstractDimension) = i1 ⊂ i2
# dx0 = Dimension(dt,Information(_->1,_->1))

# coordinate / point / information N-dim in GOD (∞-dim)
center = [0.5,0.5]
radius = [0.1,0.1]
@assert length(center) == length(radius) # else pad

a=Something(
    "red circle",
    Area(center,radius),
    x->begin @show x; any(iszero.(x) .|| isone.(x)) ? f2(4e14) : zero(eltype(x)) end
)
big(2)^8^3
f(x)=-log2(1-x) # [0,1] -> [0,∞]
f2(x)=-log2(1-1/x) # [1,∞] -> [0,1]
f2(big(2)^8^3)
x=big(2)^8^3
big(1)-big(1)/x
f2(4e14)
empty!(SOMETHING[])
push!(SOMETHING[],a)
observe(center)
observe([0.5,1.0])

struct Something <: AbstractInformation
    name::String
    area::AbstractArea
    energy::Function # [0,1]
    # information::AbstractInformation
end
const SOMETHING = Ref(Something[])
E = Δ²I = Ref((Dict{AbstractVector,AbstractFloat})()) # [0,1]^∞
E[]
function observe(center)
    something_around_center = filter(i -> center ∈ i.area, SOMETHING[])
    e = sum(i -> i.energy(center),something_around_center)
    !iszero(e) && ( Δ²I[][center] = e )
    e
end # todo performance

∈(x::AbstractVector,a::AbstractArea) = a.center - a.radius ≤ x ≤ a.center + a.radius

struct Observation
end

# area
# corner(::NoArea) = 
# corner(a::Area) = a.center .- a.radius, a.center + a.radius
# ZERO, ONE = center .- radius, center + radius

# claimants
# ⊂ = ::AbstractVector{Information}

# discretization = given Tuple{N,Int} (size per dimension), map between theoretical space and index
# index::CartesianIndices, center::AbstractVector

# observe/create = set some information, includes owner, gets cached (emphemeral), equals creation, setting or giving energy, lost as entropy
# isdefined()

end
