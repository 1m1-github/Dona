"""
I = [ZERO < ○ < ONE] denotes a unit 1-dim space of information with origin ○ (no information) in its center including the corners ZERO and ONE.
Ω = I^I an ∞-dim metric and smooth vector space.
∃ is a pretopology on Ω such that ϵ ∈ ∃:
* ϵ ⊆ Ω
* ∃!ϵ̂: ϵ ∈ ϵ̂ ∈ ∃: ϵ|ϵ̂ ⊆ ϵ̂ <=> ϵ ⫉ ϵ̂
* ∀ ϵ̂ ≠ ϵ ∈ ∃: ϵ̂ ∩ ϵ = ∅
* ϵ.∃ ∈ I is arbitrary, computable and smooth fuzzy existence towards ONE=true xor ZERO=false.

ϵ ∈ ∃ defines its existence inside an Ω using an origin vector (μ) and a radius vector (ρ), these vectors are finite and all other dimensional coordinates of ϵ follow from stepwise interpolation defined in the ∂ vector.
If we use a horizontal axis for dimension and a vertical axis for coordinate in the dimension, for any ϵ, the chart looks like a stepwise constant function with finite jumps.
Each child ϵ is a subset of its parent in the active dimensions (0 ≤ ρ) declared by the parent (as opposed to undeclared dimensions where 0==ρ).
"""
# module TheoryOfGod

# @enum Border ZEROZER0 ZEROONE ONEZERO ONEONE
# closed_zero(∂::Border) = ∂ == ONEZERO || ∂ == ONEONE
# closed_one(∂::Border) = ∂ == ZEROONE || ∂ == ONEONE
# closed(d::Vector) = fill(ONEONE, d + 1)

○(::Type{T}) where {T<:Real} = one(T) / (one(T) + one(T))
abstract type Pretopology{T<:Real} end
struct ∀{T<:Real} <: Pretopology{T}
    ϵ::Vector{Pretopology{T}}
end
struct ∃{T<:Real} <: Pretopology{T}
    ι::String
    d::Vector{T} # sorted, distinct
    μ::Vector{T} # length(μ) == length(d)
    ρ::Vector{T} # length(ρ) == length(d)
    ∂::Vector{Bool} # length(∂) == 2length(d), ∂[i] <=> [μ-ρ,..., ∂[2i] <=> ...,μ+ρ] both in d=i
    ∂d::Vector{Bool} # length(∂d) == 2(length(d) + 1), ∂d[i] <=> [d[i-1],d[i]..., ∂d[2i] <=> ...d[i-1],d[i]]
    ∃::Function # X(ρ=0) ∈ ∃ -> I
    ∃̂::Pretopology{T} # ∃ ⫉ ∃̂ ⩓ ∃ ∩ ∃̂ = ∅
    ϵ::Vector{∃{T}} # ϵ ⫉ ∃ ⩓ ϵ ∩ ∃ = ∅
end # todo check validity for outside creators
# ∃(ϵ::∃) = ∃{eltype(ϵ.d)}(ϵ.ι, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.∃, ϵ.∃̂, ϵ.ϵ)
∃(ϵ, ϵ̂) = ∃(ϵ.ι, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.∂d, ϵ.∃, ϵ̂, ϵ.ϵ)
# ∃(ϵ, ϵ̂) = ∃(ϵ.ι, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.∃, ϵ̂, ϵ.ϵ)
# X(ϵ::∃, d, μ) = ∃("", d, μ, zeros(d), close(d), _ -> one(eltype(d)), ϵ, [])
# X(ϵ, μ) = ∃("", ϵ.d, μ, zeros(ϵ.d), fill(true, length(ϵ.∂)), _ -> one(eltype(ϵ.μ)), ϵ, []) # todo check μ ∈ [ϵ.μ-ϵ.ρ,ϵ.μ+ϵ.ρ] ?
X(ϵ, μ) = ∃("", ϵ.d, μ, zeros(ϵ.d), fill(true, length(ϵ.∂)), fill(true, length(ϵ.∂d)), _ -> one(eltype(ϵ.μ)), ϵ, []) # todo check μ ∈ [ϵ.μ-ϵ.ρ,ϵ.μ+ϵ.ρ] ?
# X(ϵ::∃, μ) = X(ϵ, ϵ.d, μ)
# unit(x::∃, ϵ::∃) = ∃("", x.d, x.μ - ϵ.μ, zeros(x.d), close(ϵ.d), _ -> one(eltype(ϵ.d)), ϵ, [])
unit(x, ϵ) = X(ϵ, x.μ - ϵ.μ)
index(n) = (collect(i) for i ∈ Iterators.product((1:n̂ for n̂ ∈ n)...))
function ∃(n, ϵ, Ξ=Dict())
    ○̂ = ○(eltype(ϵ.μ))
    ∃̂ = fill(○̂, n...)
    ẑero = ϵ.μ - ϵ.ρ
    for i = index(n)
        μ = fill(○̂, length(n))
        for î = eachindex(ϵ.d)
            μ[î] = isone(n[î]) ? ϵ.μ[î] : ẑero[î] + 2 * ϵ.ρ[î] * T(i[î] - 1) / T(n[î] - 1)
        end
        x = X(ϵ, μ) # x ∈ cl(ϵ)
        if haskey(Ξ, x) # todo test
            ∃̂[i] = Ξ[x]
            continue
        end
        Ξ[x] = ∃̂[i...] = ∃(x, nothing, ϵ)
    end
    ∃̂
