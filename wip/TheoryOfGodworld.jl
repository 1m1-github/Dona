# module TheoryOfGod

# const TOG = TheoryOfGod
# import .TheoryOfGod: ∀, ∃, ∃!, ○

T = Rational{BigInt}
const Ω = ∀{T}([])
const Ξ = Dict{∃{T},T}()
const OUTER = time()

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
