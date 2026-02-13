mutable struct god
    ẑero::∃
    ône::∃
    v::Tuple # dt/dt̂ ; dẑero[2:end-2]/dt
    ♯::NTuple
    pin::UInt
end
# g = god{T}(dimx, dimy, dimc, x, y, T(5), T(3))
# nx, ny=T(5), T(3)
# function god(dimx, dimy, dimc, x, y, nx, ny)
function god(dimx, dimy, dimc, x, y, nx, ny, pin=zero(UInt))
    d = SA[zero(T), dimx, dimy, dimc, one(T)]
    N = length(d)
#     # ∂ = fill(true, 2 * length(d))
    ∂zero = ntuple(_ -> (true, false), N)
    μzero = SA[t(), x, y, ○, ○]
#     # ρzero = SA[zero(T), one(T)-x, one(T)-y, ○, zero(T)]
    ẑeros = @SVector zeros(T, N)
    ẑero = ∃(God, d, μzero, ẑeros, ∂zero, _ -> ○)
    μone = @SVector ones(T, N)
    # ρone = @SVector zeros(T, 5)
    ∂one = ntuple(_ -> (false, true), N)
    ône = ∃(God, d, μone, ẑeros, ∂one, _ -> ○)
#     # ∃{T}("one(∀)", [zero(T), one(T)], [one(T), one(T)], [zero(T), zero(T)], fill(true, 4), _ -> ○(T), God, ∃{T}[])
    # ♯ = Grid([1, nx, ny, 6, 1])
    ♯ = (1, nx, ny, 6, 1)
#     # ♯ = (0, nx, ny, 3, 0)
#     v = (zero(T), zero(T), zero(T))
    v = ntuple(_ -> zero(T), N)
    # god{5}(♯, ẑero, ône, v)
#     # god(♯, ẑero, one(God), v)
    god(ẑero, ône, v, ♯, pin)
end
# length(collect(keys(Ξ)))
# 1 2 3 4 5 6
# 0 0.2 0.4 0.6 0.8 1
# 0.25 0.5 0.75 1.0
const WHITE = (one(T), one(T), one(T), one(T))
function observe(g::god)
    ϵ = g.ône - g.ẑero
    # pixel = fill(ntuple(_ -> (one(T)), 5), ♯[1], ♯[2])
    pixel = fill(WHITE, g.♯[2], g.♯[3])
    # pixel = fill((one(T), one(T), one(T)), ♯[1], ♯[2])
    # x = ∃(g.♯, God)
    # x = ∃̇(g.♯, ϵ, God)
    # x = ∃̇(ϵ, God, g.♯)
    # ♯̂ = ntuple(i -> begin
    #         i == 1 && return 1
    #         i == 2 && return ♯[1]
    #         i == 3 && return ♯[2]
    #         i == 4 && return 4
    #         1
    #         # i == length(ϵ.d) && return 
    #     end, length(ϵ.d))
    ϕ = ∃̇(ϵ, g.♯)
    # i = collect(CartesianIndices(pixel))[1]
    for i = CartesianIndices(pixel)
        r = ϕ[1, i[1], i[2], 2, 1]
        g = ϕ[1, i[1], i[2], 3, 1]
        b = ϕ[1, i[1], i[2], 4, 1]
        a = ϕ[1, i[1], i[2], 5, 1]
        # r = ϕ[i[1], i[2], 2]
        # g = ϕ[i[1], i[2], 3]
        # b = ϕ[i[1], i[2], 4]
        # r == g == b == a == ○(T) && begin @show "1/2",i ; r, g, b, a = (one(T), one(T), one(T), one(T)) end
        pixel[i[1], i[2]] = if r == g == b == a == ○
        # pixel[i[1], i[2]] = if r == g == b == ○
            WHITE
            # (one(T), one(T), one(T))
        else
            (r, g, b, a)
            # (r, g, b)
        end
        # @show i, r == g == b == a == ○(T), r, g, b, a
    end
    pixel