end
# ∂mode[1] ∈ [00: 1/2, 01: ]
# 0 ... ∂mode[1] ... μ(ϵ, ϵ.d[1]) ... ∂mode[2] ... μ(ϵ, ϵ.d[2]) ... ∂mode[end-1] ... μ(ϵ, ϵ.d[end]) ... ∂mode[end] ... 1
μ(a, b, x) = a + (b-a)*x
function μρ(ϵ, d)
    T = eltype(d)
    ○̂ = ○(T)
    isempty(ϵ.d) && return ○̂, 0, true, true
    i = searchsortedfirst(ϵ.d, d)
    ϵ.d[i] == d && return ϵ.μ[i], ϵ.ρ[i], ϵ.∂[i], ϵ.∂[2i]
    ϵd1 = ϵ.d[1] ; ϵdend = ϵ.d[end] ; ϵμ1 = ϵ.μ[1]
    zerod = ϵd1 ; oned = ϵd1 ; zeroμ = ○̂ ; oneμ = ○̂ ; zeroρ = zero(T) ; oneρ = zero(T)
    if d < ϵd1
        zerod = zero(T) ; oneμ = ϵμ1 ; oneρ = ϵ.ρ[1]
    elseif ϵdend < d
        zerod = ϵdend ; oned = one(T) ; zeroμ = ϵ.μ[end] ; zeroρ = ϵ.ρ[end]
        i -= 1
    else
        oned = ϵ.d[i+1] ; zeroμ = ϵμ1 ; oneμ = ϵ.μ[i+1] ; zeroρ = ϵ.ρ[i] ; oneρ = ϵ.ρ[i+1]
    end
    d̂ = (d - zerod)/(oned - zerod)
    # μ(zeroμ, oneμ, d̂), μ(zeroρ, oneρ, d̂), ϵ.∂[i] && ϵ.∂[i+1], ϵ.∂[2i] && ϵ.∂[2(i+1)]
    μ(zeroμ, oneμ, d̂), μ(zeroρ, oneρ, d̂), ϵ.∂d[i], ϵ.∂d[i+1]
end
function ∂(x, ϵ) # x ∈ cl(ϵ)
    for (i, d) = enumerate(ϵ.d)
        ρ = ϵ.ρ[i]
        iszero(ρ) && continue
        μ = ϵ.μ[i]
        μ̂, _ = μρ(x, d)
        ẑero, ône = μ - ρ,μ + ρ
        (μ̂ == ẑero || μ̂ == ône) && return true
    end
    false
end
function ∃(x, ϵ, ϵ̂) # x ∈ cl(ϵ̂)
    ○̂ = ○(eltype(ϵ̂.μ))
    ∂(x, ϵ̂) && return ○̂
    isnothing(ϵ) && ( x ⫉ ϵ̂ || return ○̂ )
    x̂ = unit(x, ϵ̂)
    x ∩ ϵ̂ && return ϵ̂.∃(x̂)
    for ϵ̃ = ϵ̂.ϵ
        ϵ̃ == ϵ && continue
        x ⫉ ϵ̃ || continue
        x ∩ ϵ̃ && return ϵ̃.∃(x̂)
    end
    isnothing(ϵ̂.∃̂) && return ○̂
    ∃(x, ϵ̂, ϵ̂.∃̂)
end
# [0,1] ⊆ [0,1] : true,true : true
# ]0,1] ⊆ [0,1] : false,true : true
# [0,1] ⊆ ]0,1] : true,false : false
# ]0,1] ⊆ ]0,1] : false, false : true
function ⊆(zero₁, one₁, czero₁, cone₁, zero₂, one₂, czero₂, cone₂)
    żero = zero₂ < zero₁ || (zero₂ == zero₁ && (!czero₁ || czero₂))
    ȯne = one₁ < one₂ || (one₁ == one₂ && (!cone₁ || cone₂))
    żero && ȯne
