"""
I = [ZERO < ○ < ONE] denotes a unit 1-dim space of information with origin ○ (no information) in its center including the corners ZERO and ONE.
Ω = I^I an ∞-dim metric and smooth vector space.
∃ is a topology on Ω such that ϵ ∈ ∃:
* ϵ ⊊ Ω
* ∃!ϵ̂: ϵ ∈ ϵ̂ ∈ ∃: ϵ|ϵ̂ ⊆ ϵ̂
* ∀ ϵ̂ ≠ ϵ ∈ ∃: ϵ̂ ∩ ϵ = ∅
* ϵ.∃ ∈ I is arbitrary, computable and smooth fuzzy existence towards ONE=true xor ZERO=false.

# Ω is a mapping of R^R (∞-dim and ∞-large) to I^I (∞-dim, finite volume) unit circle.
∃ contains all the created existence.
Observe the world on a discreet n-dim grid  with ∃(n::Vector{<:Integer}, ϵ::∃{T}, Ξ::Dict{∃{T},T})
"""
# module TheoryOfGod

# using SHA, Serialization
using Serialization

○(::Type{T}) where {T<:Real} = one(T) / (one(T) + one(T))
struct ∃{T<:Real}
    ι::String
    d::Vector{T}
    μ::Vector{T}
    ρ::Vector{T}
    ∂::Vector{Symbol}
    ∃::Function # ∃ -> I
    ∃̂::Union{∃{T},Nothing}
    ϵ::Vector{∃{T}}
end
i(n::Vector{<:Integer}) = (collect(i) for i ∈ Iterators.product((1:n̂ for n̂ ∈ n)...))
function ∃(n::Vector{<:Integer}, ϵ::∃{T}, Ξ::Dict{∃{T},T}=Dict())::Array{T,length(n)} where {T<:Real} # ZERO < i
    ∃̂ = fill(○(T), n...)
    _zero = ϵ.μ - ϵ.ρ
    for î = i(n)
        μ = fill(○(T), length(n))
        for ĩ = eachindex(ϵ.d)
            μ[ĩ] = isone(n[ĩ]) ? ϵ.μ[ĩ] : _zero[ĩ] + 2 * ϵ.ρ[ĩ] * T(î[ĩ] - 1) / T(n[ĩ] - 1)
        end
        x̂ = ∃{T}("", ϵ.d, μ, zeros(T, length(ϵ.d)), fill(:ONEONE, length(ϵ.d) + 1), _ -> one(T), ϵ, [])
        if haskey(Ξ, x̂)
            ∃̂[î] = Ξ[x̂]
            continue
        end
        Ξ[x̂] = ∃̂[î...] = ∃(x̂, ϵ)
    end
    ∃̂
end
function ∃(x::∃{T}, ϵ::∃{T}) where {T<:Real}
    ∂(x, ϵ) && return ○(T)
    x ∩ ϵ && return ϵ.∃(x)
    for ϵ̂ = ϵ.ϵ
        x ∩ ϵ̂ && return ϵ̂.∃(x)
    end
    ○(T)
end
closed_zero(mode::Symbol) = mode == :ONEZERO || mode == :ONEONE
closed_one(mode::Symbol) = mode == :ZEROONE || mode == :ONEONE
function ∅(zero₁, one₁, czero₁, cone₁, zero₂, one₂, czero₂, cone₂)
    if cone₁ && czero₂
        one₁ < zero₂ && return true
    else
        one₁ ≤ zero₂ && return true
    end
    if cone₂ && czero₁
        one₂ < zero₁ && return true
    else
        one₂ ≤ zero₁ && return true
    end
    false
end
function ⩀(ϵ::∃{T}, ϵ̂::∃{T}) where {T<:Real}
    for (i, d) ∈ enumerate(ϵ.d)
        d ∈ ϵ̂.d && continue
        x = X(ϵ̂, d)
        _zero, _one = ϵ.μ[i] - ϵ.ρ[i], ϵ.μ[i] + ϵ.ρ[i]
        ∅(x, x, true, true, _zero, _one, closed_zero(ϵ.∂[i]), closed_one(ϵ.∂[i+1])) && return false
    end
    true
