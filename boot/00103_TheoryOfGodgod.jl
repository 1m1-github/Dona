struct god
    ẑero::∃
    ône::∃
    ∂t₀::Bool
    v::T
    ρ::T
    Ω::𝕋
    ⚷::UInt
    ♯::NTuple
    ∇::UInt
    d::Function
end
function god(; d, μ, ρ, ⚷=zero(UInt), Φ=○̂, ♯=SA[1], ∇=typemax(UInt))
    N = length(d)
    ∂₀ = SVector(ntuple(_ -> (true, false), N))
    ẑero = ∃(God, d, μ, ρ, ∂₀, Φ)
    # μ₁ = SA[μ[1], ones(T, N - 1)...]
    ones = @SVector ones(T, N)
    ∂₁ = SVector(ntuple(_ -> (false, true), N))
    zeros = @SVector zeros(T, N)
    ône = ∃(God, d, ones, zeros, ∂₁, ○̂)
    god(ẑero, ône, true, zero(T), zero(T), 𝕋(), ⚷, ♯, ∇, (x, y) -> sqrt.(x .^ 2 .+ y .^ 2))
end
# isreal(ϵ::∃) = √(ϵ) === God
# function dh(⚷, g, n)
#     powermod(g, ⚷, n)
# end
# function ⚷⚷(⚷, dh)
#     powermod(dh, ⚷, DH_N)
# end
# function ⚷i(i, ⚷, ♯)
#     ntuple(length(♯)) do d
#         mod1(i[d] + ⚷, ♯[d])
#     end
# end
# function i⚷(i, ⚷, ♯)
#     ntuple(length(♯)) do d
#         î = mod(⚷, ♯[d])
#         mod1(i[d] + ♯[d] - î, ♯[d])
#     end
# end
function ∃!(g::god, Φ, Ω=God)
    ϵ = g.ône - g.ẑero
    ṫ = t(Ω.Ο[Ω] + 1)
    ρt = (one(T) - ṫ) * ○
    μt = ṫ + ρt
    μ = SA[μt, ϵ.μ[2:end]...]
    ρ = SA[ρt, ϵ.ρ[2:end]...]
    ϵ = ∃(ϵ, ϵ.d, μ, ρ, ϵ.∂, Φ)
    # ϵ = ∃(ϵ, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ℼ(Φ))
    ∃!(ϵ, Ω)
end

function ∃̇(g::god, ∇=1, Ω=God)
    
end
struct ΦTuple{ΦΦ}
    ϕ::ΦΦ
end
@generated function Φ(φ::ΦTuple{ΦΦ}, i, x) where {ΦΦ}
    N = length(ΦΦ.parameters)
    branches = []
    for ĩ in 1:N
        push!(branches, quote
            if i == $ĩ
                return φ.φ[$ĩ](x)
            end
        end)
    end
    quote
        $(branches...)
        return zero(T)
    end
end
function project!(out, Φ, x, i)
    o = zero(T)
    for zi = 1:GL_N
        ĩ = @index(Global, NTuple)
        ϕi = i[ĩ..., zi]
        ϕ = Φ[ϕi]
        o += ϕ(x[ĩ])
    end
    out[ĩ] = one(T) - exp(-o)
end
function project(g::god, Φ::ΦTuple{ΦΦ}, x, i) where {ΦΦ}
    out = KernelAbstractions.zeros(GPU_BACKEND, T, g.♯[2], g.♯[3])
    i̇ = KernelAbstractions.allocate(GPU_BACKEND, UInt16, size(i))
    copyto!(i̇, i)
    ẋ = KernelAbstractions.allocate(GPU_BACKEND, T, size(x))
    copyto!(ẋ, x)
    project!(GPU_BACKEND, GPU_BACKEND_WORKGROUPSIZE)(
        out,
        Φ, ẋ, i̇,
        ndrange=(g.♯[2], g.♯[3])
    )
    KernelAbstractions.synchronize(GPU_BACKEND)
end

