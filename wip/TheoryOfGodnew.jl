"""
I = [ZERO < ○ < ONE] denotes a unit 1-dim space of information with origin ○ (no information) in its center including the corners ZERO and ONE.
Ω = I^I an ∞-dim metric and smooth vector space.
∃ is a topology on Ω such that ϵ ∈ ∃:
* ϵ ⊆ Ω
* ∃!ϵ̂: ϵ ∈ ϵ̂ ∈ ∃: ϵ|ϵ̂ ⊆ ϵ̂
* ∀ ϵ̂ ≠ ϵ ∈ ∃: ϵ̂ ∩ ϵ = ∅
* ϵ.∃ ∈ I is arbitrary, computable and smooth fuzzy existence towards ONE=true xor ZERO=false.

ϵ ∈ ∃ defines its existence inside an Ω using an origin vector (μ) and a radius vector (ρ), these vectors are finite and all other dimensional coordinates of ϵ follow from stepwise interpolation defined in the ∂ vector.
If we use a horizontal axis for dimension and a vertical axis for coordinate in the dimension, for any ϵ, the chart looks like a stepwise constant function with finite jumps.
"""
# module TheoryOfGod

using Serialization

○(::Type{T}) where {T<:Real} = one(T) / (one(T) + one(T))
abstract type Topology{T<:Real} end
struct ∀{T<:Real} <: Topology{T}
    ϵ::Vector{Topology{T}}
end
struct ∃{T<:Real} <: Topology{T}
    ι::String
    d::Vector{T}
    μ::Vector{T} # length(μ) == length(d)
    ρ::Vector{T} # length(ρ) == length(d)
    ∂::Vector{Symbol} # length(∂) == length(d) + 1
    ∃::Function # Topology{T} -> I
    ∃̂::Topology{T}
    ϵ::Vector{∃{T}}
end
index(n::Vector{<:Integer}) = (collect(i) for i ∈ Iterators.product((1:n̂ for n̂ ∈ n)...))
function ∃(n::Vector{<:Integer}, ϵ::∃{T}, Ξ::Dict{<:Topology{T},T}=Dict())::Array{T, length(n)} where {T<:Real}
    ∃̂ = fill(○(T), n...)
    _zero = ϵ.μ - ϵ.ρ
    for i = index(n)
        μ = fill(○(T), length(n))
        for î = eachindex(ϵ.d)
            μ[î] = isone(n[î]) ? ϵ.μ[î] : _zero[î] + 2 * ϵ.ρ[î] * T(i[î] - 1) / T(n[î] - 1)
        end
        x̂ = ∃{T}("", ϵ.d, μ, zeros(T, length(ϵ.d)), fill(:ONEONE, length(ϵ.d) + 1), _ -> one(T), ϵ, [])
        if haskey(Ξ, x̂)
            ∃̂[i] = Ξ[x̂]
            continue
        end
        Ξ[x̂] = ∃̂[i...] = unit(∃(x̂, nothing, ϵ), ϵ)
    end
    ∃̂
end
unit(x::∃, ϵ::∃) = ∃("", x.d, x.μ - ϵ.μ, zeros(T, length(x.d)), fill(:ONEONE, length(x.d) + 1), _ -> one(T), ϵ, [])
function ∂(x::∃, ϵ::∃)
    for (i, d) = enumerate(ϵ.d)
        iszero(ϵ.ρ[i]) && continue
        x̂ = μ(x, d)
        _zero, _one = ϵ.μ[i] - ϵ.ρ[i], ϵ.μ[i] + ϵ.ρ[i]
        (x̂ == _zero || x̂ == _one) && return true
    end
    false
end
function μ(ϵ::∃{T}, d::T)::T where {T<:Real}
    isempty(ϵ.d) && return ○(T)
    for (i, d̂) = enumerate(ϵ.d)
        d == d̂ && return ϵ.μ[i]
    end
    d̂ = sort(ϵ.d)
    _zero = iszero(d̂[1]) ? ϵ.d[1] : ○(T)
    _one = isone(d̂[end]) ? ϵ.d[end] : ○(T)
    if d < d̂[1]
        ∂ = ϵ.∂[1]
        ∂ == :ZEROONE && return ϵ.μ[1]
        ∂ == :ONEZERO && return _zero
    elseif d̂[end] < d
        ∂ = ϵ.∂[end]
        ∂ == :ZEROONE && return _one
        ∂ == :ONEZERO && return ϵ.μ[end]
    else
        i = findlast(d̃ -> d̃ < d, d̂)
        ∂ = ϵ.∂[i+1]
        ∂ == :ZEROONE && return ϵ.d[d̂[i+1]]
        ∂ == :ONEZERO && return ϵ.d[d̂[i]]
    end
    ○(T)