end
function ∩(ϵ::∃{T}, ϵ̂::∃{T}) where {T<:Real}
    !(ϵ ⩀ ϵ̂) && return false
    !(ϵ̂ ⩀ ϵ) && return false
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

    true
end
# function ∈(x::∃{T}, ϵ::∃{T}) where {T<:Real}
#     isempty(ϵ.d) && return all(d -> X(x, d) == ○(T), x.d)
#     for dx = x.d
#         if dx ∉ ϵ.d
#             xx = x.d[dx]
#             xϵ = X(ϵ, dx)
#             xx ≠ xϵ && return false
#         end
#     end
#     for (iϵ, dϵ) = enumerate(ϵ.d)
#         xx = X(x, dϵ)
#         μ = ϵ.μ[iϵ]
#         ρ = ϵ.ρ[iϵ]
#         if iszero(ρ)
#             xx ≠ μ && return false
#             continue
#         end
#         _zero, _one = μ - ρ, μ + ρ
#         if closed_zero(ϵ.∂[iϵ])
#             xx < _zero && return false
#         else
#             xx ≤ _zero && return false
#         end
#         if closed_one(ϵ.∂[iϵ+1])
#             _one < xx && return false
#         else
#             _zero ≤ xx && return false
#         end
#     end
#     true
# end
function ∂(x::∃{T}, ϵ::∃{T}) where {T<:Real}
    for (i, d) = enumerate(ϵ.d)
        iszero(ϵ.ρ[i]) && continue
        x̂ = X(x, d)
        _zero, _one = ϵ.μ[i] - ϵ.ρ[i], ϵ.μ[i] + ϵ.ρ[i]
        (x̂ == _zero || x̂ == _one) && return true
    end
    false
end
function X(ϵ::∃{T}, d::T)::T where {T<:Real}
    isempty(ϵ.d) && return ○(T)
    for (i, d̂) = enumerate(ϵ.d)
        d == d̂ && return ϵ.μ[i]
    end
    (ϵ.∂ == :ZEROZERO || ϵ.∂ == :ONEONE) && return ○(T)
    d̂ = sort(ϵ.d)
    _zero = iszero(d̂[1]) ? ϵ.d[1] : ○(T)
    _one = isone(d̂[end]) ? ϵ.d[end] : ○(T)
    if d < d̂[1]
        ∂ = ϵ.∂[1]
        ∂ == :ZEROONE && return _zero
        ∂ == :ONEZERO && return ○(T)
    elseif d̂[end] < d
        ∂ = ϵ.∂[end]
        ∂ == :ZEROONE && return ○(T)
        ∂ == :ONEZERO && return _one
    else
        i = findlast(d̃ -> d̃ < d, d̂)
        ∂ = ϵ.∂[i+1]
        ∂ == :ZEROONE && return ϵ.d[d̂[i+1]]
        ∂ == :ONEZERO && return ϵ.d[d̂[i]]
    end
    ○(T)
end
function ∃!(ϵ::∃{T}, ι::String, d::Vector{T}, μ::Vector{T}, ρ::Vector{T},
            ∂::Vector{Symbol}, E::Function) where {T<:Real}
    ϵ̂ = ∃{T}(ι, d, μ, ρ, ∂, E, ϵ, ∃{T}[])
    # todo find better parent?
    ϵ̂ ∩ ϵ && return nothing
    any(ϵ̃ -> ϵ̂ ∩ ϵ̃, ϵ.ϵ) && return nothing
    push!(ϵ.ϵ, ϵ̂)
    ϵ̂
end
# function ⫉(x::∃{T}, ϵ::∃{T}) where {T<:Real}
#     for (i, d) = enumerate(ϵ.d)
#         x̂ = X(x, d)
#         _zero, _one = ϵ.μ[i] - ϵ.ρ[i], ϵ.μ[i] + ϵ.ρ[i]
#         (x̂ < _zero || x̂ > _one) && return false
#     end
#     true
# end
# function X(d::Dict{T,T}, ∂::Vector{Symbol}) where {T<:Real}
#     dims = sort(collect(keys(d)))
#     vals = [d[k] for k in dims]
#     ∃{T}("", dims, vals, zeros(T, length(d)), ∂, identity, nothing, UInt8[], ∃{T}[])
# end
# function X(d::Dict{T,T}, ∂::Symbol=:ZEROZERO) where {T<:Real}
#     n = length(d)
#     X(d, fill(∂, n + 1))
# end