# const WHITE = (one(T), one(T), one(T), one(T))
# const BLACK = (zero(T), zero(T), zero(T), one(T))
# ∃̇(g::god) = ∃̇(g.ône - g.ẑero, g.♯, g.∇)
# # ϵ=g.ône - g.ẑero
# function ∃̇(ϵ::∃, ♯, ∇)
#     ϵ̂ = X(ϵ, ♯, ∇)
#     ϵ∃ = filter(ϵ -> ϵ !== God, vec(ϵ̂))
#     isempty(ϵ∃) && return fill(WHITE, ♯[2], ♯[3])
#     unique!(t, ϵ∃)
#     sort!(ϵ∃, by=t)
#     ϵt = map(t, ϵ∃)
#     t_to_tag = Dict(ϵt[i] => UInt32(i) for i in eachindex(ϵt))
#     Φi = zeros(UInt32, ♯[2], ♯[3], ♯[4])
#     for i in CartesianIndices(ϵ̂)
#         ϵ̂ᵢ = ϵ̂[i]
#         ϵ̂ᵢ === God && continue
#         Φi[i[2], i[3], i[4]] = t_to_tag[t(ϵ̂ᵢ)]
#     end
#     φ = ΦSet(ntuple(i -> ϵ∃[i].Φ, length(ϵ∃)))
#     rgba = render(φ, Φi, ♯)
#     ℼ̂(rgba)
# end
# ℼ̂(ϕ) = begin
#     pixel = fill(WHITE, size(ϕ, 2), size(ϕ, 3))
#     # i = collect(CartesianIndices(pixel))[1]
#     for i = CartesianIndices(pixel)
#         r = ϕ[1, Tuple(i)...]
#         g = ϕ[2, Tuple(i)...]
#         b = ϕ[3, Tuple(i)...]
#         a = ϕ[4, Tuple(i)...]
#         pixel[i] = r == g == b == a == ○ ? WHITE : (r, g, b, a)
#     end
#     pixel
# end
# # ρ(μ) = min(μ, 1 - μ)
function step(g::god, dt̂=one(T))
    if g.∂t₀
        ṫ = t()
        μ = SVector(ntuple(i -> i == 1 ? ṫ : g.ẑero.μ[i], length(g.ẑero.μ)))
    else
        δμ = g.ône.μ .- g.ẑero.μ
        all(d -> iszero(d), δμ) && return
        α = clamp(g.v * dt̂, zero(T), one(T))
        μ = g.ẑero.μ .+ α .* δμ
    end
    g = move(g, μ)
    # g.ẑero.Φ !== ○̂ && ∃!(g.ẑero)
    g
end
jerk(g::god, δ) = accelerate(g, g.v * exp(δ))
accelerate(g::god, δ) = speed(g, iszero(g.v) ? δ : g.v * exp(δ))
speed(g::god, v) = god(g.ẑero, g.ône, g.∂t₀, clamp(T(v), zero(T), one(T)), g.ρ, g.Ω, g.⚷, g.♯, g.∇, g.d)
# stop(g::god) = speed(g, zero(T))
# stoptime(g::god) = god(g.ẑero, g.ône, g.∂t₀, SA[zero(T), g.v[2:end]...], g.ρ, g.Ω, g.⚷, g.♯, g.∇, g.d)
# δ=T(0.01)
scale(g::god, δ) = begin
    ϵ = g.ône - g.ẑero
    ρ = min.(ϵ.ρ * exp(δ), ○)
    N = length(ϵ.μ)
    ône = min.(ϵ.μ .+ ρ, ones(T, N))
    ẑero = max.(zeros(T, N), ϵ.μ .- ρ)
    move(g, ône) # could be parallel
    move(g, ẑero) # could be parallel
end
# ẑeroμ=ône
# ẑeroμ=ẑero
move(g::god, ẑeroμ) =
    god(
        ∃(g.ẑero.ϵ̂, g.ẑero.d, ẑeroμ, g.ẑero.ρ, g.ẑero.∂, g.ẑero.Φ),
        # ∃(g.ône.ϵ̂, g.ône.d, SA[ẑeroμ[1], g.ône.μ[2:end]...], g.ône.ρ, g.ône.∂, g.ône.Φ),
        g.ône,
        g.∂t₀, g.v, g.ρ, g.Ω, g.⚷, g.♯, g.∇, g.d
    )
focus(g::god, ôneμ) =
    god(
        # ∃(g.ẑero.ϵ̂, g.ẑero.d, SA[ôneμ[1], g.ẑero.μ[2:end]...], g.ẑero.ρ, g.ẑero.∂, g.ẑero.Φ),
        g.ẑero,
        ∃(g.ône.ϵ̂, g.ône.d, ôneμ, g.ône.ρ, g.ône.∂, g.ône.Φ),
        g.∂t₀, g.v, g.ρ, g.Ω, g.⚷, g.♯, g.∇, g.d
    )
movegod(g, d, δ) = move(g, SVector(ntuple(i -> begin
        g.ẑero.d[i] == d && return δ(μ[i], T(0.01))
        μ[i]
    end, length(μ))))
