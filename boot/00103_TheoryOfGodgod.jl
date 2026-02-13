mutable struct god
    ẑero::∃
    ône::∃
    v::Tuple # dt/dt̂ ; dẑero[2:end-2]/dt
    ♯::NTuple
    pin::UInt
end
const WHITE = (one(T), one(T), one(T), one(T))
# z=∃(God, SA[zero(T),one(T)], SA[zero(T),zero(T)], SA[zero(T),zero(T)], ((true,true),(true,true)), _ -> ○)
# o=∃(God, SA[zero(T),one(T)], SA[one(T),one(T)], SA[zero(T),zero(T)], ((true,true),(true,true)), _ -> ○)
# o-z
# z=∃(God, SA[zero(T),one(T)], SA[○,○], SA[○,○], ((true,true),(true,true)), _ -> ○)
# o=∃(God, SA[zero(T),one(T)], SA[○,○], SA[○,○], ((true,true),(true,true)), _ -> ○)
# o-z
function god(dimx, dimy, dimc, x, y, nx, ny, pin=zero(UInt))
    d = SA[zero(T), dimx, dimy, dimc, one(T)]
    N = length(d)
    ∂zero = ntuple(_ -> (true, false), N)
    μzero = SA[t(), x, y, ○, one(T)]
    ρzero = SA[zero(T), zero(T), zero(T), ○, zero(T)]
    ẑero = ∃(God, d, μzero, ρzero, ∂zero, _ -> ○)
    μone = SA[t(), one(T), one(T), ○, one(T)]
    ρone = SA[zero(T), zero(T), zero(T), ○, zero(T)]
    ∂one = ntuple(_ -> (false, true), N)
    ône = ∃(God, d, μone, ρone, ∂one, _ -> ○)
    ♯ = (1, nx, ny, 6, 1)
    v = ntuple(_ -> zero(T), N)
    god(ẑero, ône, v, ♯, pin)
end
function observe(g::god)
    ϵ = g.ône - g.ẑero
    d₁ = 1 .< g.♯
    d₂ = filter(i -> d₁[i], 1:length(d₁))
    d₃ = SVector{length(d₂)}(d₂)
    ϵ̃ = ∃(ϵ.ϵ̂, ϵ.d[d₃], ϵ.μ[d₃], ϵ.ρ[d₃], ϵ.∂[d₃], ϵ.Φ)
    ϕ = ∃̇(ϵ̃, g.♯[d₃])
    pixel = fill(WHITE, g.♯[2], g.♯[3])
    # i = collect(CartesianIndices(pixel))[1]
    for i = CartesianIndices(pixel)
        r = ϕ[1, i[1], i[2], 2, 1]
        g = ϕ[1, i[1], i[2], 3, 1]
        b = ϕ[1, i[1], i[2], 4, 1]
        a = ϕ[1, i[1], i[2], 5, 1]
        pixel[i[1], i[2]] = if r == g == b == a == ○
            WHITE
        else
            (r, g, b, a)
        end
    end
    pixel
end
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
function create(g::god, Φ)
    ϵ̂ = g.ône - g.ẑero
    ϵ̂ = ∃(ϵ̂, ϵ̂.d, ϵ̂.μ, ϵ̂.ρ, ϵ̂.∂, Φ̃(Φ))
    ∃!(ϵ̂)
end
accelerate!(g::god, v) = g.v = v
jerk!(g::god, j) = accelerate(g, g.v^j) # ?
stop!(g::god) = accelerate(g, ntuple(_ -> zero(g.T), 3))
turn!(g::god, ône) = g.ône = ône
# scale!(g::god, ♯) = g.♯ = ♯

# ∇(t) = t*g.ône-(1-t)*g.ẑero
# ∇(0) = g.ẑero
# ∇(1) = g.ône
# t(ẑero), t̂
# speed = dt(ẑero)/dt̂, dx/dt(ẑero), dy/dt(ẑero)
# t = 1 - 1/(1+log(C)) = log(C)/(1+log(C))
# dt(ẑero) = speed[1]*dt̂
# dt̂=0.01
function step!(g::god, dt̂)
    dt = g.v[1] * dt̂
    N = length(g.ẑero.μ)
    μ = SVector(ntuple(N) do i
        3 < i && return g.ẑero.μ[i]
        i == 1 && return min(g.ẑero.μ[1] + dt, one(T))
        min(g.ẑero.μ[i] + g.v[i] * dt, one(T))
    end)
    ρ = SVector(ntuple(N) do i
        (i == 2 || i == 3) && return min(g.ẑero.ρ[i], one(T) - μ[i])
        g.ẑero.ρ[i]
    end)
    g.ẑero = ∃(g.ẑero.ϵ̂, g.ẑero.d, μ, ρ, g.ẑero.∂, g.ẑero.Φ)
end
