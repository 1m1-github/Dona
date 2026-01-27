"""
I = [ZERO < ○ < ONE] denotes a unit 1-dim space of information with origin ○ (no information) in its center including the corners ZERO and ONE.
Ω = I^I an ∞-dim metric and smooth vector space.
∃ is a topology on Ω such that ϵ ∈ ∃:
* ϵ ⊊ Ω
* ∃!ϵ̂: ϵ ∈ ϵ̂ ∈ ∃
* ∀ ϵ̂ ≠ ϵ ∈ ∃: ϵ̂ ∩ ϵ = ∅
* ϵ.∃ ∈ I is arbitrary, computable and smooth fuzzy existence towards ONE=true xor ZERO=false.

# Ω is a mapping of R^R (∞-dim and ∞-large) to I^I (∞-dim, finite volume) unit circle.
∃ contains all the created existence.
Observe the world on a discreet n-dim grid g::♯ using ∃(g, ϵ=Ω) with
struct ♯{T<:Real}
    ϵ::∃{T} # origin(♯) == origin(ϵ) => dimension(ϵ) == 0
    d::Vector{T} # volume dimensions
    ρ::Vector{T} # volume radius
    n::Vector{Int} # grid points per volume dimension
end
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
function ∃(n::Vector{<:Integer}, ϵ::∃{T}, Ξ::Dict{∃{T},T})::Array{T,length(n)} where {T<:Real} # ZERO < i
    ∃̂ = fill(○(T), n...)
    _zero = ϵ.μ - ϵ.ρ
    # î = collect(i(n))[6]
    for î = i(n)
        @show î
        μ = fill(○(T), length(n))
        for ĩ = eachindex(ϵ.d)
            μ[ĩ] = isone(n[ĩ]) ? ϵ.μ[ĩ] : _zero[ĩ] + 2 * ϵ.ρ[ĩ] * T(î[ĩ] - 1) / T(n[ĩ] - 1)
        end
        x̂ = ∃{T}("", ϵ.d, μ, zeros(T, length(ϵ.d)), fill(:ONEONE, length(ϵ.d) + 1), _ -> one(T), ϵ, [])
        if haskey(Ξ, x̂)
            @show "haskey"
            ∃̂[î] = Ξ[x̂]
            continue
        end
        Ξ[x̂] = ∃̂[î...] = ∃(x̂, ϵ)
        @show Ξ[x̂]
    end
    ∃̂
end
# x = x̂
function ∃(x::∃{T}, ϵ::∃{T}) where {T<:Real}
    @show ∂(x, ϵ)
    ∂(x, ϵ) && return ○(T)
    @show x ∈ ϵ
    x ∈ ϵ && return ϵ.∃(x)
    for ϵ̂ = ϵ.ϵ
        @show "for", x ∈ ϵ̂
        x ∈ ϵ̂ && return ϵ̂.∃(x)
    end
    ○(T)
end
closed_zero(mode::Symbol) = mode == :ONEZERO || mode == :ONEONE
closed_one(mode::Symbol) = mode == :ZEROONE || mode == :ONEONE
function ∈(x::∃{T}, ϵ::∃{T}) where {T<:Real}
    isempty(ϵ.d) && return all(d -> X(x, d) == ○(T), x.d)

    for dx = x.d
        if dx ∉ ϵ.d
            xx = x.d[dx]
            xϵ = X(ϵ, dx)
            xx ≠ xϵ && return false
        end
    end

    # (iϵ, dϵ) = collect(enumerate(ϵ.d))[1]
    # for (iϵ, dϵ) = enumerate(ϵ.d)
    #     @show iϵ, dϵ
    #     xx = X(x, dϵ)
    #     _zero, _one = ϵ.μ[iϵ] - ϵ.ρ[iϵ], ϵ.μ[iϵ] + ϵ.ρ[iϵ]

    #     if lo == hi
    #         xx ≠ lo && return false
    #         continue
    #     end

    #     cl = closed_zero(ϵ.∂[iϵ])
    #     cr = closed_one(ϵ.∂[iϵ+1])

    #     if cl
    #         xx < lo && return false
    #     else
    #         xx ≤ lo && return false
    #     end
    #     if cr
    #         xx > hi && return false
    #     else
    #         xx ≥ hi && return false
    #     end
    # end
    # @show "true"
    # true

    # iϵ = ix = 1
    # while true
    #     dϵ = ϵ.d[iϵ]
    #     dx = x.d[ix]
    #     if dx == dϵ

    #     else
    #     end
    # end

    # isempty(ϵ.d) && return all(d -> X(x, d) == ○(T), x.d)
    # iϵ = sortperm(ϵ.d)
    # ix = sortperm(x.d)
    # îϵ = iϵ[2]
    # for îϵ = iϵ
    # (iϵ, dϵ) = collect(enumerate(ϵ.d))[1]
    for (iϵ, dϵ) = enumerate(ϵ.d)
    #     # dϵ = ϵ.d[îϵ]
        @show iϵ, dϵ
    #     # îx = ix[2]
    #     # for îx = ix
    #     # (_, dx) = collect(enumerate(x.d))[1]
    #     for (_, dx) = enumerate(x.d)
    #         # @show îx
    #         # dx = x.d[ix]
    #         if dx == dϵ
                xx = X(x, dϵ)
    #             @show xx, dx
                μ = ϵ.μ[iϵ]
                ρ = ϵ.ρ[iϵ]
                @show ρ, μ
                if iszero(ρ)
                    @show xx, μ
                    xx ≠ μ && return false
                    continue
                end
                _zero, _one = μ - ρ, μ + ρ
                @show _zero, _one
                if closed_zero(ϵ.∂[iϵ])
                    @show "closed_zero"
                    xx < _zero && return false
                else
                    @show "!closed_zero"
                    xx ≤ _zero && return false
                end
                if closed_one(ϵ.∂[iϵ+1])
                    @show "closed_one"
                    _one < xx && return false
                else
                    @show "!closed_one"
                    _zero ≤ xx && return false
                end
    #         # else
    #         #     xϵ = X(ϵ, dx)
    #         #     @show xϵ, xx
    #         #     xx ≠ xϵ && return false
    #         end
            
    #     end
    end

    # for (iϵ, dϵ) = enumerate(ϵ.d)
    #     # dϵ = ϵ.d[îϵ]
    #     @show iϵ, dϵ
    #     # îx = ix[2]
    #     # for îx = ix
    #     # (_, dx) = collect(enumerate(x.d))[1]
    #     for (_, dx) = enumerate(x.d)
    #         if dx ≠ dϵ

    #         end
    #     end
    # end

    @show "true"
    true
end
function ∂(x::∃{T}, ϵ::∃{T}) where {T<:Real}
    for (i, d) = enumerate(ϵ.d)
        @show "∂", i, d, ϵ.ρ[i]
        iszero(ϵ.ρ[i]) && continue
        x̂ = X(x, d)
        @show "∂", x̂
        _zero, _one = ϵ.μ[i] - ϵ.ρ[i], ϵ.μ[i] + ϵ.ρ[i]
        @show "∂", _zero, _one
        (x̂ == _zero || x̂ == _one) && return true
    end
    false
end
# function ⫉(x::∃{T}, ϵ::∃{T}) where {T<:Real}
#     for (i, d) = enumerate(ϵ.d)
#         x̂ = X(x, d)
#         _zero, _one = ϵ.μ[i] - ϵ.ρ[i], ϵ.μ[i] + ϵ.ρ[i]
#         (x̂ < _zero || x̂ > _one) && return false
#     end
#     true
# end
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
# function ∃(n::Vector{Integer}, ϵ::∃{T}) where {T<:Real}
#     i(n)
#     Dict(collect(idx) => ∃(X(g, collect(idx)), ϵ)[1] for idx ∈ i(g))
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

# function Base.hash(ϵ::∃)
#     io = IOBuffer()
#     serialize(io, (ϵ.ι, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.∃, ϵ.h))
#     sha3_512(take!(io))
# end

# function ∃(ϵ::∃{T}, d::T) where {T<:Real}
#     isempty(ϵ.d) && return ○(T)

#     ks = ϵ.d
#     n = length(ks)

#     if d < ks[1]
#         mode = ϵ.∂[1]
#         (mode == :ZEROZERO || mode == :ONEONE) && return ○(T)
#         mode == :ZEROONE && return ○(T)
#         mode == :ONEZERO && return ϵ.μ[1]
#     elseif d > ks[end]
#         mode = ϵ.∂[n+1]
#         (mode == :ZEROZERO || mode == :ONEONE) && return ○(T)
#         mode == :ZEROONE && return ϵ.μ[n]
#         mode == :ONEZERO && return ○(T)
#     else
#         i = findlast(k -> k ≤ d, ks)
#         if d == ks[i]
#             return ϵ.μ[i]
#         else
#             mode = ϵ.∂[i+1]
#             (mode == :ZEROZERO || mode == :ONEONE) && return ○(T)
#             mode == :ZEROONE && return ϵ.μ[i]
#             mode == :ONEZERO && return ϵ.μ[i+1]
#         end
#     end
# end

# # === Validation ===

# function □(μ::Vector{T}, ρ::Vector{T}) where {T<:Real}
#     length(μ) ≠ length(ρ) && return false
#     for (o, r) ∈ zip(μ, ρ)
#         (r < zero(T) || o - r < zero(T) || o + r > one(T)) && return false
#     end
#     true
# end

# □(x::X{T}) where {T<:Real} = all(v -> zero(T) ≤ v ≤ one(T), values(x.d))

# function □(d::Vector{T}, μ::Vector{T}, ρ::Vector{T}, ∂::Vector{Symbol}) where {T<:Real}
#     n = length(d)
#     length(μ) ≠ n && return false
#     length(ρ) ≠ n && return false
#     length(∂) ≠ n + 1 && return false
#     !□(μ, ρ) && return false
#     true
# end

# # === Bounds Check ===

# function ⫉(x::X{T}, ϵ::∃{T}) where {T<:Real}
#     for (i, d) ∈ enumerate(ϵ.d)
#         v = x[d]
#         lo, hi = ϵ.μ[i] - ϵ.ρ[i], ϵ.μ[i] + ϵ.ρ[i]
#         (v < lo || v > hi) && return false
#     end
#     true
# end

# # === Boundary Modes ===

# closed_zero(mode::Symbol) = mode == :ONEZERO || mode == :ONEONE
# closed_one(mode::Symbol) = mode == :ZEROONE || mode == :ONEONE

# # === Membership ===

# function ∈(x::X{T}, ϵ::∃{T}) where {T<:Real}
#     n = length(ϵ.d)
#     n == 0 && return true

#     ks = sort(collect(keys(x.d)))

#     for d ∈ ks
#         if d ∉ ϵ.d
#             v = x.d[d]
#             ϵv = ∃(ϵ, d)
#             v ≠ ϵv && return false
#         end
#     end

#     for (i, d) ∈ enumerate(ϵ.d)
#         v = x[d]
#         lo, hi = ϵ.μ[i] - ϵ.ρ[i], ϵ.μ[i] + ϵ.ρ[i]

#         if lo == hi
#             v ≠ lo && return false
#             continue
#         end

#         cl = closed_zero(ϵ.∂[i])
#         cr = closed_one(ϵ.∂[i+1])

#         if cl
#             v < lo && return false
#         else
#             v ≤ lo && return false
#         end
#         if cr
#             v > hi && return false
#         else
#             v ≥ hi && return false
#         end
#     end
#     true
# end

# # === At Boundary ===

# function ∂(x::X{T}, ϵ::∃{T}) where {T<:Real}
#     for (i, d) ∈ enumerate(ϵ.d)
#         ϵ.ρ[i] == zero(T) && continue
#         v = x[d]
#         lo, hi = ϵ.μ[i] - ϵ.ρ[i], ϵ.μ[i] + ϵ.ρ[i]
#         (v == lo || v == hi) && return true
#     end
#     false
# end

# # === Disjoint Intervals ===

# function ∅(lo₁, hi₁, cl₁, cr₁, lo₂, hi₂, cl₂, cr₂)
#     if cr₁ && cl₂
#         hi₁ < lo₂ && return true
#     else
#         hi₁ ≤ lo₂ && return true
#     end
#     if cr₂ && cl₁
#         hi₂ < lo₁ && return true
#     else
#         hi₂ ≤ lo₁ && return true
#     end
#     false
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

# # === Create ===

# function ∃!(Ω::∃{T}, ι::String, d::Vector{T}, μ::Vector{T}, ρ::Vector{T},
#             ∂::Vector{Symbol}, E::Function) where {T<:Real}
#     !□(d, μ, ρ, ∂) && return nothing
#     ϵ′ = ∃{T}(ι, d, μ, ρ, ∂, E, nothing, UInt8[], ∃{T}[])
#     p = ∃̂(ϵ′, Ω)
#     p ≢ Ω && ∩(p, ϵ′) && return nothing
#     any(c -> ∩(c, ϵ′), p.ϵ) && return nothing
#     ϵ = ∃{T}(ι, d, μ, ρ, ∂, E, p, hash(p), ∃{T}[])
#     push!(p.ϵ, ϵ)
#     ϵ
# end

# # === Hash Point ===

# function h(x::X{T}) where {T<:Real}
#     io = IOBuffer()
#     serialize(io, (x.d, x.∂))
#     sha3_512(take!(io))
# end

# === Observe ===

# function ∃(x::X{T}, ϵ::∃{T}) where {T<:Real}
#     !□(x) && return (○(T), ϵ, false)

#     for c ∈ ϵ.ϵ
#         if ⫉(x, c)
#             r = ∃(x, c)
#             r[2] ≢ ϵ && return r
#         end
#     end

#     x ∈ ϵ || return (○(T), ϵ, true)
#     ∂(x, ϵ) && return (○(T), ϵ, true)

#     k = h(x)
#     haskey(Ξ, k) && return (Ξ[k], ϵ, true)
#     Ξ[k] = ϵ.∃(x)
#     (Ξ[k], ϵ, true)
# end

# === Grid ===

# struct ♯{T<:Real}
#     d::Vector{T}
#     μ::Vector{T}
#     ρ::Vector{T}
#     n::Vector{Integer}
#     ∂::Symbol
# end
# ♯(d::Vector{T}, μ::Vector{T}, ρ::Vector{T}, n::Vector{Int}) where {T<:Real} = ♯{T}(d, μ, ρ, n, :ZEROZERO)

# for _i = i(g) @show _i end
# g = ♯([0.0,1.0], [0.1,0.2], [0.05,0.1], [3,2])
# struct ♯{T<:Real}
#     ϵ::∃{T}
#     n::Vector{Int}
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
# """
# x[d], interpolated if need be.
# """
# function ∃(x::X{T}, d::T) where {T<:Real}
#     haskey(x.d, d) && return x.d[d]
#     isempty(x.d) && return ○(T)
#     (x.∂ == :ZEROZERO || x.∂ == :ONEONE) && return ○(T)