focusgod(g, d, δ) = focus(g, SVector(ntuple(i -> begin
        g.ône.d[i] == d && return δ(μ[i], T(0.01))
        μ[i]
    end, length(μ))))
focusup(g, d) = focusgod(g, d, +)
focusdown(g, d) = focusgod(g, d, -)
moveup(g, d) = movegod(g, d, +)
movedown(g, d) = movegod(g, d, -)
jerkdown(g) = jerk(g, T(-0.01))
jerkup(g) = jerk(g, T(0.01))
scaledown(g) = scale(g, T(-0.01))
scaleup(g) = scale(g, T(0.01))

# home(g::god) = god(g.ẑero, g.ône, true, zero(T), g.ρ, g.Ω, g.⚷, g.♯, g.∇)

# struct ΦSet{Fs}
#     fs::Fs  # Tuple of Φ functions
# end
# # eval_Φ(φ,1,0.5,0.5,0.5,0.4)
# # @generated function eval_Φ(φ::ΦSet{Fs}, idx, t, x, y, z) where Fs
# @generated function eval_Φ(φ::ΦSet{Fs}, idx, x) where Fs
#     N = length(Fs.parameters)
#     branches = []
#     for i in 1:N
#         push!(branches, quote
#             if idx == $i
#                 # return φ.fs[$i](t, x, y, z)
#                 return φ.fs[$i](x)
#             end
#         end)
#     end
#     quote
#         $(branches...)
#         return (zero(T), zero(T), zero(T), zero(T))
#     end
# end
# @kernel function κ!(rgba, φ::ΦSet, Φi, ♯)
#     xi, yi = @index(Global, NTuple)
#     # xi, yi = 2,2
#     _, W, H, D = ♯
#     x = isone(W) ? ○ : (T(xi) - 1) / T(W - 1)
#     y = isone(H) ? ○ : (T(yi) - 1) / T(H - 1)
#     r, g, b, a = zero(T), zero(T), zero(T), zero(T)
#     # zi = collect(1:D)[2]
#     for zi = 1:D
#         one(T) ≤ a && break
#         z = isone(D) ? ○ : T(zi - 1) / T(D - 1)
#         idx = Φi[xi, yi, zi]
#         iszero(idx) && continue
#         # ṙ, ġ, ḃ, ȧ = eval_Φ(φ, idx, ○, x, y, z)
#         ṙ, ġ, ḃ, ȧ = eval_Φ(φ, idx, (○, x, y, z))
#         iszero(ȧ) && continue
#         rem = one(T) - a
#         r += ṙ * ȧ * rem
#         g += ġ * ȧ * rem
#         b += ḃ * ȧ * rem
#         a += ȧ * rem
#     end
#     rgba[1, xi, yi] = r
#     rgba[2, xi, yi] = g
#     rgba[3, xi, yi] = b
#     rgba[4, xi, yi] = a
# end
# # ♯=g.♯
# # φ, Φi, ♯
# function render(φ::ΦSet, Φi, ♯)
#     rgba = KernelAbstractions.zeros(GPU_BACKEND, T, 4, ♯[2], ♯[3])
#     i̇ = KernelAbstractions.allocate(GPU_BACKEND, UInt32, size(Φi))
#     copyto!(i̇, Φi)
#     Base.invokelatest() do
#         κ!(GPU_BACKEND, GPU_BACKEND_WORKGROUPSIZE)(
#             rgba, φ, i̇, ♯,
#             ndrange=(♯[2], ♯[3])
#         )
#     end
#     KernelAbstractions.synchronize(GPU_BACKEND)
#     Array(rgba)
# end

# # i = collect(CartesianIndices(Ξ))[2678]
# # Ξ[i].Φ(1)
# # ∇=typemax(UInt32)
# function X(ϵ::∃, ♯, ∇)
#     Ξ = Array{∀}(undef, ♯...)
#     ρ₀ = zero(ϵ.ρ)
#     # for i in CartesianIndices(Ξ)
#     # î = collect(1:length(Ξ))[1]
#     @time Threads.@threads for î in 1:length(Ξ)
#         # @time begin 
#         i = CartesianIndices(Ξ)[î]
#         x = X(i, ♯)
#         # xϵ = ∃(God, ϵ.d, x, ρ₀, ϵ.∂, ϵ.Φ)
#         xϵ = ∃(God, ϵ.d, SVector(x), ρ₀, ϵ.∂, ϵ.Φ)
#         Ξ[i], _ = X(xϵ, ∇)
#         # end;
#     end
#     Ξ
# end


# sum([0.707,-0.707,0] .* [1,1,1])
# sum([0.408,0.408,-0.816] .* [1,1,1])
