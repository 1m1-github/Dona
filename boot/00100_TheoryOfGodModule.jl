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

using KernelAbstractions
using Metal ; const GPU_BACKEND = MetalBackend()
# using CUDA ; const GPU_BACKEND = CUDABackend()
const GPU_BACKEND_WORKGROUPSIZE = 2^2^3

const T = Float32

include("00101_TheoryOfGod∃.jl")

const God = 𝕋()

# struct Named
#     ϵ::∃
#     T::Type
# end
# const names = Dict{String,Named}()

# end

# in LoopOS
include("00103_TheoryOfGodgod.jl")
# include("00103_TheoryOfGodTypst.jl")

# include("00090_BroadcastBrowser2Module.jl")
# import Main.BroadcastBrowserModule: BroadcastBrowser, start
# include("00105_TheoryOfGodgodBrowser.jl")
# const BROWSERTASK = Threads.@spawn start(b->godBrowser(b))
# g=collect(values(godBROWSER[]))[1].g

d = SA[T(0.1),T(0.2),T(0.3)]
μ = SA[T(0.1),T(0.1),T(0.1)]
g=god(d=d, μ=μ,♯=(3,3,3))
g.ẑero
g.ône
ϵ = g.ône-g.ẑero
# ϵ=∃(God, SA[T(0.1)], SA[T(0.1)], SA[T(0.1)], ((true,true),), _->one(T))
# ϵ=∃(God, SA[T(0.1)], SA[T(0.1)], SA[T(0.1)], ((true,true),), _->rand(T))
# ϵ=∃(God, SA[T(0.1)], SA[T(0.1)], SA[T(0.1)], ((true,true),), _->begin
#     f=open("w.jl");close(f)
# end)

God.Ο[God]
Φ(x...) = x
create(g, Φ)
God.Ο[God]
# collect(keys(God.ϵ̃))
# ϵ̃=God.ϵ̃[God][1]
# t()
# t(ϵ̃)
ϕ = ∃̇(g)

ϕ[:,2,2]
# all(==(ntuple(_->one(T),4)),observe(g))
# step(g)
