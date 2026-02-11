mutable struct god{N,T<:Real}
    ♯::NTuple{N,Int}
    ẑero::∃{N,T}
    ône::∃{N,T}
    v::Tuple{T,T,T} # dt(ẑero)/dt̂, dx/dt(ẑero), dy/dt(ẑero)
end
# g = god{T}(dimx, dimy, dimc, x, y, T(5), T(3))
# nx, ny=T(5), T(3)
function god{T}(dimx, dimy, dimc, x, y, nx, ny) where {T<:Real}
    d = SA[zero(T), dimx, dimy, dimc, one(T)]
    # ∂ = fill(true, 2 * length(d))
    ∂zero = ntuple(_ -> (true, false), length(d))
    μzero = SA[t(GOD), x, y, ○(T), ○(T)]
    ρzero = SA[zero(T), one(T)-x, one(T)-y, ○(T), zero(T)]
    ẑero = ∃{5,T}(GOD, "", d, μzero, ρzero, ∂zero, (_,_,_) -> ○(T))
    μone = @SVector ones(T, 5)
    ρone = @SVector zeros(T, 5)
    ∂one = ntuple(_ -> (false, true), length(d))
    ône = ∃{5,T}(GOD, "", d, μone, ρone, ∂one, (_,_,_) -> ○(T))
    # ∃{T}("one(∀)", [zero(T), one(T)], [one(T), one(T)], [zero(T), zero(T)], fill(true, 4), _ -> ○(T), GOD, ∃{T}[])
    # ♯ = Grid([1, nx, ny, 6, 1])
    # ♯ = (1, nx, ny, 6, 1)
    ♯ = (0, nx, ny, 3, 0)
    v = (zero(T), zero(T), zero(T))
    god{5,T}(♯, ẑero, ône, v)
    # god(♯, ẑero, one(GOD), v)
end
# length(collect(keys(Ξ)))
# 1 2 3 4 5 6
# 0 0.2 0.4 0.6 0.8 1
# 0.25 0.5 0.75 1.0
function observe(g::god)
    ϵ = g.ône - g.ẑero
    pixel = fill((one(T), one(T), one(T), one(T)), g.♯[2], g.♯[3])
    # x = ∃(g.♯, GOD)
    # x = ∃̇(g.♯, ϵ, GOD)
    x = ∃̇(g.♯, GOD)
    # i = collect(CartesianIndices(pixel))[1]
    for i = CartesianIndices(pixel)
        r = x[1, i[1], i[2], 2, 1]
        g = x[1, i[1], i[2], 3, 1]
        b = x[1, i[1], i[2], 4, 1]
        a = x[1, i[1], i[2], 5, 1]
        # r == g == b == a == ○(T) && begin @show "1/2",i ; r, g, b, a = (one(T), one(T), one(T), one(T)) end
        pixel[i[1], i[2]] = if r == g == b == a == ○(T)
            (one(T), one(T), one(T), one(T))
        else
            (r, g, b, a)
        end
        # @show i, r == g == b == a == ○(T), r, g, b, a
    end
    pixel
end
∃̃(∃̇) = (x̂, Φ̇, ẋ) -> begin
    # @show "∃̂(∃̇)", x̂.μ
    t, x, y, c, _ = x̂.μ
    # @show "∃̂(∃̇)", t, x, y, c
    # @show "∃̂(∃̇)", ∃̇
    # return ∃̇(0.1,0.2,0.3)
    # return ∃̇(t, x, y)
    r, g, b, a = ∃̇(t, x, y)
    # @show "∃̂(∃̇)", r, g, b, a
    r == g == b == a == ○(T) && return one(T)
    # @show "∃̂(∃̇) ..."
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
# name="circle"
# ∃̇2=(t, x, y) -> begin
# # @show "hi"
#     # @show name, t, x, y, x^2 + y^2
#     # x^2 + y^2 == 0.01 ? (T(rand()), T(rand()), T(rand()), one(T)) : (○(T), ○(T), ○(T), ○(T))
#     @show name, t, x, y
#     T(rand()), T(rand()), T(rand()), one(T)
# end
function create(g::god{N,T}, name, ∃̇, ϵ) where {N,T<:Real}
    ϵ̂ = g.ône - g.ẑero
    ϵ̇ = g.ẑero + ϵ
    ϵ̃ = ∃{N,T}(ϵ̂, name, ϵ̇.d, ϵ̇.μ, ϵ̇.ρ, ϵ̇.∂, ∃̃(∃̇))
    # ϵ̂ = ∃{T}(name, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ∃̃(∃̇2), GOD, ∃{T}[])
    ∃!(ϵ̃, GOD)
end
accelerate(g::god, v) = g.v = v
jerk(g::god, j) = accelerate(g, g.v^j) # todo ?
stop(g::god) = accelerate(g, ntuple(_ -> zero(g.T), 3))
turn(g::god, ône) = g.ône = ône
scale(g::god, ♯) = g.♯ = ♯

# ẑero::∃, ône=g.ẑero, g.ône
# ẑero.d
# ẑero.μ
# μρ(ẑero, d)
# ϵ, d=ẑero, d
# (i, d) = collect(enumerate(d̂))[5]
function Base.:(-)(ône::∃{N,T}, ẑero::∃{N,T}) where {N,T<:Real}
    # d̂ = sort(unique(ẑero.d ∪ ône.d)) # todo sort vs unique order
    μ = @MVector fill(○(T), length(ẑero.d))
    ρ = @MVector fill(○(T), length(ẑero.d))
    for (i, d) = enumerate(ẑero.d)
        ẑeroμ, _ = μρ(ẑero, d)
        ôneμ, _ = μρ(ône, d)
        ρ[i] = (ôneμ - ẑeroμ) / 2
        μ[i] = ẑeroμ + ρ[i]
    end
    # ∂ = fill(true, 2*length(ẑero.d))
    ∂ = ntuple(i -> iseven(i) ? ône.∂[i] : ẑero.∂[i], length(ẑero.d))
    ∃{N,T}(GOD, "", ẑero.d, SVector(μ), SVector(ρ), ∂, (_,_,_) -> ○(T))
end
Base.:(+)(ône::∃{N,T}, ẑero::∃{N,T}) where {N,T<:Real} = ∃{N,T}(ône, "", ẑero.d, ẑero.μ + ône.μ, ẑero.ρ, ẑero.∂, _ -> ○(T))
# ∇(t) = t*g.ône-(1-t)*g.ẑero
# ∇(0) = g.ẑero
# ∇(1) = g.ône
# t(ẑero), t̂
# speed = dt(ẑero)/dt̂, dx/dt(ẑero), dy/dt(ẑero)
# t = 1 - 1/(1+log(C)) = log(C)/(1+log(C))
# dt(ẑero) = speed[1]*dt̂
function step(g::god{N,T}, dt̂) where {N,T<:Real}
    dt = g.v[1] * dt̂
    dx = g.v[2] * dt
    dy = g.v[3] * dt
    μ = SA[g.ẑero.μ[1]+dt, g.ẑero.μ[2]+dx, g.ẑero.μ[3]+dy, ○(T), ○(T)]
    ρ = SA[zero(T), one(T)-μ[2], one(T)-μ[3], ○(T), ○(T)]
    g.ẑero = ∃{N,T}(GOD, "", g.ẑero.d, μ, ρ, g.ẑero.∂, (_,_,_) -> ○(T))
end