end
Φ̃(Φ) = ẋ -> begin
    # @show ẋ
    # zero(T)
    # @show "∃̂(∃̇)", x̂.μ
    # _, x, y, c, _ = ẋ.μ
    t, x, y, c, _ = ẋ
    # x, y, c = ẋ.μ
    # x, y, c = ẋ
    # # @show "∃̂(∃̇)", t, x, y, c
    # # @show "∃̂(∃̇)", ∃̇
    # # return ∃̇(0.1,0.2,0.3)
    # # return ∃̇(t, x, y)
    # # r, g, b, a = ∃̇(t, x, y)
    r, g, b, a = Φ(t, x, y)
    # # @show "∃̂(∃̇)", r, g, b, a
    r == g == b == a == ○ && return one(T)
    # r == g == b == ○ && return one(T)
    # # @show "∃̂(∃̇) ..."
    c∂ = one(T) / 4
    # c∂ = one(T) / 3
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
# name="circle"
# ∃̇2=(t, x, y) -> begin
# # @show "hi"
#     # @show name, t, x, y, x^2 + y^2
#     # x^2 + y^2 == 0.01 ? (T(rand()), T(rand()), T(rand()), one(T)) : (○(T), ○(T), ○(T), ○(T))
#     @show name, t, x, y
#     T(rand()), T(rand()), T(rand()), one(T)
# end
# function create(g::god, ∃̇, ϵ)
function create(g::god, Φ)
    ϵ̂ = g.ône - ẑero
    # ϵ̂ = -(g.ône, g.ẑero, God, Φ̃(Φ))
    # ϵ̇ = g.ẑero + ϵ
    ϵ̂ = ∃(ϵ̂, ϵ̂.d, ϵ̂.μ, ϵ̂.ρ, ϵ̂.∂, Φ̃(Φ))
    # ϵ̂ = ∃{T}(name, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ∃̃(∃̇2), God, ∃{T}[])
    # ϵ̃ = ∃(ϵ̂, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ∃̃(∃̇))
    # ∃!(ϵ̃, God)
    ∃!(ϵ̂)
end
accelerate!(g::god, v) = g.v = v
jerk!(g::god, j) = accelerate(g, g.v^j) # ?
stop!(g::god) = accelerate(g, ntuple(_ -> zero(g.T), 3))
turn!(g::god, ône) = g.ône = ône
# scale!(g::god, ♯) = g.♯ = ♯

# ẑero, ône=g.ẑero, g.ône
# ône-ẑero

# ẑero.d
# ẑero.μ
# μρ(ẑero, d)
# ϵ, d=ẑero, d
# (i, d) = collect(enumerate(d̂))[5]
# function Base.:(-)(ône::∃, ẑero::∃)
#     # d̂ = sort(unique(ẑero.d ∪ ône.d)) # todo sort vs unique order
#     μ = @MVector fill(○, length(ẑero.d))
#     ρ = @MVector fill(○, length(ẑero.d))
#     for (i, d) = enumerate(ẑero.d)
#         ẑeroμ, _ = μρ(ẑero, d)
#         ôneμ, _ = μρ(ône, d)
#         ρ[i] = (ôneμ - ẑeroμ) / 2
#         μ[i] = ẑeroμ + ρ[i]
#     end
#     # ∂ = fill(true, 2*length(ẑero.d))
#     ∂ = ntuple(i -> iseven(i) ? ône.∂[i] : ẑero.∂[i], length(ẑero.d))
#     ∃(God, ẑero.d, SVector(μ), SVector(ρ), ∂, _ -> ○)
# end
# function Base.:(-)(ône::∃, ẑero::∃, God::𝕋)
#     d̂ = sort!(ẑero.d ∪ ône.d)
#     N = length(d̂)
#     μ = MVector{N,T}(undef)
#     ρ = MVector{N,T}(undef)
#     ∂out = Vector{Tuple{Bool,Bool}}(undef, N)
#     for (i, d) in enumerate(d̂)
#         ẑeroμ, ẑeroρ, ẑero∂ = μρ(ẑero, d)
#         ôneμ, ôneρ, ône∂ = μρ(ône, d)
#         lo = ẑeroμ - ẑeroρ
#         hi = ôneμ + ôneρ
#         ρ[i] = (hi - lo) / 2
#         μ[i] = lo + ρ[i]
#         ∂out[i] = (ẑero∂[1], ône∂[2])
#     end
#     ϵ̂ = α(ône, ẑero, God)
#     ∃(ϵ̂, SVector{N}(d̂), SVector{N}(μ), SVector{N}(ρ), NTuple{N}(∂out), ône.Φ)
# end
# Base.:(+)(ône::∃, ẑero::∃) = ∃(ône, ẑero.d, ẑero.μ + ône.μ, ẑero.ρ, ẑero.∂, _ -> ○)
# ∇(t) = t*g.ône-(1-t)*g.ẑero
# ∇(0) = g.ẑero
# ∇(1) = g.ône
# t(ẑero), t̂
# speed = dt(ẑero)/dt̂, dx/dt(ẑero), dy/dt(ẑero)
# t = 1 - 1/(1+log(C)) = log(C)/(1+log(C))
# dt(ẑero) = speed[1]*dt̂
function step!(g::god, dt̂)
    dt = g.v[1] * dt̂
    g.ẑero.μ[1] += dt
    g.ẑero.μ[2:end-2] .+= g.ẑero.v[2:end-2] * dt
    g.ẑero.ρ[2:end-2] .-= g.ẑero.μ[2:end-2]
    # dx = g.v[2] * dt
    # dy = g.v[3] * dt
    # μ = SA[g.ẑero.μ[1]+dt, g.ẑero.μ[2]+dx, g.ẑero.μ[3]+dy, ○, ○]
    # ρ = SA[zero(T), one(T)-μ[2], one(T)-μ[3], ○, ○]
    # g.ẑero = ∃(God, g.ẑero.d, μ, ρ, g.ẑero.∂, _ -> ○)
end
