struct god
    # {F,FI}
    ẑero::∃
    ône::∃
    v::T
    # ℼ::F
    # ℼ̂::FI
    owner::UInt
    secret::UInt
    present::Bool
    visible::Bool
    border::Bool
end
function secret_dims(secret::UInt)
    iszero(secret) && return rand(T), rand(T)
    h = hash(secret)
    m = T(typemax(typeof(secret)))
    T(h >> 32) / m, T(h & m) / m
end
function scramble_index(i, secret::UInt, ♯)
    ntuple(length(♯)) do d
        mod1(i[d] + secret, ♯[d])
    end
end
function unscramble_index(i, secret::UInt, ♯)
    ntuple(length(♯)) do d
        mod1(i[d] + ♯[d] - secret, ♯[d])
    end
end
# secret = UInt(8);
# grid = [1 2 3;
#         4 5 6;
#         7 8 9];
# scrambled = similar(grid);
# for i in CartesianIndices(grid)
#     j = CartesianIndex(scramble_index(Tuple(i), secret, ♯))
#     scrambled[j] = grid[i]
# end
# scrambled
# recovered = similar(grid);
# for i in CartesianIndices(scrambled)
#     j = CartesianIndex(scramble_index(Tuple(i), secret, ♯))
#     recovered[i] = scrambled[j]
# end
# recovered
const WHITE = (one(T), one(T), one(T), one(T))
# ρ(μ) = min(μ, 1 - μ)
function god(spatial_dims::NTuple, spatial_pos::NTuple, owner=zero(UInt), secret=zero(UInt), Φ=_ -> ○)
    doverlay₁, doverlay₂ = secret_dims(secret)
    d = SVector(zero(T), doverlay₁, doverlay₂, ○, spatial_dims..., one(T))
    N = length(d)
    μzero = SA[t(), zero(T), zero(T), zero(T), spatial_pos..., zero(T)]
    ∂zero = ntuple(_ -> (true, false), N)
    zeros = SVector(ntuple(_ -> zero(T), N))
    ẑero = ∃(God, d, μzero, zeros, ∂zero, Φ)
    μone = SVector(ntuple(_ -> one(T), N))
    ∂one = ntuple(_ -> (false, true), N)
    ône = ∃(God, d, μone, zeros, ∂one, _ -> ○)
    # god(ẑero, ône, zero(T), ℼ, ℼ̂, owner, secret, true, false, false)
    god(ẑero, ône, zero(T), owner, secret, true, false, false)
end
function grid_coord(i, ♯; near=T(0.01))
    isone(♯) && return ○
    t = (T(i) - one(T)) / T(♯ - 1)  # linear [0,1]
    near * (one(T) / near)^t        # geometric expansion
end
# grid_coord(2, 5)
function observe(g::god, ♯)
    ϵ = g.ône - g.ẑero
    ϕ = ∃̇(ϵ, ♯)
    ℼ̂(ϕ)
end
ℼ(Φ) = x -> begin
    t, _, _, c, ẋ... = x
    r, g, b, a = Φ(t, ẋ...)
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
ℼ̂(ϕ) = begin
    pixel = fill(WHITE, size(ϕ, 5), size(ϕ, 6))
    # i = collect(CartesianIndices(pixel))[1]
    for i = CartesianIndices(pixel)
        r = ϕ[1, 1, 1, 2, Tuple(i)..., 1]
        g = ϕ[1, 1, 1, 3, Tuple(i)..., 1]
        b = ϕ[1, 1, 1, 4, Tuple(i)..., 1]
        a = ϕ[1, 1, 1, 5, Tuple(i)..., 1]
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
function step!(g::god, dt̂=one(T))
    if g.present
        ṫ = t()
        N = length(g.ẑero.μ)
        μ = SVector(ntuple(i -> i == 1 ? ṫ : g.ẑero.μ[i], N))
        g.ẑero = ∃(God, g.ẑero.d, μ, g.ẑero.ρ, g.ẑero.∂, g.ẑero.Φ)
    else
        δμ = g.ône.μ .- g.ẑero.μ
        any(d -> !iszero(d), δμ) || return
        α = clamp(g.v * dt̂, zero(T), one(T))
        μ = g.ẑero.μ .+ α .* diff
        g.ẑero = ∃(God, g.ẑero.d, μ, g.ẑero.ρ, g.ẑero.∂, g.ẑero.Φ)
    end
    # g.visible && present!(g)
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
