import Pkg
Pkg.activate("tog")

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

# export ∃, ∃̇, ∃!

# using DataStructures
const T = Float32

include("00101_TheoryOfGod∃.jl")
const God = 𝕋()
# const name = Dict{∃, String}()
include("00103_TheoryOfGodgod.jl")

include("00100_TheoryOfGodProject.jl")

const invϕ = one(T) / MathConstants.golden
♯space = 10^3
# g = god(
#     d=sort(SA[zero(T), invϕ, invϕ^2, invϕ^3, invϕ^4, invϕ^5, invϕ^6, one(T)]),
#     μ=SA[t(), ○, ○, ○, ○, ○, ○, zero(T)],
#     ρ=SA[zero(T), zero(T), zero(T), zero(T), zero(T), zero(T),zero(T), zero(T)],
#     ♯=(♯space, ♯space))
# const SPATIAL = [2,3,4]
g = god(
    d=SA[zero(T), invϕ, one(T)],
    μ=SA[t(), ○, ○],
    ρ=SA[zero(T), ○, ○],
    ♯=(♯space, ♯space))

include("00102_TheoryOfGodMiniFB.jl")

function start() while true
    # sleep(10)
    yield()
    # t̂ = time()
    # dt = t̂ - t
    # t = t̂
    step(g, dt)
    p̂ixel = ∃̇(g)
    @show p̂ixel
    δ = Δ(pixel, p̂ixel)
    # @show δ
    @show isempty(δ)
    isempty(δ) && continue
    # todo
end end
const godTASK = @async start(g)

Φ_hi = typst_to_matrix("hi")
create(g, Φ_hi)

# const MAX_RGB = T(mfb_rgb(255, 255, 255))
# rgb2c(r, g, b) = T(mfb_rgb(r * 255, g * 255, b * 255)) / MAX_RGB
# c2rgb(c2) = begin
#     c = floor(UInt32, c2 * MAX_RGB)
#     ((c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF) ./ 255
# end

# μ(::𝕋) = SVector(ntuple(_ -> ○, length(d)))
# μ(ϵ::∃) = ϵ.μ
# ρ(Ω::𝕋) = μ(Ω)
# ρ(ϵ::∃) = ϵ.ρ

# g=step(g)


# include("00090_BroadcastBrowser2Module.jl")
# import Main.BroadcastBrowserModule: BroadcastBrowser, start
# include("00105_TheoryOfGodgodBrowser.jl")
# const BROWSERTASK = Threads.@spawn start(b -> godBrowser(b))
# g=collect(values(godBROWSER[]))[1].g
