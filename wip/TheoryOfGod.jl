# module TheoryOfGod

# const TOG = TheoryOfGod
# import .TheoryOfGod: ∀, ∃, ∃!, ○

T = Rational{BigInt}
T=Float64
const Ω = ∀{T}([])
const Ξ = Dict{∃{T},T}()
const BEGIN = time()


using Test

Ω.ϵ
# Ω.ϵ[1].ϵ

ϵ1∃(ϵ) = begin
    @show ϵ.μ[1]
    return ϵ.μ[1]
end
ϵ1 = ∃{T}("1", [0.1], [0.1], [0.1], [true,true], ϵ1∃, Ω, [])
∃!(ϵ1, Ω)
n = [5]
∃(n, ϵ1, Ξ)
ks=collect(keys(Ξ))

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
    resolution::Vector{Int}
    dimensions::Vector{Int}
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

inner_creation_outer_time_bounded = T(0.999)
delta_since_inner_creation_outer_time_unbounded = T(1) # s
rest_after_inner_creation_outer_time_bounded = T(1) - inner_creation_outer_time_bounded
now_outer_time_bounded =  T(1) - rest_after_inner_creation_outer_time_bounded / (T(1) + rest_after_inner_creation_outer_time_bounded * delta_since_inner_creation_outer_time_unbounded)
now_inner_time_unbounded = (now_outer_time_bounded - inner_creation_outer_time_bounded) / (T(1) - now_outer_time_bounded)
now_inner_time_bounded = now_inner_time_unbounded / (1+now_inner_time_unbounded)
dt = T(0.5)
speedup = dt / (1-dt)
sync = rest_after_inner_creation_outer_time_bounded*(1-now_inner_time_bounded)^2
delta_inner_time_bounded = speedup*sync


function observe(p::TravelPeripheral)
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
