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
    μ₁ = SA[μ[1], ones(T, N - 1)...]
    ∂₁ = SVector(ntuple(_ -> (false, true), N))
    zeros = @SVector zeros(T, N)
    ône = ∃(God, d, μ₁, zeros, ∂₁, ○̂)
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
    μ = SA[t(Ω.Ο[Ω] + 1), ϵ.μ[2:end]...]
    ϵ = ∃(ϵ, ϵ.d, μ, ϵ.ρ, ϵ.∂, Φ)
    # ϵ = ∃(ϵ, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ℼ(Φ))
    ∃!(ϵ, Ω)
end
const GL_N = 8
const GL_NODES = (
    -0.9602898564975363,
    -0.7966664774136267,
    -0.5255324099163290,
    -0.1834346424956498,
    0.1834346424956498,
    0.5255324099163290,
    0.7966664774136267,
    0.9602898564975363,
)
const GL_WEIGHTS = (
    0.1012285362903763,
    0.2223810344533745,
    0.3137066458778873,
    0.3626837833783620,
    0.3626837833783620,
    0.3137066458778873,
    0.2223810344533745,
    0.1012285362903763,
)
function to_Ω(ϵ::∃, d)
    μk, ρk, _ = μρ(ϵ, d)
    lo = μk - ρk
    hi = μk + ρk
    p = ϵ.ϵ̂
    while p isa ∃
        pμ, pρ, _ = μρ(p, d)
        p_lo = pμ - pρ
        lo = p_lo + lo * 2 * pρ
        hi = p_lo + hi * 2 * pρ
        p = p.ϵ̂
    end
    lo, hi
end

function clip_half_plane(poly, α, β, r)
    out = eltype(poly)[]
    n = length(poly)
    for j in 1:n
        s1, t1 = poly[j]
        s2, t2 = poly[j%n+1]
        d1 = α * s1 + β * t1 - r
        d2 = α * s2 + β * t2 - r
        if d1 ≥ zero(T)
            push!(out, (s1, t1))
        end
        if (d1 > zero(T)) != (d2 > zero(T))
            frac = d1 / (d1 - d2)
            push!(out, (s1 + frac * (s2 - s1), t1 + frac * (t2 - t1)))
        end
    end
    out
end

