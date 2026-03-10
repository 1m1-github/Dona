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

# include("00100_TheoryOfGodProjection.jl")
# include("00100_TheoryOfGodProjection2.jl")
# using KernelAbstractions
# using Metal
# const GPU_BACKEND = MetalBackend()
# const GPU_BACKEND_WORKGROUPSIZE = 2^2^3

const invϕ = one(T) / MathConstants.golden
♯space = 10
# g = god(
#     d=sort(SA[zero(T), invϕ, invϕ^2, invϕ^3, invϕ^4, invϕ^5, invϕ^6, one(T)]),
#     μ=SA[t(), ○, ○, ○, ○, ○, ○, zero(T)],
#     ρ=SA[zero(T), zero(T), zero(T), zero(T), zero(T), zero(T),zero(T), zero(T)],
#     ♯=(♯space, ♯space))
# const SPATIAL = [2,3,4]
g = god(
    d=sort(SA[zero(T), invϕ, invϕ^2, one(T)]),
    μ=SA[t(), ○, ○,○],
    ρ=SA[zero(T), ○, ○,○],
    ♯=(♯space, ♯space))

(i, ΦΦ, p0, e1, e2, d̂, Δx, Δy, c, ẑero, ône, has_gl) = ∃̇(g);
ΦΦ
unique(i)
ΦΦ[1] === ○̂
φ_hi(x...) = T(0.3)
∃!(g, φ_hi);
(i, ΦΦ, p0, e1, e2, d̂, Δx, Δy, c, ẑero, ône, has_gl) = ∃̇(g);
ΦΦ
unique(i)
g = move(g, SA[t(), g.ẑero.μ[2:end]...]);
(i, ΦΦ, p0, e1, e2, d̂, Δx, Δy, c, ẑero, ône, has_gl) = ∃̇(g);
ΦΦ
unique(i)

println("○̂: ", count(==(UInt32(1)), i))
println("φ_hi: ", count(==(UInt32(2)), i))
println("total: ", length(i))

φ_lo(x...) = T(0.7)
ṫ = t()
∃!(∃(God, g.ẑero.d, SA[ṫ, ○, ○, ○], SA[T(0.05), T(0.25), T(0.25), T(0.25)], g.ẑero.∂, φ_lo))
(i, ΦΦ, p0, e1, e2, d̂, Δx, Δy, c, ẑero, ône, has_gl) = ∃̇(g);
unique(i)

a1 = God.ϵ̃[God][1]
φ_lo(x...) = T(0.7)
∃!(∃(a1, a1.d, SA[a1.μ[1], T(0.25), T(0.25), T(0.25)], SA[zero(T), T(0.15), T(0.15), T(0.15)], a1.∂, φ_lo))

(i, ΦΦ, p0, e1, e2, d̂, Δx, Δy, c, ẑero, ône, has_gl) = ∃̇(g,  2);
println(ΦΦ)
println(unique(i))

i
God.ϵ̃[God][1].Φ
φ_child(x...) = T(0.8)
∃!(g, φ_child)
g = scaleup(g)
g = scaledown(g)
for _=1:10 g = moveup(g, zero(T)) end

include("00102_TheoryOfGodMiniFB.jl")

function start(g::god)
    t = time()
    while true
        # sleep(10)
        yield()
        t̂ = time()
        dt = t̂ - t
        t = t̂
        step(g, dt)
        # p̂ixel = ∃̇(g)
        # @show p̂ixel
        # δ = Δ(pixel, p̂ixel)
        # @show δ
        # @show isempty(δ)
        # isempty(δ) && continue
        # todo
        # global buffer = p̂ixel
        global buffer = ∃̇(g)
    end
end
const godTASK = @async start(g)

# include("00104_TheoryOfGodTypst.jl")
# Φ_hi = Φ_typst(typst_to_matrix("hi"))
# Φ_hi = Φ_typst("hi")
# gpu_safe(○̂, 2)
# gpu_safe((x,y) -> ○, 2)
# φ_hi, mat_hi = Φ_typst("hi")
# gpu_safe(φ_hi, 2)
# ∃!(g, φ_hi)

# using KernelAbstractions
# const T = Float32
# function gpu_safe(Φ, N)
#     try
#         @kernel gpu(Φ, x) = Φ(x)
#         x = KernelAbstractions.zeros(GPU_BACKEND, T, N)
#         gpu(GPU_BACKEND, GPU_BACKEND_WORKGROUPSIZE)(Φ, x, ndrange=1)
#         true
#     catch
#         # bt = catch_backtrace()
#         # showerror(stderr, e, bt)
#         false
#     end
# end

