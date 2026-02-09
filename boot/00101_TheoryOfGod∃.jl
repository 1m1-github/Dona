export ∃, ∃!

const THEORYOFGOD = """
I = [ZERO < ○ < ONE] denotes a unit 1-dim space of information with origin ○ (no information) in its center including the corners ZERO and ONE.
∀ = I^I an ∞-dim metric and smooth vector space.
We have a Pretopology ℙ on ∀ such that ϵᵢ ∈ ℙ:
* ϵᵢ ⊆ ∀
* ϵ₂ ∈ ϵ₁.ϵ̃ => ϵ₂|ϵ₁ ⊆ ϵ₁ <=> ϵ₂ ⫉ ϵ₁ ⩓ ϵ₂ ∈ ϵ₃.ϵ̃ => ϵ₁ = ϵ₃
* ϵ₁ ≠ ϵ₂ => ϵ₁ ∩ ϵ₂ = ∅
* x ∈ ϵᵢ ⊊ ∀: x.ρ = 0 => ϵᵢ.Φ(x) ∈ I is arbitrary, computable and smooth fuzzy existence potential towards ONE=true xor ZERO=false with its inputs being the current coordinates and any known local coordinate with values of Φ previously computed.

ϵ ⊊ ∀ defines its existence inside a subset of ∀ using an origin (μ), a radius (ρ) and a closed vs. open in each direction (∂) vector. These vectors are finite and all other dimensional coordinates of ϵ follow from linear interpolation.
If we use a horizontal axis for dimension and a vertical axis for coordinate in the dimension, for any ϵ, the chart looks like a stepwise linear function with finite non-zero radius intervals and zero interval points within the interpolated regions.
Each child ϵ is a subset of its parent in the active dimensions (0 < ρ) declared by the parent (as opposed to undeclared dimensions where 0==ρ).

god ⊊ God ⊊ GOD = ∀ = I^I = I^(.) = [ZERO < ○ < ONE]^(.)

god can observe all, God can create in non-existing non-past, GOD can iterate all.
"""

○(::Type{T}) where {T<:Real} = one(T) / (one(T) + one(T))
abstract type ∀{T<:Real} end
struct ∃{N,T<:Real} <: ∀{T}
    ϵ̂::∀{T}
    ι::String
    d::SVector{N,T}
    μ::SVector{N,T}
    ρ::SVector{N,T}
    ∂::NTuple{N,Tuple{Bool,Bool}}
    Φ::Function
    function ∃{N,T}(ϵ̂::∀{T}, ι::String, d::SVector{N,T}, μ::SVector{N,T}, ρ::SVector{N,T}, ∂::NTuple{N,Tuple{Bool,Bool}}, Φ::Function) where {N,T<:Real}
        @assert 1 ≤ N
        p = sortperm(d)
        new{N,T}(ϵ̂, ι, d[p], μ[p], ρ[p], ntuple(i -> ∂[p[i]], N), Φ)
    end
end
# T=Float64
# struct Q{N,T<:Real} <: ∀{T}
#     q::SVector{N,T}
# end
# q1=Q(SA[1])
# q2=Q(SA[1,2])
# qs=Q{<:Any,Int}[]
# push!(qs, q1)
# push!(qs, q2)
# qs
struct ℙ{T<:Real} <: ∀{T}
    ϵ̃::ConcurrentDict{∀{T}, Vector{∃{<:Any,T}}}
    Ο::ConcurrentDict{∀{T}, Int}
end
Base.hash(::∀, ::UInt) = zero(UInt)
function Base.hash(ϵ::∃, h::UInt)
    h = hash(ϵ.d, h)
    h = hash(ϵ.μ, h)
    h = hash(ϵ.ρ, h)
    h = hash(ϵ.∂, h)
    hash(objectid(ϵ.ϵ̂), h)
end
# Base.:(==)(ϵ::∃, ::∀) = false
# Base.:(==)(ϵ₁::∃, ϵ₂::∃) = ϵ₁.d == ϵ₂.d && ϵ₁.μ == ϵ₂.μ && ϵ₁a.ρ == ϵ₂.ρ && ϵ₁.∂ == ϵ₂.∂ && objectid(ϵ₁.ϵ̂) == objectid(ϵ₂.ϵ̂)
# Ο() = Ο(GOD::ℙ) = 
# Ο(ϵ) = 1 + sum((Ο(ϵ̂) for ϵ̂ in ϵ.ϵ), init=0)
t(GOD::ℙ{T}) where {T<:Real} = one(T) - one(T) / (one(T) + T(log(GOD.Ο[GOD])))
# Base.zero(::∀) = ∃{T}("zero(∀)", [zero(T), one(T)], [zero(T), zero(T)], [zero(T), zero(T)], fill(true, 4), _ -> ○(T), Ω, ∃{T}[])
# Base.one(::∀) = ∃{T}("one(∀)", [zero(T), one(T)], [one(T), one(T)], [zero(T), zero(T)], fill(true, 4), _ -> ○(T), Ω, ∃{T}[])
# Base.zero(ϵ::∃) = X(ϵ, ϵ.μ .- ϵ.ρ)
# Base.one(ϵ::∃) = X(ϵ, ϵ.μ .+ ϵ.ρ)
# Base.eltype(::∀{N,T}) where {N,T<:Real} = T
# Base.ndims(::∀{N,T}) where {N,T<:Real} = N

