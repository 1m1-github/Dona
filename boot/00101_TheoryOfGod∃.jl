export ∃, ∃!

const THEORYOFGOD = """
I = [ZERO < ○ < ONE] denotes a unit 1-dim space of information with origin ○ (no information) in its center including the corners ZERO and ONE.
Ω = I^I an ∞-dim metric and smooth vector space.
We have a Pretopology on Ω such that ϵ ∈ ∃:
* ϵ ⊆ Ω
* ∃!ϵ̂: ϵ ∈ ϵ̂.ϵ: ϵ|ϵ̂ ⊆ ϵ̂ <=> ϵ ⫉ ϵ̂
* ∀ ϵ̂ ≠ ϵ: ϵ̂ ∩ ϵ = ∅
* ∀ x: x.ρ == 0 => ϵ.∃(x) ∈ I is arbitrary, computable and smooth fuzzy existence towards ONE=true xor ZERO=false.

ϵ ∈ ∃ defines its existence inside an Ω using an origin vector (μ) and a radius vector (ρ) and a closed vs. open in each direction (∂) vector, these vectors are finite and all other dimensional coordinates of ϵ follow from linear interpolation.
If we use a horizontal axis for dimension and a vertical axis for coordinate in the dimension, for any ϵ, the chart looks like a stepwise linear function with finite non-zero radius intervals and zero interval points within the interpolated regions.
Each child ϵ is a subset of its parent in the active dimensions (0 < ρ) declared by the parent (as opposed to undeclared dimensions where 0==ρ).

god ⊊ God ⊊ GOD === Ω === I^I === I^(.) === [ZERO < ○ < ONE]^(.)
"""

○(::Type{T}) where {T<:Real} = one(T) / (one(T) + one(T))
abstract type Pretopology{T<:Real} end
struct ∃{T<:Real} <: Pretopology{T}
    Ο::T
    ι::String
    d::Vector{T} # sorted, distinct
    μ::Vector{T} # length(μ) == length(d)
    ρ::Vector{T} # length(ρ) == length(d)
    ∂::Vector{Bool} # length(∂) == 2length(d), ∂[i] <=> [μ-ρ,..., ∂[i+1] <=> ...,μ+ρ] both in d=i
    ∃::Function # X(ρ=0) ∈ ∃ -> I
    ∃̂::Pretopology{T} # ∃ ⫉ ∃̂ ⩓ ∃ ∩ ∃̂ = ∅
    ϵ::Vector{∃{T}} # ϵ ⫉ ∃ ⩓ ϵ ∩ ∃ = ∅
    function ∃{T}(ι::String, d::Vector{T}, μ::Vector{T}, ρ::Vector{T}, ∂::Vector{Bool}, ∃::Function, ϵ̂::Pretopology{T}, ϵ::Vector{∃{T}}) where {T}
        new{T}(Ο(), ι, d, μ, ρ, ∂, ∃, ϵ̂, ϵ)
    end
end # todo check validity for outside creators ?
struct ∀{T<:Real} <: Pretopology{T}
    ϵ::Vector{∃{T}}
end
∃(ϵ, ϵ̂) = ∃{eltype(ϵ.μ)}(ϵ.ι, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.∃, ϵ̂, ϵ.ϵ)
X(ϵ, μ) = ∃("", ϵ.d, μ, zero(ϵ.d), fill(true, length(ϵ.∂)), _ -> one(eltype(ϵ.d)), ϵ, ∃{eltype(ϵ.d)}[]) # todo check μ ∈ [ϵ.μ-ϵ.ρ,ϵ.μ+ϵ.ρ] ?
unit(x, ϵ) = X(ϵ, (x.μ .- (ϵ.μ .- ϵ.ρ)) ./ ϵ.ρ ./ 2)
index(n) = (collect(i) for i ∈ Iterators.product((1:n̂ for n̂ ∈ n)...))
function ∃(n::Vector{<:Integer}, ϵ::∃{T}) where {T<:Real}
    ○̂ = ○(T)
    ϵ̂ = fill(○̂, n...)
    ẑero = ϵ.μ - ϵ.ρ
    @threads for i = collect(index(n))
        μ = fill(○̂, length(ϵ.d))
        for î = eachindex(ϵ.d)
            μ[î] = isone(n[î]) ? ϵ.μ[î] : ẑero[î] + 2 * ϵ.ρ[î] * T(i[î] - 1) / T(n[î] - 1)
        end
        x = X(ϵ, μ) # x ∈ cl(ϵ)
        if haskey(Ξ, x)
            ϵ̂[i...] = Ξ[x]
            continue
        end
        Ξ[x] = ϵ̂[i...] = ∃̇(x, ϵ)
    end
    ϵ̂
