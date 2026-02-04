mutable struct god{T<:Real}
    ♯::Grid
    ẑero::∃{T}
    ône::∃{T}
    v::Tuple{T,T,T} # dt(ẑero)/dt̂, dx/dt(ẑero), dy/dt(ẑero)
end
function god{T}(dimx, dimy, dimc, x, y, nx, ny)
    d = [zero(T), dimx, dimy, dimc, one(T)]
    ∂ = fill(true, 2 * length(d))
    μzero = [t(Ω), x, y, ○(T), ○(T)]
    ρzero = [zero(T), one(T) - x, one(T) - y, ○(T), zero(T)]
    ẑero = ∃{T}("", d, μzero, ρzero, ∂, _ -> ○(T), Ω, ∃{T}[])
    # μone = fill(one(T), length(d))
    # ρone = fill(zero(T), length(d))
    # ône = ∃{T}("", d, μone, ρone, ∂, _ -> ○(T), Ω, ∃{T}[])
    ♯ = Grid([1, nx, ny, 6, 1])
    v = (zero(T), zero(T), zero(T))
    # god(♯, ẑero, ône(Ω), v)
    god(♯, ẑero, one(Ω), v)
end
# length(collect(keys(Ξ)))
# 1 2 3 4 5 6
# 0 0.2 0.4 0.6 0.8 1
# 0.25 0.5 0.75 1.0
function observe(g::god)
    ϵ = g.ône - g.ẑero
    pixel = fill((one(T), one(T), one(T), one(T)), g.♯.n[2], g.♯.n[3])
    # x = ∃(g.♯, Ω)
    x = ∃(g.♯, ϵ)
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
∃̂(∃̇) = x̂ -> begin
# @show x̂
    t, x, y, c, _ = x̂.μ
    r, g, b, a = ∃̇(t, x, y)
    r == g == b == a == ○(T) && return one(T)
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
function create(g::god, name, ∃̇)
    ϵ = g.ône - g.ẑero
    ϵ̂ = ∃{T}(name, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ∃̂(∃̇), Ω, ∃{T}[])
    ∃!(ϵ̂)
end
accelerate(g::god, v) = g.v = v
stop(g::god) = accelerate(g, ntuple(_ -> zero(g.T), 3))
turn(g::god, ône) = g.ône = ône
scale(g::god, ♯) = g.♯ = ♯

# ẑero::∃, ône=g.ẑero, g.ône
# ẑero.d
# ẑero.μ
# μρ(ẑero, d)
# ϵ, d=ẑero, d
# (i, d) = collect(enumerate(d̂))[5]
function Base.:(-)(ône::∃, ẑero::∃)
    # d̂ = sort(unique(ẑero.d ∪ ône.d)) # todo sort vs unique order
    μ = fill(○(T), length(ẑero.d))
    ρ = fill(○(T), length(ẑero.d))
    for (i, d) = enumerate(ẑero.d)
        ẑeroμ, _ = μρ(ẑero, d)
        ôneμ, _ = μρ(ône, d)
        ρ[i] = (ôneμ - ẑeroμ) / 2
        μ[i] = ẑeroμ + ρ[i]
    end
    ∂ = fill(true, 2*length(ẑero.d))
    ∃{T}("", ẑero.d, μ, ρ, ∂, _ -> ○(T), Ω, ∃{T}[])
end

# ∇(t) = t*g.ône-(1-t)*g.ẑero
# ∇(0) = g.ẑero
# ∇(1) = g.ône
# t(ẑero), t̂
# speed = dt(ẑero)/dt̂, dx/dt(ẑero), dy/dt(ẑero)
# t = 1 - 1/(1+log(C)) = log(C)/(1+log(C))
# dt(ẑero) = speed[1]*dt̂
function step(g::god, dt̂)
    dt = g.v[1] * dt̂
    dx = g.v[2] * dt
    dy = g.v[3] * dt
    μ = [g.ẑero.μ[1] + dt, g.ẑero.μ[2] + dx, g.ẑero.μ[3] + dy, ○(T), ○(T)]
    ρ = [zero(T), one(T) - μ[2], one(T) - μ[3], ○(T), ○(T)]
    g.ẑero = ∃{T}("", g.ẑero.d, μ, ρ, g.ẑero.∂, _ -> ○(T), Ω, ∃{T}[])
end