#     ks = sort(collect(keys(x.d)))
#     v0 = haskey(x.d, zero(T)) ? x.d[zero(T)] : ○(T)
#     v1 = haskey(x.d, one(T)) ? x.d[one(T)] : ○(T)

#     if d < ks[1]
#         x.∂ == :ZEROONE && return v0
#         x.∂ == :ONEZERO && return x.d[ks[1]]
#     elseif d > ks[end]
#         x.∂ == :ZEROONE && return x.d[ks[end]]
#         x.∂ == :ONEZERO && return v1
#     else
#         i = findlast(k -> k ≤ d, ks)
#         x.∂ == :ZEROONE && return x.d[ks[i]]
#         x.∂ == :ONEZERO && return x.d[ks[i+1]]
#     end

#     ○(T)
# end
# Base.getindex(x::X{T}, d::T) where {T<:Real} = ∃(x, d)
# function X(g::♯{T}, idx::Vector{Int}) where {T<:Real}
#     p = Dict{T,T}()
#     for (i, d) ∈ enumerate(g.d)
#         lo, hi = g.μ[i] - g.ρ[i], g.μ[i] + g.ρ[i]
#         p[d] = g.n[i] == 1 ? g.μ[i] : lo + T(idx[i] - 1) / T(g.n[i] - 1) * (hi - lo)
#     end
#     X{T}(p, g.∂)
# end

# function array(g::♯{T}, r::Dict{Vector{Int},T}) where {T<:Real}
#     [r[[i,j]] for i ∈ 1:g.n[1], j ∈ 1:g.n[2]]
# end

# end
