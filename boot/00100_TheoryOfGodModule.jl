"""
TheoryOfGod

I = [ZERO < ○ < ONE] denotes a unit 1-dim space of information with origin ○ (no information) in its center including the corners ZERO and ONE.
∀ = I^I an ∞-dim metric and smooth vector space.
We have a Pretopology 𝕋 on ∀ such that ϵᵢ ∈ 𝕋:
* ϵᵢ ⊆ ∀
* ϵ₂ ∈ ϵ₁.ϵ̃ => ϵ₂|ϵ₁ ⊆ ϵ₁ <=> ϵ₂ ⫉ ϵ₁ ⩓ ϵ₂ ∈ ϵ₃.ϵ̃ => ϵ₁ = ϵ₃
* ϵ₁ ≠ ϵ₂ => ϵ₁ ∩ ϵ₂ = ∅
* x ∈ ϵᵢ ⊊ ∀: x.ρ = 0 => ϵᵢ.Φ(x) ∈ I is arbitrary, computable and smooth fuzzy existence potential towards ONE=true xor ZERO=false.

ϵ ⊊ ∀ defines its existence inside a subset of ∀ using an origin (μ), a radius (ρ) and a closed vs. open in each direction (∂) vector. These vectors are finite and all other dimensional coordinates of ϵ follow from linear interpolation.
If we use a horizontal axis for dimension and a vertical axis for coordinate in the dimension, for any ϵ, the chart looks like a stepwise linear function with finite non-zero radius intervals (active dimensions) and zero interval points within the interpolated regions.
Each child ϵ is a subset of its parent in the active dimensions declared by the parent.

god ⊊ God = ∀ = I^I = I^(.) = [ZERO < ○ < ONE]^(.)
god observes or creates, God iterates.
"""
# module tog

export ∃, ∃̇, ∃!

# Main.@install StaticArrays, KernelAbstractions
using StaticArrays, KernelAbstractions

const T = Float64

include("00101_TheoryOfGod∃.jl")
# include("00102_TheoryOfGodGrid.jl")

const GOD = 𝕋()

# end

# in LoopOS
# include("00103_TheoryOfGodgod.jl")
# include("00103_TheoryOfGodTypst.jl")

# include("00090_BroadcastBrowser2Module.jl")
# import Main.BroadcastBrowserModule: BroadcastBrowser, start
# include("00105_TheoryOfGodgodBrowser.jl")
# const BROWSERTASK = Threads.@spawn start(b->godBrowser(b))

# g=collect(values(godBROWSER[]))[1].g
# dimx, dimy, dimc = T(0.1),T(0.2),T(0.3)
# x, y = T(0.1),T(0.1)
# g = god{T}(dimx, dimy, dimc, x, y, T(2^3), T(2^3))
# # dt = 0.01
# # step(g, dt)
# g.ẑero.μ
# pixel = fill((one(T),one(T),one(T),one(T)), g.♯.n[2],g.♯.n[3])
# @time p̂ixel = observe(g)
# δ = Δ(pixel, p̂ixel)
# isempty(δ)
# dimx, dimy, dimc = T(0.1),T(0.2),T(0.3)
# x, y = T(0.1),T(0.1)
# g = god{T}(dimx, dimy, dimc, x, y, T(3), T(3))
# N=5
name="circle"
# d = g.ẑero.d
# μ = SA[zero(T), T(0.1), T(0.1), ○(T), zero(T)]
# ρ = SA[zero(T), T(0.1), T(0.1), ○(T), zero(T)]
# ϵ=∃{N,T}(GOD,name, d, μ, ρ, ntuple(_->(false,false), 5), (_,_,_)->○(T))
# create(g, name, (t, x, y) -> begin
# # @show "hi"
#     # @show name, t, x, y, x^2 + y^2
#     # x^2 + y^2 == 0.01 ? (T(rand()), T(rand()), T(rand()), one(T)) : (○(T), ○(T), ○(T), ○(T))
#     # @show name, t, x, y
#     T(rand()), T(rand()), T(rand()), one(T)
# end,ϵ)
# collect(keys(GOD.ϵ̃))
# GOD.Ο[GOD]

# observe(g)