# @kernel function _test_simple(out)
#     I = @index(Global)
#     out[I] = ○
# end
# out = KernelAbstractions.zeros(GPU_BACKEND, T, 1)
# _test_simple(GPU_BACKEND, 64)(out, ndrange=1)
# KernelAbstractions.synchronize(GPU_BACKEND)
# println(Array(out))


# φ_hi, mat_hi = Φ_typst("hi")
# println(φ_hi)
# println(size(mat_hi))
# isbitstype(typeof(φ_hi))

# @kernel function _test_full(out, φ, @Const(atlas))
#     I = @index(Global)
#     x = (T(0.5), T(0.5))
#     out[I] = φ(x, atlas)
# end

# atlas_gpu = adapt(GPU_BACKEND, mat_hi)
# out = KernelAbstractions.zeros(GPU_BACKEND, T, 1)
# _test_full(GPU_BACKEND, 64)(out, φ_hi, atlas_gpu, ndrange=1)
# KernelAbstractions.synchronize(GPU_BACKEND)
# println("OK: ", Array(out))


# φ_const = ΦFunc(○̂)
# φs = ΦSet((φ_const, φ_hi))

# @generated function eval_Φ(φ::ΦSet{Fs}, idx, x, atlas) where Fs
#     N = length(Fs.parameters)
#     branches = []
#     for i in 1:N
#         push!(branches, quote
#             if idx == $i
#                 return φ.fs[$i](x, atlas)
#             end
#         end)
#     end
#     quote
#         $(branches...)
#         return ○
#     end
# end

# @kernel function _test_set(out, φ::ΦSet, @Const(atlas))
#     I = @index(Global)
#     x = (T(0.5), T(0.5))
#     out[I] = eval_Φ(φ, UInt32(1), x, atlas)  # should give ○ = 0.5
# end

# out = KernelAbstractions.zeros(GPU_BACKEND, T, 2)
# Base.invokelatest() do
#     _test_set(GPU_BACKEND, 64)(out, φs, atlas_gpu, ndrange=1)
# end
# KernelAbstractions.synchronize(GPU_BACKEND)
# println("idx=1 (const): ", Array(out)[1])

# @kernel function _test_set2(out, φ::ΦSet, @Const(atlas))
#     I = @index(Global)
#     x = (T(0.5), T(0.5))
#     out[I] = eval_Φ(φ, UInt32(2), x, atlas)  # should give 0.992...
# end

# Base.invokelatest() do
#     _test_set2(GPU_BACKEND, 64)(out, φs, atlas_gpu, ndrange=1)
# end
# KernelAbstractions.synchronize(GPU_BACKEND)
# println("idx=2 (tex):   ", Array(out)[1])

# φ_const = ΦFunc((args...) -> ○)
# φ_const = ΦFunc((x,y) -> ○)
# φs = ΦSet((φ_const, φ_hi))

# Base.invokelatest() do
#     _test_set(GPU_BACKEND, 64)(out, φs, atlas_gpu, ndrange=1)
# end
# KernelAbstractions.synchronize(GPU_BACKEND)
# println("idx=1 (const): ", Array(out)[1])

# Base.invokelatest() do
#     _test_set2(GPU_BACKEND, 64)(out, φs, atlas_gpu, ndrange=1)
# end
# KernelAbstractions.synchronize(GPU_BACKEND)
# println("idx=2 (tex): ", Array(out)[1])
# # const MAX_RGB = T(mfb_rgb(255, 255, 255))
# # rgb2c(r, g, b) = T(mfb_rgb(r * 255, g * 255, b * 255)) / MAX_RGB
# # c2rgb(c2) = begin
# #     c = floor(UInt32, c2 * MAX_RGB)
# #     ((c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF) ./ 255
# # end

# # μ(::𝕋) = SVector(ntuple(_ -> ○, length(d)))
# # μ(ϵ::∃) = ϵ.μ
# # ρ(Ω::𝕋) = μ(Ω)
# # ρ(ϵ::∃) = ϵ.ρ

# # g=step(g)


# # include("00090_BroadcastBrowser2Module.jl")
# # import Main.BroadcastBrowserModule: BroadcastBrowser, start
# # include("00105_TheoryOfGodgodBrowser.jl")
# # const BROWSERTASK = Threads.@spawn start(b -> godBrowser(b))
# # g=collect(values(godBROWSER[]))[1].g
