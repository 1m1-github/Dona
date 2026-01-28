# module TheoryOfGod

# const TOG = TheoryOfGod
# import .TheoryOfGod: ∀, ∃, ∃!, ○

T = Rational{BigInt}
const Ω = ∀{T}([])
const Ξ = Dict{∃{T},T}()
const tether_creation = time()

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
function observe(p::TravelPeripheral)
    tether = p.focus.μ[1]
    dt = log(tether / (one(T) - tether))
    μ = [dt, p.focus.μ...]
    focus = ∃(ϵ.focus.ι, ϵ.focus.d, μ, ϵ.ρ, ϵ.focus.∂, ϵ.∃, e.∃̂, [])
    ∃(p.n, focus, Ξ)
end
function create(p::TravelPeripheral, what::String)
    ϵ = ask(p, what)
    dt = p.focus.μ[1]
    tether = one(T) / (one(T) + exp(-dt))
    μ = [tether, p.focus.μ...]
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
