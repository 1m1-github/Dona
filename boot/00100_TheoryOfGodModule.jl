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

using StaticArrays, KernelAbstractions, Metal
# using CUDA
const GPU_BACKEND = MetalBackend() # CUDABackend()

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

g=god((T(0.1),T(0.2),T(0.3)), (T(0.1),T(0.1),T(0.1)))
g.ẑero
g.ône
g.ône-g.ẑero
struct Π{F}
    Φ::F
end
@inline function (p::Π)(t, x, y, z, c)
    r, g, b, a = p.Φ(t, x, y, z)
    r == g == b == a == ○ && return one(T)
    c∂ = one(T) / T(4)
    c∂ = one(T) / 4
    if c < c∂
        r
    elseif c < 2 * c∂
        g
    elseif c < 3 * c∂
        b
    else
        a
    end
end
ℼ(Φ) = Π(Φ)
Φ(t,x,y,z) = (T(0.78),T(0.8),T(0.9),one(T))
ϵ = g.ône - g.ẑero
ϵ = ∃(ϵ, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ℼ(Φ))
ℼ(Φ) === ϵ.Φ
y = KernelAbstractions.zeros(GPU_BACKEND, T, 1)
@kernel function κ!(y, Φ)
    i = @index(Global)
    # y[1],y[2],y[3],y[4] = Φ(T(i),T(i),T(i),T(i),T(i))
    y[1] = Φ(T(i),T(i),T(i),T(i),T(i))
end
κ!(GPU_BACKEND, 2)(
    y,
    # ℼ(Φ),
    ϵ.Φ,
    ndrange=1
)
y
create(g, Φ_solid)
God.Ο[God]
create(g, Φ)
God.Ο[God]
# g.ẑero
# collect(keys(God.ϵ̃))
ϵ̃=God.ϵ̃[God][1]
t()
t(ϵ̃)
ϵ̃.Φ(zeros(7))
♯ = (1,3,3,3,6)
∃̇(g, ♯)
all(==(ntuple(_->one(T),4)),observe(g,♯))
step(g)