μ̂(ϵ) = ϵ.μ .- ϵ.ρ .+ 2 .* ϵ.ρ .* ϵ.ϵ̂.μ
ρ̂(ϵ) = 2 .* ϵ.ϵ̂.ρ .* ϵ.ρ
μ̃(μ::SVector{N,T}, ϵ::∃{N,T}) where {N,T<:Real} = (μ .- (ϵ.μ .- ϵ.ρ)) ./ ϵ.ρ ./ 2
ρ̃(ρ::SVector{N,T}, ϵ::∃{N,T}) where {N,T<:Real} = ρ ./ ϵ.ρ ./ 2
# ∃(ϵ, ϵ̂) = ∃{N,T}(ϵ̂, ϵ.ι, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.∃)
# X(ϵ, μ) = ∃{N,T}(ϵ, "x at $μ in $(ϵ.ι)", ϵ.d, μ, zero(ϵ.ρ), ntuple(i -> (true, true), N), _ -> one(T))
function μρ(ϵ::∃{N,T}, d::SVector{N,T}) where {N,T<:Real}
    ○̂ = ○(T)
    i = searchsortedfirst(ϵ.d, d)
    if i ≤ N && ϵ.d[i] == d
        return ϵ.μ[i], ϵ.ρ[i], ϵ.∂[i]
    end
    d₀ = d₁ = ϵ.d[1]
    dₙ = ϵ.d[N]
    μ₀ = μ₁ = ○̂
    if d < d₀
        d₀ = zero(T)
        μ₁ = ϵ.μ[1]
    elseif dₙ < d
        d₀, d₁ = dₙ, one(T)
        μ₀ = ϵ.μ[N]
    else
        d₀, d₁ = ϵ.d[i-1], ϵ.d[i]
        μ₀, μ₁ = ϵ.μ[i-1], ϵ.μ[i]
    end
    d = (d - d₀) / (d₁ - d₀)
    μ₀ + (μ₁ - μ₀) * d, zero(T), (true, true)
end
function ∂(x::∃{N,T}, ::ℙ{T}) where {N,T<:Real}
    zeroₓ = x.μ .- x.ρ
    any(zeroₓ .== zero(T)) && return true
    oneₓ = x.μ .+ x.ρ
    any(oneₓ .== one(T))
end
function ∂(x::∃{N,T}, ϵ::∃{N,T}) where {N,T<:Real}
    zeroμ, oneμ = ϵ.μ .- ϵ.ρ, ϵ.μ .+ ϵ.ρ
    for (i, d) = enumerate(ϵ.d)
        iszero(ϵ.ρ[i]) && continue
        μₓ, _ = μρ(x, d)
        (μₓ == zeroμ[i] || μₓ == oneμ[i]) && return true
    end
    false
end
function Base.:(⊆)(zero₁::SVector{N,T}, one₁::SVector{N,T}, ∂₁::NTuple{N,Tuple{Bool,Bool}}, zero₂::SVector{N,T}, one₂::SVector{N,T}, ∂₂::NTuple{N,Tuple{Bool,Bool}}) where {N,T<:Real}
    żero = zero₂ < zero₁ || (zero₂ == zero₁ && (!∂₁[1] || ∂₂[1]))
    ȯne = one₁ < one₂ || (one₁ == one₂ && (!∂₁[2] || ∂₂[2]))
    żero && ȯne
end
function ⪽(ϵ₁::∃{N,T}, ϵ₂::∃{N,T}) where {N,T<:Real}
    x = true
    for (i₂, d₂) = enumerate(ϵ₂.d)
        ρ₂ = ϵ₂.ρ[i₂]
        iszero(ρ₂) && continue
        x = false
        μ₂ = ϵ₂.μ[i₂]
        μ₁, ρ₁, ∂₁ = μρ(ϵ₁, d₂)
        zero₁, one₁ = μ₁ - ρ₁, μ₁ + ρ₁
        zero₂, one₂ = μ₂ - ρ₂, μ₂ + ρ₂
        !⊆(zero₁, one₁, ∂₁, zero₂, one₂, ϵ₂.∂[i₂]) && return false
    end
    !x
end
α(::∀) = Set(Ω)
function α(ϵ)
    αϵ = Set{ℙ}([ϵ])
    p = ϵ.ϵ̂
    while p isa ∃
        push!(αϵ, p)
        p = p.ϵ̂
    end
    # push!(αϵ, Ω)
    αϵ
