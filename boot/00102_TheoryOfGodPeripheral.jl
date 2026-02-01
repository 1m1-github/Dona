abstract type AbstractPeripheral{T<:Real} end

struct Peripheral{T<:Real} <: AbstractPeripheral{T}
    target::Pretopology{T}
    focus::∃{T}
    resolution::Vector{Int}
end

function observe(p::Peripheral)
    children = p.target isa ∀ ? p.target.ϵ : [p.target]
    T = eltype(p.focus.μ)
    focus = ∃{T}(p.focus.ι, p.focus.d, p.focus.μ, p.focus.ρ, p.focus.∂, _ -> ○(T), p.target, children)
    ∃(p.resolution, focus)
end

function teleport(p::Peripheral, μ)
    T = eltype(p.focus.μ)
    focus = ∃{T}(p.focus.ι, p.focus.d, μ, p.focus.ρ, p.focus.∂, p.focus.∃, p.focus.∃̂, p.focus.ϵ)
    Peripheral{T}(p.target, focus, p.resolution)
end

function scale(p::Peripheral, ρ)
    T = eltype(p.focus.μ)
    focus = ∃{T}(p.focus.ι, p.focus.d, p.focus.μ, ρ, p.focus.∂, p.focus.∃, p.focus.∃̂, p.focus.ϵ)
    Peripheral{T}(p.target, focus, p.resolution)
end

function move(p::Peripheral, Δμ)
    T = eltype(p.focus.μ)
    μ = clamp.(p.focus.μ .+ Δμ, zero(T), one(T))
    teleport(p, μ)
end
