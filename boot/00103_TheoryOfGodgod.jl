# mutable struct god
#     ẑero::∃
#     ône::∃
#     v::Tuple # dẑero/dt
#     # ♯::NTuple
#     pin::UInt
# end
const WHITE = (one(T), one(T), one(T), one(T))
ρ(μ) = min(μ, 1 - μ)
# function god(dimx, dimy, dimc, x, y, nx, ny, pin=zero(UInt))
#     d = SA[zero(T), dimx, dimy, dimc, one(T)]
#     N = length(d)
#     ṫ = t() ; ρ̇ = ρ(ṫ)
#     μzero = SA[ṫ - ρ̇, x, y, zero(T), one(T)]
#     ∂zero = ntuple(_ -> (true, false), N)
#     zeros = SVector(ntuple(_ -> zero(T), N))
#     ẑero = ∃(God, d, μzero, zeros, ∂zero, _ -> ○)
#     μone = SA[ṫ + ρ̇, one(T), one(T), one(T), one(T)]
#     ∂one = ntuple(_ -> (false, true), N)
#     ône = ∃(God, d, μone, zeros, ∂one, _ -> ○)
#     ♯ = (1, nx, ny, 6, 1)
#     v = ntuple(_ -> zero(T), N)
#     god(ẑero, ône, v, ♯, pin)
# end
# function observe(g::god)
#     ϵ = g.ône - g.ẑero
#     ϕ = ∃̇(ϵ, g.♯)
#     pixel = fill(WHITE, g.♯[2], g.♯[3])
#     # i = collect(CartesianIndices(pixel))[1]
#     for i = CartesianIndices(pixel)
#         r = ϕ[1,i[1], i[2], 2,1]
#         g = ϕ[1,i[1], i[2], 3,1]
#         b = ϕ[1,i[1], i[2], 4,1]
#         a = ϕ[1,i[1], i[2], 5,1]
#         pixel[i[1], i[2]] = if r == g == b == a == ○
#             WHITE
#         else
#             (r, g, b, a)
#         end
#     end
#     pixel
# end
Φ̃(Φ) = ẋ -> begin
    t, x, y, c, _ = ẋ
    r, g, b, a = Φ(t, x, y)
    r == g == b == a == ○ && return one(T)
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
# function create(g::god, Φ)
#     ϵ̂ = g.ône - g.ẑero
#     ϵ̂ = ∃(ϵ̂, ϵ̂.d, ϵ̂.μ, ϵ̂.ρ, ϵ̂.∂, Φ̃(Φ))
#     ∃!(ϵ̂)
# end
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



mutable struct god
    ẑero::∃
    ône::∃
    v::T
    pin::UInt
    visible::Bool
    edge::Bool
    Φ::Function  # self-representation appearance
end

function god(dimx, dimy, dimc, x, y, pin=zero(UInt))
    d = SA[zero(T), dimx, dimy, dimc, one(T)]
    N = length(d)
    ṫ = t()
    μzero = SA[ṫ, x, y, zero(T), zero(T)]
    ∂zero = ntuple(_ -> (true, false), N)
    zeros = SVector(ntuple(_ -> zero(T), N))
    ẑero = ∃(God, d, μzero, zeros, ∂zero, _ -> ○)
    μone = SA[one(T), one(T), one(T), one(T), one(T)]
    ∂one = ntuple(_ -> (false, true), N)
    ône = ∃(God, d, μone, zeros, ∂one, _ -> ○)
    god(ẑero, ône, zero(T), pin, false, true, (t, x, y) -> (○, ○, ○, one(T)))
end

# --- step ---

