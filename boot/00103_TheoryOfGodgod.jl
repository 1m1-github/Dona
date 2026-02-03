mutable struct god{T<:Real} <: AbstractPeripheral{T}
    ♯::Grid
    ẑero::∃{T}
    ône::∃{T}
    v::Tuple{T,T,T} # dt_inner(ẑero)/dt_origin, dx/dt_inner(ẑero), dy/dt_inner(ẑero)
end
function god{T}(dimx, dimy, dimc, x, y, nx, ny)
    d = [zero(T), dimx, dimy, dimc]
    μ = [t(Ω), x, y, ○(T)]
    ρ = [zero(T), one(T) - x, one(T) - y, ○(T)]
    ∂ = fill(true, 2 * length(d))
    ẑero = ∃{T}("", d, μ, ρ, ∂, _ -> ○(T), Ω, [])
    ône = ∃{T}("", [zero(T), one(T)], [one(T), one(T)], [zero(T), zero(T)], [true, true, true, true], _ -> ○(T), Ω, [])
    ♯ = Grid([1, nx, ny, 4]) #rgba
    # v = (one(T), zero(T), zero(T))
    v = (zero(T), zero(T), zero(T)) # DEBUG
    god(♯, ẑero, ône, v)
end
function observe(g::god)
    ϵ = g.ône - g.ẑero
    pixels = fill((1.0, 1.0, 1.0, 1.0), g.♯[2], g.♯[3])
    x = ∃(g.♯, ϵ)
    for i = eachindex(pixels)
        r = x[1, i[1], i[2], 1]
        g = x[1, i[1], i[2], 2]
        b = x[1, i[1], i[2], 3]
        a = x[1, i[1], i[2], 4]
        pixels[i[1], i[2]] = (r, g, b, a)
    end
    pixels
end
∃̂(∃̇) = x̂ ->
    t, x, y, c = x̂
    r, g, b, a = ∃̇(t, x, y)
    c∂ = one(T) / 4
    return if c < c∂
        r
    elseif c < 2 * c∂
        g
    elseif c < 3 * c∂
        b
    else
        a
    end
function create(g::god, name, ∃̇)
    ϵ = g.ône - g.ẑero
    ϵ̂ = ∃{T}(name, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ∃̂(∃̇), Ω, [])
    ∃!(ϵ̂)
end
accelerate(g::god, v) = g.v = v
stop(g::god) = accelerate(g, ntuple(_ -> zero(g.T), 3))
turn(g::god, ône) = g.ône = ône
scale(g::god, ♯) = g.♯ = ♯

function Base.(-)(ẑero::∃, ône::∃)
    d̂ = sort(ϵ.d ∪ ϵ̂.d)
    μ = fill(○(T), length(d̂))
    ρ = fill(○(T), length(d̂))
    for (i, d) = enumerate(d̂)
        ẑeroμ, _ = μρ(ẑero, d)
        ôneμ, _ = μρ(ône, d)
        μ[i] = ôneμ - ẑeroμ
        ρ[i] = μ[i] / 2
    end
    ∂ = fill(true, length(d̂))
    ∃("", d, μ, ρ, ∂, _ -> ○(T), Ω, [])
end

# ∇(t_inner) = t_inner*g.ône-(1-t_inner)*g.ẑero
# ∇(0) = g.ẑero
# ∇(1) = g.ône
# t_inner(ẑero), t_origin
# speed = dt_inner(ẑero)/dt_origin, dx/dt_inner(ẑero), dy/dt_inner(ẑero)
# t_inner = 1 - 1/(1+log(C)) = log(C)/(1+log(C))
# dt_inner(ẑero) = speed[1]*dt_origin
function step(g::god, dt̂)
    dt = g.v[1] * dt̂
    dx = g.v[2] * dt
    dy = g.v[3] * dt
    μ = [g.ẑero.μ[1] + dt, g.ẑero.μ[2] + dx, g.ẑero.μ[3] + dy, ○(T)]
    ρ = [zero(T), one(T) - μ[2], one(T) - μ[3], ○(T)]
    g.ẑero = ∃{T}("", g.ẑero.d, μ, ρ, g.ẑero.∂, _ -> ○(T), Ω, [])
end
