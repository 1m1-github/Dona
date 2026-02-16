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

using StaticArrays, KernelAbstractions

const T = Float32

include("00101_TheoryOfGod∃.jl")

const God = 𝕋()

struct Named
    ϵ::∃
    T::Type
end
const names = Dict{String,Named}()

# end

# in LoopOS
include("00103_TheoryOfGodgod.jl")
# include("00103_TheoryOfGodTypst.jl")


# include("00090_BroadcastBrowser2Module.jl")
# import Main.BroadcastBrowserModule: BroadcastBrowser, start
# include("00105_TheoryOfGodgodBrowser.jl")
# const BROWSERTASK = Threads.@spawn start(b->godBrowser(b))
# g=collect(values(godBROWSER[]))[1].g

g=god((T(0.1),T(0.2)), (T(0.1),T(0.1)))
g.ẑero
g.ône
g.ône-g.ẑero
Φ(t,x,y,z) = begin
    # x^2 + y^2 == 0.01 ? (T(rand()), T(rand()), T(rand()), one(T)) : (○(T), ○(T), ○(T), ○(T))
    # ntuple(_ -> rand(), 4)
    (T(0.7),T(0.8),T(0.9),one(T))
end
# const God = 𝕋()
God.Ο[God]
create(g, Φ)
God.Ο[God]
# g.ẑero
# collect(keys(God.ϵ̃))
ϵ̃=God.ϵ̃[God][1]
t()
t(ϵ̃)
ϵ̃.Φ(zeros(7))
♯ = (1,1,1,6,3,3,1)
# ♯ = (1,1,1,6,4,4,1)
observe(g, ♯)
all(==(ntuple(_->one(T),4)),observe(g,♯))
step(g)