function step!(g::god, dt̂=one(T))
    if g.edge
        ṫ = t()
        N = length(g.ẑero.μ)
        μz = SVector(ntuple(i -> i == 1 ? ṫ : g.ẑero.μ[i], N))
        g.ẑero = ∃(God, g.ẑero.d, μz, g.ẑero.ρ, g.ẑero.∂, g.ẑero.Φ)
    else
        diff = g.ône.μ .- g.ẑero.μ
        any(d -> !iszero(d), diff) || return
        α = clamp(g.v * dt̂, zero(T), one(T))
        μz = g.ẑero.μ .+ α .* diff
        g.ẑero = ∃(God, g.ẑero.d, μz, g.ẑero.ρ, g.ẑero.∂, g.ẑero.Φ)
    end
    g.visible && present!(g)
end

# --- self-representation ---

function present!(g::god, scale=T(0.1))
    N = length(g.ẑero.μ)
    dir = g.ône.μ .- g.ẑero.μ
    μ_self = g.ẑero.μ .+ scale .* dir
    ṫ = t()
    ṫ_next = t(God.Ο[God] + 1)
    ρ_self = SVector(ntuple(N) do i
        i == 1 && return (ṫ_next - ṫ) / 2
        scale * abs(dir[i]) / 2
    end)
    avatar = ∃(God, g.ẑero.d, μ_self, ρ_self,
               ntuple(_ -> (true, true), N), Φ̃(g.Φ))
    ∃!(avatar)
end

# --- observe ---

function observe(g::god, ♯::NTuple)
    ϵ = g.ône - g.ẑero
    ϕ = ∃̇(ϵ, ♯)
    @show ϕ[1, 2, 2, :, 1]
    pixel = fill(WHITE, ♯[2], ♯[3])
    for i = CartesianIndices(pixel)
        r = ϕ[1, i[1], i[2], 2, 1]
        ġ = ϕ[1, i[1], i[2], 3, 1]
        b = ϕ[1, i[1], i[2], 4, 1]
        a = ϕ[1, i[1], i[2], 5, 1]
        pixel[i[1], i[2]] = r == ġ == b == a == ○ ? WHITE : (r, ġ, b, a)
    end
    # if show_borders
    #     Ξ = X(ϵ, ♯)
    #     for i = CartesianIndices(pixel)
    #         for δ in (CartesianIndex(1, 0), CartesianIndex(0, 1))
    #             j = i + δ
    #             checkbounds(Bool, Ξ, 1, j[1], j[2], 1, 1) || continue
    #             if Ξ[1, i[1], i[2], 1, 1] !== Ξ[1, j[1], j[2], 1, 1]
    #                 pixel[i[1], i[2]] = (zero(T), zero(T), zero(T), one(T))
    #                 break
    #             end
    #         end
    #     end
    # end
    pixel
end

# --- create ---

function create(g::god, Φ)
    ϵ̂ = g.ône - g.ẑero
    ϵ̂ = ∃(ϵ̂, ϵ̂.d, ϵ̂.μ, ϵ̂.ρ, ϵ̂.∂, Φ̃(Φ))
    ∃!(ϵ̂)
end

# --- controls ---

function move_zero!(g::god, dim::Int, val)
    μ = MVector(g.ẑero.μ)
    μ[dim] = clamp(T(val), zero(T), one(T))
    g.ẑero = ∃(God, g.ẑero.d, SVector(μ), g.ẑero.ρ, g.ẑero.∂, g.ẑero.Φ)
    dim == 1 && (g.edge = false)
end

function move_one!(g::god, dim::Int, val)
    μ = MVector(g.ône.μ)
    μ[dim] = clamp(T(val), zero(T), one(T))
    g.ône = ∃(God, g.ône.d, SVector(μ), g.ône.ρ, g.ône.∂, g.ône.Φ)
    dim == 1 && (g.edge = false)
end

speed!(g::god, v) = g.v = clamp(T(v), zero(T), one(T))
appear!(g::god, Φ::Function) = g.Φ = Φ
show!(g::god) = g.visible = true
hide!(g::god) = g.visible = false
home!(g::god) = (g.edge = true; g.v = zero(T))
