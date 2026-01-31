# module TheoryOfGod

# const TOG = TheoryOfGod
# import .TheoryOfGod: ∀, ∃, ∃!, ○

# T = Rational{BigInt}
T=Float64
const Ω = ∀{T}([])
const Ξ = Dict{∃{T},T}()
const ORIGIN = time()

using Test

Ω.ϵ
# Ω.ϵ[1].ϵ

ϵ1 = ∃{T}("1", [0.1], [0.1], [0.1], [true,true], _->one(T), Ω, [])
n = [3]
@test ∃(n, ϵ1, Ξ) == [0.5,1.0,0.5]
∃!(ϵ1, Ω)
@test Θ(Ω) == 1
@test Ω.ϵ[1] == ϵ1

ϵ2 = ∃{T}("2", [0.1], [0.1], [0.1], [true,true], _->one(T), Ω, [])
∃!(ϵ2, Ω)
@test Θ(Ω) == 1

ϵ3 = ∃{T}("3", [0.1,0.2], [0.1,0.1], [0.1,0.1], [true,true,true,true], _->one(T), Ω, [])
∃!(ϵ3, Ω)
@test Θ(Ω) == 1

ϵ4 = ∃{T}("4", [0.1,0.2], [0.1,0.2], [0.1,0.1], [true,true,true,true], _->one(T)/4, Ω, [])
∃!(ϵ4, Ω)
@test Θ(Ω) == 1
n = [3,3]
@test ∃(n, ϵ4, Ξ) == [0.5 0.5 0.5; 0.5 0.25 0.5; 0.5 0.5 0.5]

ϵ5 = ∃{T}("5", [0.1,0.2], [0.1,0.3], [0.1,0.1], [true,true,true,true], _->one(T)/4, Ω, [])
∃!(ϵ5, Ω)
@test Θ(Ω) == 2
n = [3,3]
@test ∃(n, ϵ5, Ξ) == [0.5 0.5 0.5; 0.5 0.25 0.5; 0.5 0.5 0.5]

# dimensions are dt, dx, dy, ...
abstract type Peripheral{T<:Real} end
struct TravelPeripheral{T<:Real} <: Peripheral{T}
    # observer::∃{T}
    focus::∃{T}
    n::Vector{Int}
end
move!(p::Peripheral{T}, μ::Vector{T}) = Peripheral(
    ∃(p.focus.ι, p.focus.d, μ, p.focus.ρ, p.focus.∂, _ -> ○(T), Ω, []),
    # ∃{T}(p.observer.ι, p.observer.d, p.observer.μ + p.focus.μ - μ, p.observer.ρ, p.observer.∂, _ -> ○(T), Ω, [])
)
look!(p::Peripheral{T}, observer::∃{T}) = Peripheral(
    p.focus,
    # observer
)
scale!(p::Peripheral{T}, ρ::Vector{T}) = Peripheral(
    ∃(p.focus.ι, p.focus.d, p.focus.μ, ρ, p.focus.∂, _ -> ○(T), Ω, []),
    # p.observer
)
σ(x) = one(T) / (one(T) + exp(-x))
logit(x) = log(x / (one(T) - x))
# let δ = t - OUTER (time since creation)
# let ω = u / (1 - u) (odds ratio of unit time)
to_unit(τ, δ) = δ / (δ + τ)      # δ → u
from_unit(u, τ) = τ * u / (1 - u)  # u → δ
ω = δ / τ
δ = t - OUTER      # outer time elapsed since inner world's birth
τ = outer - OUTER  # outer time elapsed from birth to observation
OUTER  # outer time when inner world was created (birth)
outer  # outer time now (observation/tethering moment)
t      # any outer time we want to map
ω = δ / τ  # subjective age: "lifetimes lived"
u = ω / (ω + 1)  # compressed to unit interval
The odds ω answers: "What fraction of its life has the inner world lived?"
ω = 0.5: half its life (at observation) has passed
ω = 1: its full life (at observation) has passed — this is "now"
ω = 2: it has lived twice as long as when we tethered
# ω is the natural coordinate
# u is the bounded projection for finite representation
# or parameterized by "odds"
to_odds(δ, τ)   = δ / τ            # δ → ω  
from_odds(ω, τ) = τ * ω            # ω → δ
function observe(p::TravelPeripheral)
    # outer: -∞ ... OUTER=create ... outer=observe=0 ... ∞
    # ->
    # inner: OUTER=-∞ ... inner=0 ... ∞
    # ->
    # unit: OUTER=0 ... inner=1/2 ... 1

    world_age = time() - OUTER
    to_unit(τ, world_age)

    to_unit(t) = (t - OUTER) / (t - OUTER + world_age)

    
    # OUTER = 
    inner = p.focus.μ[1]
    dt = log(inner / (one(T) - inner))
    μ = [dt, p.focus.μ...]
    focus = ∃(ϵ.focus.ι, ϵ.focus.d, μ, ϵ.ρ, ϵ.focus.∂, ϵ.∃, e.∃̂, [])
    ∃(p.n, focus, Ξ)
end
function create(p::TravelPeripheral, what::String)
    ϵ = ask(p, what)
    dt = p.focus.μ[1]
    inner = one(T) / (one(T) + exp(-dt))
    μ = [inner, p.focus.μ...]
    ϵ̂ = ∃(ϵ.focus.ι, ϵ.focus.d, μ, ϵ.ρ, ϵ.focus.∂, ϵ.∃, e.∃̂, [])
    ∃!(ϵ̂, Ω)
end

function TravelPeripheral(name, dimensions, location, radius)
    # observer = ∃{T}(name, dimensions, location, zeros(dimensions), fill(:ONEONE, dimensions + 1), _ -> ○(T), Ω, [])
    # focus = ∃{T}(name * ".focus", dimensions, location, radius, fill(:ONEONE, dimensions + 1), _ -> ○(T), Ω, [observer])
    focus = ∃(name * ".focus", dimensions, location, radius, fill(:ONEONE, dimensions + 1), _ -> ○(T), Ω, [])
    n = [100, 200]
    TravelPeripheral{T}(observer, focus, n)
end

# end

"""
Time transformation for inner world observation.

Parameters:
- p_origin_bounded: origin's present in origin-bounded time (e.g., 0.991)
- i_create_origin: when inner was created in origin-bounded time (e.g., 0.99)
- inner_delta: observer's time slider (0,1), default 0.5 = natural pace

Returns:
- inner_bounded_time: the point in inner-bounded time (0,1) to observe
"""
function inner_bounded_time(p_origin_bounded, i_create_origin, inner_delta=0.5)
    # Inner's present in inner-bounded time
    p_inner_bounded = (p_origin_bounded - i_create_origin) / (1 - i_create_origin)
    
    # Edge case: inner just created
    p_inner_bounded ≤ 0 && return 0.0
    p_inner_bounded ≥ 1 && return 1.0
    
    # Edge cases: delta at extremes
    inner_delta ≤ 0 && return 0.0
    inner_delta ≥ 1 && return 1.0
    
    # Odds multiplication
    delta_odds = inner_delta / (1 - inner_delta)
    present_odds = p_inner_bounded / (1 - p_inner_bounded)
    result_odds = delta_odds * present_odds
    
    return result_odds / (1 + result_odds)
end
p_origin_bounded=0.991
i_create_origin=0.99
inner_delta=0.52
inner_bounded_time(p_origin_bounded, i_create_origin, inner_delta)
