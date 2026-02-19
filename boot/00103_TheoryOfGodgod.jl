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
end
function god(; d, μ, ⚷=zero(UInt), Φ=○̂, ♯=(1, 1, 1), ∇=typemax(UInt))
    @assert zero(T) ∉ d
    @assert one(T) ∉ d
    d̂ = SA[zero(T), d..., one(T)]
    N = length(d̂)
    μ₀ = SA[t(), μ..., zero(T)]
    ∂₀ = ntuple(_ -> (true, false), N)
    zeros = @SVector zeros(T, N)
    ẑero = ∃(God, d̂, μ₀, zeros, ∂₀, Φ)
    μ₁ = @SVector ones(T, N)
    ∂₁ = ntuple(_ -> (false, true), N)
    ône = ∃(God, d̂, μ₁, zeros, ∂₁, ○̂)
    ♯̂ = (1, ♯..., 6)
    god(ẑero, ône, true, zero(T), zero(T), 𝕋(), ⚷, ♯̂, ∇)
end
isreal(ϵ::∃) = √(ϵ) === God
function dh(⚷, g, n)
    powermod(g, ⚷, n)
end
function ⚷⚷(⚷, dh)
    powermod(dh, ⚷, DH_N)
end
function ⚷i(i, ⚷, ♯)
    ntuple(length(♯)) do d
        mod1(i[d] + ⚷, ♯[d])
    end
end
function i⚷(i, ⚷, ♯)
    ntuple(length(♯)) do d
        î = mod(⚷, ♯[d])
        mod1(i[d] + ♯[d] - î, ♯[d])
    end
end
function create(g::god, Φ, Ω=God)
    ϵ = g.ône - g.ẑero
    ϵ = ∃(ϵ, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, Φ)
    # ϵ = ∃(ϵ, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ℼ(Φ))
    ∃!(ϵ, Ω)
end
function ∃̇(g::god)
    ϵ = g.ône - g.ẑero
    ϵ̂ = X(ϵ, g.♯, g.∇)
    î = fill(zero(UInt), size(ϵ̂))
    ϵ∃ = filter(ϵ -> ϵ !== God, ϵ̂)
    unique!(t, ϵ∃)
    sort!(ϵ∃, by=t)
    ϵΠ = ntuple(i -> ϵ∃[1].Φ, length(ϵ∃))
    ϵt = map(t, ϵ∃)
    # Threads.@threads
    for i = CartesianIndices(ϵ̂)
        ϵ̂ᵢ = ϵ̂[i]
        ϵ̂ᵢ === God && continue
        ϵ̂ᵢt = t(ϵ̂ᵢ)
        î[i] = findfirst(t -> t == ϵ̂ᵢt, ϵt)
    end
    # ♯̇ = fill(○, ♯...)
    ϕ = gpu(ϵΠ, î, g.♯)
    # Threads.@threads
    # for (i₁, i₂) = enumerate(i)
    #     ♯̇[i₂] = Φ̇[i₁]
    # end
    # end
    # ♯̇
    pixels = ℼ̂(ϕ)
    # for ϵ̃ = g.Ω
    #     isreal(ϵ̃) || continue
    #     ϕ = ∃̇(ϵ̃, ♯)
    #     composite!(pixels, ϕ, ♯)
    # end
    # pixels
end
# ℼ(Φ) = ẋ -> begin
#     r, g, b, a = Φ(ẋ[1], ẋ[2], ẋ[3], ẋ[4])
#     r == g == b == a == ○ && return one(T)
#     c∂ = one(T) / 4
#     if c < c∂
#         r
#     elseif c < 2 * c∂
#         g
#     elseif c < 3 * c∂
#         b
#     else
#         a
#     end
# end
const WHITE = (one(T), one(T), one(T), one(T))
ℼ̂(ϕ) = begin
    pixel = fill(WHITE, size(ϕ, 2), size(ϕ, 3))
    # i = collect(CartesianIndices(pixel))[1]
    for i = CartesianIndices(pixel)
        r = ϕ[1, Tuple(i)...]
        g = ϕ[1, Tuple(i)...]
        b = ϕ[1, Tuple(i)...]
        a = ϕ[1, Tuple(i)...]
        # r = ϕ[1, Tuple(i)..., 2]
        # g = ϕ[1, Tuple(i)..., 3]
        # b = ϕ[1, Tuple(i)..., 4]
        # a = ϕ[1, Tuple(i)..., 5]
        pixel[i] = r == g == b == a == ○ ? WHITE : (r, g, b, a)
    end
    pixel