function ∃̇(g::god; ∇=1, Ω=God)
    v = g.ône - g.ẑero
    ϵ̂ = β(v, Ω)
    N = length(v.d)
    nx, ny = g.♯
    has_gl = N ≥ 4

    # view box in Ω coordinates
    ẑero = SVector{N,T}(ntuple(k -> to_Ω(v, v.d[k])[1], N))
    ône = SVector{N,T}(ntuple(k -> to_Ω(v, v.d[k])[2], N))
    d⃗ = ône .- ẑero
    c = (ẑero .+ ône) ./ 2
    d̂ = d⃗ ./ sqrt(sum(d⃗ .^ 2))

    # screen basis: e2 from v.d[end-1], e1 from v.d[end-2]
    up = setindex(zero(d⃗), one(T), N - 1)
    e2 = up .- sum(up .* d̂) .* d̂
    e2 = e2 ./ sqrt(sum(e2 .^ 2))

    if N ≥ 3
        right = setindex(zero(d⃗), one(T), N - 2)
        e1 = right .- sum(right .* d̂) .* d̂ .- sum(right .* e2) .* e2
        e1 = e1 ./ sqrt(sum(e1 .^ 2))
    else
        e1 = SVector(e2[2], -e2[1])
    end

    # inscribed rectangle: clip view box to screen plane, find max rect
    view_a_lo = ẑero .- c
    view_a_hi = ône .- c
    L = sqrt(sum(d⃗ .^ 2))
    poly = [(-L, -L), (L, -L), (L, L), (-L, L)]
    for k in 1:N
        α, β = e1[k], e2[k]
        abs(α) + abs(β) ≤ eps(T) && continue
        poly = clip_half_plane(poly, α, β, view_a_lo[k])
        isempty(poly) && break
        poly = clip_half_plane(poly, -α, -β, -view_a_hi[k])
        isempty(poly) && break
    end

    α_ratio = T(nx) / T(ny)
    M = length(poly)
    H = typemax(T)
    for k in 1:M
        k2 = k % M + 1
        a = poly[k2][2] - poly[k][2]
        b = -(poly[k2][1] - poly[k][1])
        r = a * poly[k][1] + b * poly[k][2]
        r < zero(T) && (a, b, r=(-a, -b, -r))
        H = min(H, r / (abs(a) * α_ratio + abs(b)))
    end
    W = α_ratio * H
    Δx = 2W / nx
    Δy = 2H / ny
    p0 = c .- W .* e1 .- H .* e2
    # allocate grid and Φ list
    i = has_gl ? ones(UInt32, nx, ny, GL_N) : ones(UInt32, nx, ny)
    ΦΦ = Function[ϵ̂ isa 𝕋 ? ○̂ : ϵ̂.Φ]

    # fill i for each sibling
    for ϵ in God.ϵ̃[ϵ̂]
        v ∩ ϵ || continue  # skip if no intersection
        push!(ΦΦ, ϵ.Φ)
        idx = UInt32(length(ΦΦ))

        ϵ_zero = SVector{N,T}(ntuple(k -> to_Ω(ϵ, v.d[k])[1], N))
        ϵ_one = SVector{N,T}(ntuple(k -> to_Ω(ϵ, v.d[k])[2], N))

        if has_gl
            for ig in 1:GL_N
                τ = (GL_NODES[ig] + one(T)) / 2  # map [-1,1] → [0,1]
                omτ = one(T) - τ

                a_lo = (ϵ_zero .- τ .* ône) ./ omτ .- c
                a_hi = (ϵ_one .- τ .* ône) ./ omτ .- c
                poly_ϵ = [(-L, -L), (L, -L), (L, L), (-L, L)]
                for k in 1:N
                    α, β = e1[k], e2[k]
                    abs(α) + abs(β) ≤ eps(T) && continue
                    poly_ϵ = clip_half_plane(poly_ϵ, α, β, a_lo[k])
                    isempty(poly_ϵ) && break
                    poly_ϵ = clip_half_plane(poly_ϵ, -α, -β, -a_hi[k])
                    isempty(poly_ϵ) && break
                end
                isempty(poly_ϵ) && continue

                t_min = minimum(v -> v[2], poly_ϵ)
                t_max = maximum(v -> v[2], poly_ϵ)
                iy_lo = clamp(floor(Int, (t_min + H) / Δy), 0, ny - 1)
                iy_hi = clamp(floor(Int, (t_max + H) / Δy), 0, ny - 1)

                edges_ϵ = [(poly_ϵ[j], poly_ϵ[j%length(poly_ϵ)+1]) for j in 1:length(poly_ϵ)]

                for iy in iy_lo:iy_hi
                    t_scr = -H + (iy + ○) * Δy
                    s_min, s_max = W, -W
                    for ((s1, t1), (s2, t2)) in edges_ϵ
                        min(t1, t2) ≤ t_scr ≤ max(t1, t2) || continue
                        abs(t2 - t1) ≤ eps(T) && continue
                        frac = (t_scr - t1) / (t2 - t1)
                        s_cross = s1 + frac * (s2 - s1)
                        s_min = min(s_min, s_cross)
                        s_max = max(s_max, s_cross)
                    end
                    s_min ≤ s_max || continue
                    ix_lo = clamp(floor(Int, (s_min + W) / Δx), 0, nx - 1)
                    ix_hi = clamp(floor(Int, (s_max + W) / Δx), 0, nx - 1)
                    i[ix_lo+1:ix_hi+1, iy+1, ig] .= idx
                end
            end
        else
            a_lo = ϵ_zero .- c
            a_hi = ϵ_one .- c

            poly_ϵ = [(-W, -H), (W, -H), (W, H), (-W, H)]
            for k in 1:N
                α, β = e1[k], e2[k]
                abs(α) + abs(β) ≤ eps(T) && continue
                poly_ϵ = clip_half_plane(poly_ϵ, α, β, a_lo[k])
                isempty(poly_ϵ) && break
                poly_ϵ = clip_half_plane(poly_ϵ, -α, -β, -a_hi[k])
                isempty(poly_ϵ) && break
            end
            isempty(poly_ϵ) && continue

            t_min = minimum(v -> v[2], poly_ϵ)
            t_max = maximum(v -> v[2], poly_ϵ)
            iy_lo = clamp(floor(Int, (t_min + H) / Δy), 0, ny - 1)
            iy_hi = clamp(floor(Int, (t_max + H) / Δy), 0, ny - 1)

            edges_ϵ = [(poly_ϵ[j], poly_ϵ[j%length(poly_ϵ)+1]) for j in 1:length(poly_ϵ)]

            for iy in iy_lo:iy_hi
                t_scr = -H + (iy + ○) * Δy
                s_min, s_max = W, -W
                for ((s1, t1), (s2, t2)) in edges_ϵ
                    min(t1, t2) ≤ t_scr ≤ max(t1, t2) || continue
                    abs(t2 - t1) ≤ eps(T) && continue
                    frac = (t_scr - t1) / (t2 - t1)
                    s_cross = s1 + frac * (s2 - s1)
                    s_min = min(s_min, s_cross)
                    s_max = max(s_max, s_cross)
                end
                s_min ≤ s_max || continue
                ix_lo = clamp(floor(Int, (s_min + W) / Δx), 0, nx - 1)
                ix_hi = clamp(floor(Int, (s_max + W) / Δx), 0, nx - 1)
                i[ix_lo+1:ix_hi+1, iy+1] .= idx
            end
        end
    end

    (i, ΦΦ, p0, e1, e2, d̂, Δx, Δy, c, ẑero, ône, has_gl)