end
function ∃(x::∃{T}, ϵchecked::Union{∃{T},Nothing}, ϵ̂::∃{T}) where {T<:Real}
    ∂(x, ϵ̂) && return ○(T)
    isnothing(ϵchecked) && ( x ⩀ ϵ̂ || return ○(T) )
    x ∩ ϵ̂ && return ϵ̂.∃(x)
    for ϵ̃ = ϵ̂.ϵ
        ϵ̃ == ϵchecked && continue
        x ⩀ ϵ̃ || continue
        x ∩ ϵ̃ && return ϵ̃.∃(x)
    end
    isnothing(ϵ̂.∃̂) && return ○(T)
    ∃(x, ϵ̂, ϵ̂.∃̂)
end
closed_zero(mode::Symbol) = mode == :ONEZERO || mode == :ONEONE
closed_one(mode::Symbol) = mode == :ZEROONE || mode == :ONEONE
function ∅(zero₁, one₁, czero₁, cone₁, zero₂, one₂, czero₂, cone₂)
    (cone₁ && czero₂ ? one₁ < zero₂ : one₁ ≤ zero₂) && return true
    (cone₂ && czero₁ ? one₂ < zero₁ : one₂ ≤ zero₁) && return true
    false
end
function ⩀(ϵ::∃, ϵ̂::∃)
    for (i, d) ∈ enumerate(ϵ̂.d)
        d ∈ ϵ.d && continue
        x = μ(ϵ, d)
        _zero, _one = ϵ̂.μ[i] - ϵ̂.ρ[i], ϵ̂.μ[i] + ϵ̂.ρ[i]
        ∅(x, x, true, true, _zero, _one, closed_zero(ϵ̂.∂[i]), closed_one(ϵ̂.∂[i+1])) && return false
    end
    true
end
function Base.:∩(ϵ::∃, ϵ̂::∃)
    ϵ ⩀ ϵ̂ || return false
    ϵ̂ ⩀ ϵ || return false
    for (i, d) ∈ enumerate(ϵ.d)
        j = findfirst(==(d), ϵ̂.d)
        isnothing(j) && continue
        zero₁, one₁ = ϵ.μ[i] - ϵ.ρ[i], ϵ.μ[i] + ϵ.ρ[i]
        zero₂, one₂ = ϵ̂.μ[j] - ϵ̂.ρ[j], ϵ̂.μ[j] + ϵ̂.ρ[j]
        ∅(
            zero₁,
            one₁, 
            closed_zero(ϵ.∂[i]), 
            closed_one(ϵ.∂[i+1]), 
            zero₂, 
            one₂, 
            closed_zero(ϵ̂.∂[j]), 
            closed_one(ϵ̂.∂[j+1])) && return false
    end
    n, m = length(ϵ.d), length(ϵ̂.d)
    if 0 < n && 0 < m
        mode₁ = ϵ.∂[n+1]
        mode₂ = ϵ̂.∂[m+1]
        mode₁ ≠ mode₂ && return false
        if mode₁ == :ZEROONE
            tail₁ = ϵ.μ[n]
            tail₂ = ϵ̂.μ[m]
            tail₁ ≠ tail₂ && return false
        end
    end
    isempty(ϵ̂.ϵ) && return true
    any(ϵ̃ -> ϵ ∩ ϵ̃, ϵ̂.ϵ)
end
function ∃!(ϵ::∃, Ω::∀)
    intersects, ϵ̂ = ϵ ∩ Ω
    intersects && return nothing
    ϵ̃ = ∃{eltype(ϵ.d)}(ϵ.ι, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.∃, ϵ̂, ϵ.ϵ)
    push!(ϵ̂.ϵ, ϵ̃)
    ϵ̃
end
function Base.:∩(ϵ::∃, ϵ̂::Topology)
    ϵ′ = Ref{Topology}(ϵ̂)
    ϵdepth = Ref(0)
    intersects = any(ϵ̃ -> ∩(ϵ, ϵ̃, 1, ϵ′, ϵdepth), ϵ̂.ϵ)
    intersects, ϵ′[]
end
function Base.:∩(ϵ::∃, ϵ̂::Topology, ϵ̂depth::Int, ϵ′::Ref{Topology}, ϵdepth::Ref{<:Integer})
    ϵ ⩀ ϵ̂ || return false
    if ϵdepth[] < ϵ̂depth
        ϵ′[] = ϵ̂
        ϵdepth[] = ϵ̂depth
    end
    ϵ ∩ ϵ̂ && return true
    any(ϵ̃ -> ∩(ϵ, ϵ̃, ϵ̂depth + 1, ϵ′, ϵdepth), ϵ̂.ϵ)
end

# end