end
function μρ(ϵ, d)
    T = eltype(d)
    ○̂ = ○(T)
    isempty(ϵ.d) && return ○̂, 0, true, true
    i = searchsortedfirst(ϵ.d, d)
    i ≤ length(ϵ.d) && ϵ.d[i] == d && return ϵ.μ[i], ϵ.ρ[i], ϵ.∂[2i-1], ϵ.∂[2i]
    ϵd1 = ϵ.d[1] ; ϵdend = ϵ.d[end] ; ϵμ1 = ϵ.μ[1]
    zerod = ϵd1 ; oned = ϵd1 ; zeroμ = ○̂ ; oneμ = ○̂
    if d < ϵd1
        zerod = zero(T) ; oneμ = ϵμ1
    elseif ϵdend < d
        zerod = ϵdend ; oned = one(T) ; zeroμ = ϵ.μ[end]
    else
        zerod = ϵ.d[i-1] ; oned = ϵ.d[i] ; zeroμ = ϵ.μ[i-1] ; oneμ = ϵ.μ[i]
    end
    d̂ = (d - zerod)/(oned - zerod)
    zeroμ + (oneμ-zeroμ) * d̂, zero(T), true, true
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
function Base.issubset(zero₁, one₁, czero₁, cone₁, zero₂, one₂, czero₂, cone₂)
    żero = zero₂ < zero₁ || (zero₂ == zero₁ && (!czero₁ || czero₂))
    ȯne = one₁ < one₂ || (one₁ == one₂ && (!cone₁ || cone₂))
    żero && ȯne
end
function ⫉(ϵ, ϵ̂)
    x = true
    for (i, d) ∈ enumerate(ϵ̂.d)
        ρ̂ = ϵ̂.ρ[i]
        iszero(ρ̂) && continue
        x = false
        μ̂ = ϵ̂.μ[i]
        μ, ρ, zero∂, one∂ = μρ(ϵ, d)
        żero, ȯne = μ - ρ, μ + ρ
        ẑero, ône = μ̂ - ρ̂, μ̂ + ρ̂
        !⊆(żero, ȯne, zero∂, one∂, ẑero, ône, ϵ.∂[2i-1], ϵ.∂[2i]) && return false
    end
    !x
end
function Base.:∩(zero₁, one₁, czero₁, cone₁, zero₂, one₂, czero₂, cone₂)
    ẑero = max(zero₁, zero₂)
    ône = min(one₁, one₂)
    ẑero < ône && return true
    ẑero ≠ ône && return false
    cẑero = zero₂ < zero₁ ? czero₁ : (zero₁ < zero₂ ? czero₂ : czero₁ && czero₂)
    cône = one₁ < one₂ ? cone₁ : (one₂ < one₁ ? cone₂ : cone₁ && cone₂)
    cẑero && cône
end
function Base.:∩(ϵ, ϵ̂)
    T = eltype(ϵ.d)
    d̂ = sort(∪(ϵ.d, ϵ̂.d))
    if !iszero(d̂[1])
        if !isone(d̂[end])
            d̂ = [zero(T), d̂..., one(T)]
        else
            d̂ = [zero(T), d̂...]
        end
    elseif !isone(d̂[end])
        d̂ = [d̂..., one(T)]
    end
    μ, ρ, zero∂, one∂ = μρ(ϵ, zero(T))
    μ̂, ρ̂, ẑero∂, ône∂ = μρ(ϵ̂, zero(T))
    μprev, μ̂prev = μ, μ̂
    for (i, d) = enumerate(d̂)
        if 1 < i
            μ, ρ, zero∂, one∂ = μρ(ϵ, d)
            μ̂, ρ̂, ẑero∂, ône∂ = μρ(ϵ̂, d)
        end
        żero, ȯne = μ - ρ, μ + ρ
        ẑero, ône = μ̂ - ρ̂, μ̂ + ρ̂
        !∩(żero, ȯne, zero∂, one∂, ẑero, ône, ẑero∂, ône∂) && return false
        i == 1 && continue
        (μ - μ̂) * (μprev - μ̂prev) < 0 && return true
        μprev, μ̂prev = μ, μ̂
    end
    isempty(ϵ̂.ϵ) && return true
    all(ϵ̃ -> ϵ ∩ ϵ̃, ϵ̂.ϵ)
end
function ∃̇(x, ϵ) # x ∈ cl(ϵ̂)
    ○̂ = ○(eltype(ϵ.μ))
    ∂(x, ϵ) && return ○̂
    for ϵ̂ = ϵ.ϵ
        x ∩ ϵ̂ && return ϵ̂.∃(unit(x, ϵ̂))
    end
    x ∩ ϵ && return ϵ.∃(unit(x, ϵ))
    ○̂
end
function ∃!(ϵ)
    ϵ̂ = ∃̂(ϵ, Ω)
    any(ϵ̃ -> ϵ ∩ ϵ̃, ϵ̂.ϵ) && return nothing
    lock(L)
    ϵ̃ = ϵ̂ === ϵ.∃̂ ? ϵ̂ : ∃(ϵ, ϵ̂)
    ϵ̂ !== Ω && ϵ̃ ∩ ϵ̂ && ( unlock(L) ; return nothing )
    push!(ϵ̂.ϵ, ϵ̃)
    unlock(L)
    ϵ̃
end
function ∃̂(ϵ, ϵ̂)
    ϵϵ = filter(ϵ̃ -> ϵ ⫉ ϵ̃, ϵ̂.ϵ)
    isempty(ϵϵ) && return ϵ̂
    1 < length(ϵϵ) && throw("Need unique fitting parent.")
    ϵ̃ = only(ϵϵ)
    ∃̂(ϵ, ϵ̃)
end
function Base.hash(x::∃{T}, h::UInt) where T
    h = hash(x.d, h)
    h = hash(x.μ, h)
    h = hash(x.ρ, h)
    hash(x.∂, h)
end
Base.:(==)(a::∃, b::∃) = a.d == b.d && a.μ == b.μ && a.ρ == b.ρ && a.∂ == b.∂
Ο(ϵ=Ω) = one(T) + sum((Ο(ϵ̂) for ϵ̂ in ϵ.ϵ), init=zero(T))