end
# function ∃̇(g::god, ∇=1, Ω=God)
#     v = g.ône - g.ẑero
#     ϵ̂ = β(v, Ω)
#     i = ones(UInt32, g.♯[1], g.♯[2], GL_N)
#     # x = zeros(T, g.♯[1], g.♯[2], GL_N)
#     ΦΦ = Function[ϵ̂ isa 𝕋 ? ○̂ : ϵ̂.Φ]
#     for ϵ = God.ϵ̃[ϵ̂]

#     end
#     project(g, ΦΦ, x, i)
# end
# function screen_basis(v̂)
#     N=length(v̂)
#     axes = sortperm(SVector(ntuple(i -> abs(v̂[i]), N)))
#     e₁ = SVector(ntuple(i -> i == axes[1] ? one(T) : zero(T), N))
#     û = normalize(e₁ - dot(e₁, v̂) * v̂)
#     e₂ = SVector(ntuple(i -> i == axes[2] ? one(T) : zero(T), N))
#     ŵ = normalize(e₂ - dot(e₂, v̂) * v̂ - dot(e₂, û) * û)
#     û, ŵ
# end
# ○_μ = (g.ẑero.μ .+ g.ône.μ) ./ 2
# v = g.ône.μ .- ○_μ
# v = v[2:end]
# using LinearAlgebra: normalize, norm, dot
# r = norm(v)
# v̂ = v ./ r
# screen_basis(v̂)
# screen_basis([1,1,1])
# [1,-1,0]./sqrt(2)
# [1,1,-2]./sqrt(6)
# py, px = divrem(idx - 1, W) .+ (1, 1)
# ξ₁ = T(2px - 1) / T(W) - one(T)
# ξ₂ = T(2py - 1) / T(H) - one(T)
# d̂ = normalize(v̂ .+ g.ρ .* (ξ₁ .* û .+ ξ₂ .* ŵ))
# p = ○_μ .+ (GL_NODES[j] * r) .* d̂
# points[py, px, j] = SVector(ntuple(i -> i ≤ length(p) ? p[i] : ○, N_dims))
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
    g.ẑero !== ○̂ && ∃!(g.ẑero)
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
        ∃(g.ẑero.ϵ̂, g.ẑero.d, SVector(ẑeroμ), g.ẑero.ρ, g.ẑero.∂, g.ẑero.Φ),
        ∃(g.ône.ϵ̂, g.ône.d, SA[ẑeroμ[1], g.ône.μ[2:end]...], g.ône.ρ, g.ône.∂, g.ône.Φ),
        g.∂t₀, g.v, g.ρ, g.Ω, g.⚷, g.♯, g.∇, g.d
    )
movegod(g, d, μ, δ) = move(g, SVector(ntuple(i -> begin
        g.ẑero.d[i] == d && return δ(μ[i], T(0.01))
        μ[i]
    end, length(μ))))
focusup(g, d) = movegod(g, d, g.ône.μ, +)
focusdown(g, d) = movegod(g, d, g.ône.μ, -)
moveup(g, d) = movegod(g, d, g.ẑero.μ, +)
movedown(g, d) = movegod(g, d, g.ẑero.μ, -)
jerkdown(g) = jerk(g, T(-0.01))
jerkup(g) = jerk(g, T(0.01))
scaledown(g) = scale(g, T(-0.01))
scaleup(g) = scale(g, T(0.01))

# focus(g::god, ôneμ) =
#     god(
#         g.ẑero,
#         ∃(g.ône.ϵ̂, g.ône.d, ôneμ, g.ône.ρ, g.ône.∂, g.ône.Φ),
#         g.∂t₀, g.v, g.ρ, g.Ω, g.⚷, g.♯, g.∇
#     )
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