end
# accelerate!(g::god, v) = g.v = v
# jerk!(g::god, j) = accelerate(g, g.v^j) # ?
# stop!(g::god) = accelerate(g, ntuple(_ -> zero(g.T), 3))
# turn!(g::god, ône) = g.ône = ône
# # scale!(g::god, ♯) = g.♯ = ♯

# # ∇(t) = t*g.ône-(1-t)*g.ẑero
# # ∇(0) = g.ẑero
# # ∇(1) = g.ône
# # t(ẑero), t̂
# # speed = dt(ẑero)/dt̂, dx/dt(ẑero), dy/dt(ẑero)
# # t = 1 - 1/(1+log(C)) = log(C)/(1+log(C))
# # dt(ẑero) = speed[1]*dt̂
# # dt̂=0.01
# # step!(g, dt̂)
# # wip
# function step!(g::god, dt̂)
#     dt = g.v[1] * dt̂
#     # g.ẑero.μ[1] += dt
#     # dt = Ο(g.ẑero.μ[1] + g.v[1])
#     # Ο(0.40938)
#     # t(1)
#     N = length(g.ẑero.μ)
#     μ = SVector(ntuple(N) do i
#         3 < i && return g.ẑero.μ[i]
#         i == 1 && return min(g.ẑero.μ[1] + dt, one(T))
#         min(g.ẑero.μ[i] + g.v[i] * dt, one(T))
#     end)
#     ρ = SVector(ntuple(N) do i
#         (i == 2 || i == 3) && return min(g.ẑero.ρ[i], μ[i], one(T) - μ[i])
#         g.ẑero.ρ[i]
#     end)
#     g.ẑero = ∃(g.ẑero.ϵ̂, g.ẑero.d, μ, ρ, g.ẑero.∂, g.ẑero.Φ)
# end
# ρ(μ) = min(μ, 1 - μ)
function step(g::god, dt̂=one(T))
    if g.∂t₀
        ṫ = t()
        μ = SVector(ntuple(i -> i == 1 ? ṫ : g.ẑero.μ[i], length(g.ẑero.μ)))
    else
        δμ = g.ône.μ .- g.ẑero.μ
        # any(d -> !iszero(d), δμ) || return
        α = clamp(g.v * dt̂, zero(T), one(T))
        μ = g.ẑero.μ .+ α .* δμ
    end
    ẑero = ∃(God, g.ẑero.d, μ, g.ẑero.ρ, g.ẑero.∂, g.ẑero.Φ)
    god(ẑero, g.ône, g.∂t₀, g.v, g.ρ, g.Ω, g.⚷, g.♯, g.∇)
    g.ẑero !== ○̂ && ∃!(g.ẑero)
end
# function observe(g::god, ♯::NTuple)
#     ϵ = g.ône - g.ẑero
#     ϕ = ∃̇(ϵ, ♯)
#     @show ϕ[1, 2, 2, :, 1]
#     pixel = fill(WHITE, ♯[2], ♯[3])
#     for i = CartesianIndices(pixel)
#         r = ϕ[1, i[1], i[2], 2, 1]
#         ġ = ϕ[1, i[1], i[2], 3, 1]
#         b = ϕ[1, i[1], i[2], 4, 1]
#         a = ϕ[1, i[1], i[2], 5, 1]
#         pixel[i[1], i[2]] = r == ġ == b == a == ○ ? WHITE : (r, ġ, b, a)
#     end
#     # if show_borders
#     #     Ξ = X(ϵ, ♯)
#     #     for i = CartesianIndices(pixel)
#     #         for δ in (CartesianIndex(1, 0), CartesianIndex(0, 1))
#     #             j = i + δ
#     #             checkbounds(Bool, Ξ, 1, j[1], j[2], 1, 1) || continue
#     #             if Ξ[1, i[1], i[2], 1, 1] !== Ξ[1, j[1], j[2], 1, 1]
#     #                 pixel[i[1], i[2]] = (zero(T), zero(T), zero(T), one(T))
#     #                 break
#     #             end
#     #         end
#     #     end
#     # end
#     pixel
# end
# function move_zero!(g::god, dim::Int, val)
#     μ = MVector(g.ẑero.μ)
#     μ[dim] = clamp(T(val), zero(T), one(T))
#     g.ẑero = ∃(God, g.ẑero.d, SVector(μ), g.ẑero.ρ, g.ẑero.∂, g.ẑero.Φ)
#     dim == 1 && (g.present = false)
# end
# function move_one!(g::god, dim::Int, val)
#     μ = MVector(g.ône.μ)
#     μ[dim] = clamp(T(val), zero(T), one(T))
#     g.ône = ∃(God, g.ône.d, SVector(μ), g.ône.ρ, g.ône.∂, g.ône.Φ)
#     dim == 1 && (g.present = false)
# end
# speed!(g::god, v) = g.v = clamp(T(v), zero(T), one(T))
# appear!(g::god, Φ::Function) = g.Φ = Φ
# show!(g::god) = g.visible = true
# hide!(g::god) = g.visible = false
# home!(g::god) = (g.edge = true; g.v = zero(T))

