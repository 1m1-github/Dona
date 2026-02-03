abstract type AbstractPeripheral{T<:Real} end

# const NAME_DIMENSION(T) = T(rand())

struct Peripheral{T<:Real} <: AbstractPeripheral{T}
    # name::String
    # ∃::Pretopology{T}
    focus::∃{T}
    resolution::Vector{Int}
    # projection::Function
    # inverseprojection::Function
    # function Peripheral{T}(name, ∃, focus, resolution, Ω::∀)
    #     p = new{T}(name, ∃, focus, resolution)
    #     h = T(hash(p)/typemax(UInt64))
    #     ϵ = ∃{T}(string(h), NAME_DIMENSION(T), [h], T[0.0],[true,true],_->one(T),Ω,[])
    #     ∃!(ϵ, Ω)
    # end
end

function Base.hash(p::Peripheral, h)
    # h = hash(p.∃, h)
    h = hash(p.focus, h)
    h = hash(p.resolution, h)
end

function observe(p::Peripheral)
    T = eltype(p.focus.μ)
    # children = p.∃ isa ∀ ? p.∃.ϵ : [p.∃]
    # d = [p.focus.d..., NAME_DIMENSION(T)]
    # μ = [p.focus.μ..., ○(T)]
    # ρ = [p.focus.ρ..., ○(T)]
    # ∂ = [p.focus.∂..., true, true]
    # focus = ∃{T}(p.focus.ι, d, μ, ρ, ∂, _ -> ○(T), p.∃, children)
    # focus = ∃{T}(p.focus.ι, p.focus.d, p.focus.μ, p.focus.ρ, p.focus.∂, _ -> ○(T), p.∃, children)
    focus = ∃{T}(p.focus.ι, p.focus.d, p.focus.μ, p.focus.ρ, p.focus.∂, _ -> ○(T), p.∃, Ω.ϵ)
    # k = length(inverseprojection())
    # ∃(p.resolution, focus) .|> p.projection
    ∃(p.resolution, focus)
    # a = ∃(p.resolution, focus)
    # map all a in NAME_DIMENSION to 
    # any(a[:, end]) && 
end
export observe

function create(p::Peripheral, ϵ)
    # ϵ̂ = ∃{T}(ϵ.ι, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.∃ ∘ p.inverseprojection, p.∃, children) # todo xor p.inverseprojection ∘ ϵ.∃
    ϵ̂ = ∃{T}(ϵ.ι, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.∃, p.focus, ϵ.ϵ)
    ∃!(ϵ̂)
end
export create

function move(p::Peripheral, μ)
    T = eltype(p.focus.μ)
    focus = ∃{T}(p.focus.ι, p.focus.d, μ, p.focus.ρ, p.focus.∂, p.focus.∃, p.focus.∃̂, p.focus.ϵ)
    # Peripheral{T}(p.∃, focus, p.resolution)
    Peripheral{T}(focus, p.resolution)
end
export move

function scale(p::Peripheral, ρ)
    T = eltype(p.focus.μ)
    focus = ∃{T}(p.focus.ι, p.focus.d, p.focus.μ, ρ, p.focus.∂, p.focus.∃, p.focus.∃̂, p.focus.ϵ)
    # Peripheral{T}(p.∃, focus, p.resolution)
    Peripheral{T}(focus, p.resolution)
end
export scale