end
function α(ϵ, ϵ̂)
    αϵ = α(ϵ)
    ϵ̂ ∈ αϵ && return ϵ̂
    p = ϵ̂.∃̂
    while p isa ∃
        p ∈ αϵ && return p
        p = p.∃̂
    end
    # Ω
    nothing # ?
end
function ℼ(ϵ::∃{N,T}, GOD::ℙ{T}) where {N,T<:Real}
    ϵ̂ = ϵ.ϵ̂
    ϵ̂ === GOD && return ϵ
    ϵ̂̂ = ∃{N,T}(ϵ̂.ϵ̂, ϵ.ι * " ∈ " * ϵ̂.ι, ϵ.d, μ̂(ϵ), ρ̂(ϵ), ϵ.∂, ϵ.∃) # todo string speed
    ℼ(ϵ̂̂, GOD)
end
function ℼ(ϵ₁::∃{N,T}, ϵ₂::∃{N,T}) where {N,T<:Real}
    ○̂ = fill(○(T), N)
    ϵ₁ === ϵ₂ && return ∃{N,T}(ϵ₂, ϵ₁.ι, ϵ₁.d, ○̂, ○̂, ϵ₁.∂, ϵ₁.∃)
    ϵ₁.ϵ̂ === ϵ₂ && return ϵ₁
    if ϵ₂ ∈ ω(ϵ₁)
        return ℼ(∃{N,T}(ϵ₁.ι, ϵ₁.d, μ̂(ϵ₁), ρ̂(ϵ₁), ϵ₁.∂, ϵ₁.∃, ϵ₁.ϵ̂.ϵ̂), ϵ₂)
    end
    ϵ₁Ω = ℼ(ϵ₁, Ω)
    ϵ₂Ω = ℼ(ϵ₂, Ω)
    μ = μ̃(ϵ₁Ω.μ, ϵ₂Ω)
    ρ = ρ̃(ϵ₁Ω.ρ, ϵ₂Ω)
    ∃{N,T}(ϵ₂, ϵ₁.ι, ϵ₁.d, μ, ρ, ϵ₁.∂, ϵ₁.∃)
end
⫉(ϵ, ::∀) = true
function ⫉(ϵ₁, ϵ₂::∃)
    ϵ₁.ϵ̂ === ϵ₂.ϵ̂ && return ⪽(ϵ₁, ϵ₂)
    ϵ̂ = α(ϵ₁, ϵ₂)
    ℼ(ϵ₁, ϵ̂) ⪽ ℼ(ϵ₂, ϵ̂)
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
function Base.:∩(ϵ::∃, ϵ̂::∃)
    if ϵ.∃̂ !== ϵ̂.∃̂
        ω = α(ϵ, ϵ̂)
        return ℼ(ϵ, ω) ∩ ℼ(ϵ̂, ω)
    end
    d̂ = sort(ϵ.d ∪ ϵ̂.d)
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
    ϵ̇ = ℼ(ϵ, ϵ̂)
    all(ϵ̃ -> ϵ̇ ∩ ϵ̃, ϵ̂.ϵ)
end
∃̇(x, ϵ) = ∃̇(x, ○(T), x, ○(T), x, ϵ) # x ∈ cl(ϵ̂)
function ∃̇(onex, onex∃, zerox, zero∃, x, ϵ) # x ∈ cl(ϵ̂)
    ∂(x, ϵ) && return Ω, ○(T), true
    for ϵ̂ = filter(ϵ̂ -> x ⫉ ϵ̂, ϵ.ϵ)
        x ∩ ϵ̂ && return ϵ̂, ϵ̂.∃(onex, onex∃, zerox, zero∃, x), true
        ϵ̃, ϵ̇, found = ∃̇(x, ϵ̂)
        found && return ϵ̃, ϵ̇, true
    end
    Ω, ○(T), false
end
function ∃!(ϵ)
    ϵ̂ = ∃̂(ϵ)
    any(ϵ̃ -> ϵ ∩ ϵ̃, ϵ̂.ϵ) && return nothing
    lock(L)
    ϵ̃ = ϵ̂ === ϵ.∃̂ ? ϵ : ∃(ϵ, ϵ̂)
    ϵ̂ !== Ω && ϵ̃ ∩ ϵ̂ && (unlock(L); return nothing)
    push!(ϵ̂.ϵ, ϵ̃)
    unlock(L)
    ϵ̃
end
function ∃̂(ϵ, ϵ̂=Ω)
    ϵϵ = filter(ϵ̃ -> ϵ̃ ≠ ϵ && ϵ ⫉ ϵ̃, ϵ̂.ϵ)
    isempty(ϵϵ) && return ϵ̂
    1 < length(ϵϵ) && throw("Need unique fitting parent.")
    ϵ̃ = only(ϵϵ)
    ∃̂(ϵ, ϵ̃)
end