# # === Intersection ===

# function ∩(ϵ::∃{T}, ϵ′::∃{T}) where {T<:Real}
#     for (i, d) ∈ enumerate(ϵ.d)
#         if d ∉ ϵ′.d
#             v = ∃(ϵ′, d)
#             lo, hi = ϵ.μ[i] - ϵ.ρ[i], ϵ.μ[i] + ϵ.ρ[i]
#             cl = closed_zero(ϵ.∂[i])
#             cr = closed_one(ϵ.∂[i+1])

#             if cl
#                 (v < lo) && return false
#             else
#                 (v ≤ lo) && return false
#             end
#             if cr
#                 (v > hi) && return false
#             else
#                 (v ≥ hi) && return false
#             end
#         end
#     end

#     for (j, d) ∈ enumerate(ϵ′.d)
#         if d ∉ ϵ.d
#             v = ∃(ϵ, d)
#             lo, hi = ϵ′.μ[j] - ϵ′.ρ[j], ϵ′.μ[j] + ϵ′.ρ[j]
#             cl = closed_zero(ϵ′.∂[j])
#             cr = closed_one(ϵ′.∂[j+1])

#             if cl
#                 (v < lo) && return false
#             else
#                 (v ≤ lo) && return false
#             end
#             if cr
#                 (v > hi) && return false
#             else
#                 (v ≥ hi) && return false
#             end
#         end
#     end

#     for (i, d) ∈ enumerate(ϵ.d)
#         j = findfirst(==(d), ϵ′.d)
#         j === nothing && continue

#         lo₁, hi₁ = ϵ.μ[i] - ϵ.ρ[i], ϵ.μ[i] + ϵ.ρ[i]
#         lo₂, hi₂ = ϵ′.μ[j] - ϵ′.ρ[j], ϵ′.μ[j] + ϵ′.ρ[j]

#         cl₁ = closed_zero(ϵ.∂[i])
#         cr₁ = closed_one(ϵ.∂[i+1])
#         cl₂ = closed_zero(ϵ′.∂[j])
#         cr₂ = closed_one(ϵ′.∂[j+1])

#         ∅(lo₁, hi₁, cl₁, cr₁, lo₂, hi₂, cl₂, cr₂) && return false
#     end

#     n, m = length(ϵ.d), length(ϵ′.d)
#     if n > 0 && m > 0
#         mode₁ = ϵ.∂[n+1]
#         mode₂ = ϵ′.∂[m+1]
#         mode₁ ≠ mode₂ && return false
#         if mode₁ == :ZEROONE
#             tail₁ = ϵ.μ[n]
#             tail₂ = ϵ′.μ[m]
#             tail₁ ≠ tail₂ && return false
#         end
#     end

#     true
# end

# # === Containment ===

# function ⊂(ϵ′::∃{T}, ϵ::∃{T}) where {T<:Real}
#     for (i, d) ∈ enumerate(ϵ.d)
#         lo, hi = ϵ.μ[i] - ϵ.ρ[i], ϵ.μ[i] + ϵ.ρ[i]
#         j = findfirst(==(d), ϵ′.d)
#         if j === nothing
#             v = ∃(ϵ′, d)
#             (v < lo || v > hi) && return false
#         else
#             lo′, hi′ = ϵ′.μ[j] - ϵ′.ρ[j], ϵ′.μ[j] + ϵ′.ρ[j]
#             (lo′ < lo || hi′ > hi) && return false
#         end
#     end
#     true
# end

# # === Find Parent ===

# function ∃̂(ϵ′::∃{T}, Ω::∃{T}) where {T<:Real}
#     for c ∈ Ω.ϵ
#         ⊂(ϵ′, c) && return ∃̂(ϵ′, c)
#     end
#     Ω
# end

# end