# ϵΠ
# î
# all(iszero.(î))
# ♯=g.♯
# Φ̇ = gpu(ϵΠ, î, g.♯)
function gpu(ϵΠ, î, ♯)
    rgba = KernelAbstractions.zeros(GPU_BACKEND, T, 4, ♯[2:end-2]...)
    i̇ = KernelAbstractions.allocate(GPU_BACKEND, UInt32, size(î))
    copyto!(i̇, î)
    κ!(GPU_BACKEND, GPU_BACKEND_WORKGROUPSIZE)(
        rgba, ϵΠ, i̇, ♯,
        ndrange=(♯[2], ♯[3])
    )
    KernelAbstractions.synchronize(GPU_BACKEND)
    Array(rgba)
end
@kernel function κ!(rgba, Φ, Φi, ♯)
    xi, yi = @index(Global, NTuple)
    # xi, yi=2,2
    t = ○
    x = isone(♯[2]) ? ○ : (T(xi) - 1) / T(♯[2] - 1)
    y = isone(♯[3]) ? ○ : (T(yi) - 1) / T(♯[3] - 1)
    r, g, b, a = zero(T), zero(T), zero(T), zero(T)
    # zi = collect(1:♯[4])[2]
    for zi = 1:♯[4]
        one(T) ≤ a && break
        z = isone(♯[4]) ? ○ : T(zi - 1) / T(♯[4] - 1)
        Φi̇ = Φi[1, xi, yi, zi, 2]
        # Φi̇ = î[1, xi, yi, zi, 2]
        iszero(Φi̇) && continue
        Φ̃ = Φ[Φi̇]
        # for ci = 1:6
            # c = T(ci - 1) / 5
            # ṙ, ġ, ḃ, ȧ = Φ̃(t, x, y, z, c)
            ṙ, ġ, ḃ, ȧ = Φ̃(t, x, y, z)
            # ϕ = Φ̃(t, x, y, z, c)
            iszero(ȧ) && continue
            rem = one(T) - a
            r += ṙ * ȧ * rem
            g += ġ * ȧ * rem
            b += ḃ * ȧ * rem
            a += ȧ * rem
        # end
    end
    rgba[1, xi, yi] = r
    rgba[2, xi, yi] = g
    rgba[3, xi, yi] = b
    rgba[4, xi, yi] = a
end
# X(i, ♯::NTuple) = SVector{length(♯)}([isone(♯[î]) ? ○ : T(i[î] - 1) / T(♯[î] - 1) for î = eachindex(♯)])
X(i, ♯) = ntuple(î -> begin
        isone(♯[î]) && return ○
        # î == 4 && return # todo depth log spacing
        T(i[î] - 1) / T(♯[î] - 1)
        # T(i[î]) / T(♯[î] + 1)
    end, length(♯))
# X((1,1,1,1,1), (1,2,3,4,6))
# function log_z_grid(N::Int; z_near=0.01, z_far=1.0)
#     ratio = z_far / z_near
#     Float32[z_near * ratio ^ (i / (N - 1)) for i in 0:(N-1)]
# end
# i = collect(CartesianIndices(Ξ))[23]
# Ξ[i].Φ(1)
function X(ϵ::∃, ♯::NTuple, ∇)
    Ξ = Array{∀}(undef, ♯...)
    ρ₀ = zero(ϵ.ρ)
    # Threads.@threads
    for i in CartesianIndices(Ξ)
        x = X(i, ♯)
        # xϵ = ∃(God, ϵ.d, x, ρ₀, ϵ.∂, ϵ.Φ)
        xϵ = ∃(God, ϵ.d, SVector(x), ρ₀, ϵ.∂, ϵ.Φ)
        Ξ[i], _ = X(xϵ, ∇)
    end
    Ξ
end
