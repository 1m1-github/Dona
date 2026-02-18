struct god
    ẑero::∃
    ône::∃
    ∂t₀::Bool
    v::T
    ρ::T
    Ω::𝕋
    ⚷::UInt
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
        effective = mod(⚷, ♯[d])
        mod1(i[d] + ♯[d] - effective, ♯[d])
    end
end
const WHITE = (one(T), one(T), one(T), one(T))
function god(d::NTuple, μ::NTuple, ⚷=zero(UInt), Φ=_ -> ○)
    d̂ = SVector(zero(T), d..., one(T))
    N = length(d̂)
    μ₀ = SA[t(), μ..., zero(T)]
    ∂₀ = ntuple(_ -> (true, false), N)
    zeros = SVector(ntuple(_ -> zero(T), N))
    ẑero = ∃(God, d̂, μ₀, zeros, ∂₀, Φ)
    μ₁ = SVector(ntuple(_ -> one(T), N))
    ∂₁ = ntuple(_ -> (false, true), N)
    ône = ∃(God, d̂, μ₁, zeros, ∂₁, _ -> ○)
    god(ẑero, ône, true, zero(T), zero(T), 𝕋(), ⚷)
end
# function log_z_grid(N::Int; z_near=0.01, z_far=1.0)
#     ratio = z_far / z_near
#     Float32[z_near * ratio ^ (i / (N - 1)) for i in 0:(N-1)]
# end
# ϵ=ϵᵩ
function ∃̇(g::god, ♯, ∇=typemax(Int))
    ϵᵩ = g.ône - g.ẑero
    ϕᵩ = ∃̇(ϵᵩ, ♯, ∇)
    pixels = ℼ̂(ϕᵩ)
    for ϵ = g.Ω
        isreal(ϵ) || continue
        ϕ = ∃̇(ϵ, ♯)
        composite!(pixels, ϕ, ♯)
    end
    pixels
end
struct ℼStruct{F}
    Φ::F
end
@inline function (p::ℼStruct)(t, x, y, z, c)
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
ℼ(Φ) = ℼStruct(Φ)
# ℼ(Φ) = ẋ -> begin
#     t, x, y, z, c = ẋ
#     r, g, b, a = Φ(t, x, y, z)
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
ℼ̂(ϕ) = begin
    pixel = fill(WHITE, size(ϕ, 2), size(ϕ, 3))
    # i = collect(CartesianIndices(pixel))[1]
    for i = CartesianIndices(pixel)
        r = ϕ[1, Tuple(i)..., 2]
        g = ϕ[1, Tuple(i)..., 3]
        b = ϕ[1, Tuple(i)..., 4]
        a = ϕ[1, Tuple(i)..., 5]
        pixel[i] = r == g == b == a == ○ ? WHITE : (r, g, b, a)
    end
    pixel
end
function create(g::god, Φ)
    ϵ = g.ône - g.ẑero
    ϵ = ∃(ϵ, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ℼ(Φ))
    ∃!(ϵ)
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
    god(ẑero, g.ône, g.∂t₀, g.v, g.ρ, g.Ω, g.⚷)
    # present!(g)
end
# function present!(g::god, scale=T(0.1))
#     N = length(g.ẑero.μ)
#     dir = g.ône.μ .- g.ẑero.μ
#     μ_self = g.ẑero.μ .+ scale .* dir
#     ṫ = t()
#     ṫ_next = t(God.Ο[God] + 1)
#     ρ_self = SVector(ntuple(N) do i
#         i == 1 && return (ṫ_next - ṫ) / 2
#         scale * abs(dir[i]) / 2
#     end)
#     avatar = ∃(God, g.ẑero.d, μ_self, ρ_self,
#                ntuple(_ -> (true, true), N), Φ̃(g.Φ))
#     ∃!(avatar)
# end
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