end
function ⫉(ϵ, ϵ̂)
    for (i, d) ∈ enumerate(ϵ̂.d)
        ρ̂ = ϵ̂.ρ[i]
        iszero(ρ̂) && continue
        μ̂ = ϵ̂.μ[i]
        μ, ρ, zero∂, one∂ = μρ(ϵ, d)
        żero, ȯne = μ - ρ, μ + ρ
        ẑero, ône = μ̂ - ρ̂, μ̂ + ρ̂
        !⊆(żero, ȯne, zero∂, one∂, ẑero, ône, ϵ.∂[i], ϵ.∂[2i]) && return false
    end
    true
end
# ∩ false:
# [0,1] ∩ [2,3]
# [0,1] ∩ ]1,3]
# [0,1[ ∩ ]1,3]
# ∩(0,1,true,true,2,3,true,true)
# ∩(0,1,true,true,1,3,false,true)
# ∩(0,1,true,false,1,3,false,true)
# ∩(0,2,true,false,1,3,false,true)
function Base.:∩(zero₁, one₁, czero₁, cone₁, zero₂, one₂, czero₂, cone₂)
    ẑero = max(zero₁, zero₂)
    ône = min(one₁, one₂)
    ẑero < ône && return true
    ẑero ≠ ône && return false
    cẑero = zero₂ < zero₁ ? czero₁ : (zero₁ < zero₂ ? czero₂ : czero₁ && czero₂)
    cône = one₁ < one₂ ? cone₁ : (one₂ < one₁ ? cone₂ : cone₁ && cone₂)
    cẑero && cône
end
# function ⩀()
#     for (i, d) ∈ enumerate(ϵ.d)
#         żero, ȯne = ϵ.μ[i] - ϵ.ρ[i], ϵ.μ[i] + ϵ.ρ[i]
#         μ̂, ρ̂, ẑero∂, ône∂ = μρ(ϵ̂, d)
#         ẑero, ône = μ̂ - ρ̂, μ̂ + ρ̂
#         !∩(żero, ȯne, ϵ.∂[i], ϵ.∂[2i], ẑero, ône, ẑero∂, ône∂) && return false
#     end
#     true
# end
# d̂: 0.1 ... 0.2 
# ϵ: [0.5±0.1[ ... [0.5+x±0.1] ... ]0.6±0.1]
# ϵ̂: [0.3±0.1[ ... [0.3+x±0.1] ... ]0.4±0.1]
function Base.:∩(ϵ::∃, ϵ̂::∃)
    d̂ = sort(∪(ϵ.d, ϵ̂.d))
    for (i, d) ∈ d̂
        μ, ρ, zero∂, one∂ = μρ(ϵ, d)
        μ̂, ρ̂, ẑero∂, ône∂ = μρ(ϵ̂, d)
        żero, ȯne = μ - ρ, μ + ρ
        ẑero, ône = μ̂ - ρ̂, μ̂ + ρ̂
        ∩(żero, ȯne, zero∂, one∂, ẑero, ône, ẑero∂, ône∂) && return true

    end
    isempty(ϵ̂.ϵ) && return true
    any(ϵ̃ -> ϵ ∩ ϵ̃, ϵ̂.ϵ)
end
function ∃!(ϵ::∃, Ω::∀)
    ϵ̂ = ∃̂(ϵ, Ω)
    ϵ̂ === Ω && ( ϵ̃ = ∃(ϵ, Ω) ; push!(Ω.ϵ, ϵ̃) ; return ϵ̃ )
    ϵ̇ = ∃(ϵ, ϵ̂)
    ϵ̇ ∩ ϵ̂ && return nothing
    any(ϵ̃ -> ϵ̇ ∩ ϵ̃, ϵ̂.ϵ) && return nothing
    push!(ϵ̂.ϵ, ϵ̇)
end
function Base.push!(ϵ̂::Pretopology, ϵ::∃)
    ϵ̃ = ∃(ϵ, ϵ̂)
    push!(ϵ̂.ϵ, ϵ̃)
    ϵ̃
end
function ∃̂(ϵ::∃, ϵ̂::Pretopology)
    ϵϵ = filter(ϵ̃ -> ϵ ⫉ ϵ̃, ϵ̂.ϵ)
    isempty(ϵϵ) && return ϵ̂
    1 < length(ϵϵ) && return
    ϵ̃ = only(ϵϵ)
    ∃̂(ϵ, ϵ̃)
end
function Θ(ϵ::Pretopology)
    n = length(ϵ.ϵ)
    for ϵ̂ = ϵ.ϵ n += Θ(ϵ̂)end
    n
end

# end
