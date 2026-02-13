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

const God = 𝕋()

# end

# in LoopOS
include("00103_TheoryOfGodgod.jl")
# include("00103_TheoryOfGodTypst.jl")

# include("00090_BroadcastBrowser2Module.jl")
# import Main.BroadcastBrowserModule: BroadcastBrowser, start
# include("00105_TheoryOfGodgodBrowser.jl")
# const BROWSERTASK = Threads.@spawn start(b->godBrowser(b))

# g=collect(values(godBROWSER[]))[1].g
dimx, dimy, dimc = T(0.1),T(0.2),T(0.3)
x, y = T(0.1),T(0.1)
nx, ny = Int(4), Int(4)
g = god(dimx, dimy, dimc, x, y, nx, ny)
g.ône-g.ẑero
Φ(t,x,y) = begin
    # x^2 + y^2 == 0.01 ? (T(rand()), T(rand()), T(rand()), one(T)) : (○(T), ○(T), ○(T), ○(T))
    ntuple(_ -> rand(), 4)
end
# const God = 𝕋()
# Φ(1)
God.Ο[God]
create(g, Φ)
God.Ο[God]
# g.ẑero
# collect(keys(God.ϵ̃))
ϵ̃=God.ϵ̃[God][1]
t()
t(ϵ̃)
ϵ̃.Φ((1,1,1,1,1))
# g.♯ = (1,3,3,6,1)
# g.♯ = (1,4,4,6,1)
observe(g)
any(!=(ntuple(_->one(T),4)),observe(g))
all(==(ntuple(_->one(T),4)),observe(g))
# observe(g)[2:end,2:end]
g.ône



Do you remember our discussions on time and how they're connected between an origin and an inner world and to complexity, and that an observer can choose the consumption rate of complexity per own time and we have a formula connecting time and complexity. In this world in the beginning time jumps from zero to about 40% of total world time after the creation of the very first entity and then slows down evermore to compress, infinity until one. 
in the origin world, we have time t̂, in the inner world time t.
i am thinking about the implementation of step! for god (pasted) for time.
at finite speed, we expect to not skip any time steps, meaning we should show each age integer as it increased. or maybe not, maybe speeding up time is akin to missing inbetween frames. which is it?
we could let the speed be dt/dt̂ or skips in age observed or less sleep inbetween all time frames observations or ...
