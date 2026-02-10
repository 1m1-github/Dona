export ∃, ∃̇, ∃!

const THEORYOFGOD = """
I = [ZERO < ○ < ONE] denotes a unit 1-dim space of information with origin ○ (no information) in its center including the corners ZERO and ONE.
∀ = I^I an ∞-dim metric and smooth vector space.
We have a Pretopology 𝕋 on ∀ such that ϵᵢ ∈ 𝕋:
* ϵᵢ ⊆ ∀
* ϵ₂ ∈ ϵ₁.ϵ̃ => ϵ₂|ϵ₁ ⊆ ϵ₁ <=> ϵ₂ ⫉ ϵ₁ ⩓ ϵ₂ ∈ ϵ₃.ϵ̃ => ϵ₁ = ϵ₃
* ϵ₁ ≠ ϵ₂ => ϵ₁ ∩ ϵ₂ = ∅
* x ∈ ϵᵢ ⊊ ∀: x.ρ = 0 => ϵᵢ.Φ(x, Φ̂, x̂) ∈ I is arbitrary, computable and smooth fuzzy existence potential towards ONE=true xor ZERO=false with its inputs being the current coordinates x and any previously computed local coordinates x̂ with values of Φ̂.

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
struct 𝕋{T<:Real} <: ∀{T}
    ϵ̃::ConcurrentDict{∀{T},Vector{∃{<:Any,T}}}
    Ο::ConcurrentDict{∀{T},Int}
    L::ReentrantLock
end
function new_parent_dims(ϵ::∃{N,T}, ϵ̂::∃{N,T})
    d = copy(ϵ.d)
    nϵ̂ = length(ϵ.ϵ̂.d)
    for (i, dᵢ) = enumerate(ϵ.d)
        iϵ̂ = searchsortedfirst(ϵ.ϵ̂.d, dᵢ)
        nϵ̂ < iϵ̂ && continue
        iszero(ϵ.ϵ̂.ρ[iϵ̂]) && continue
        d[i] = ϵ̂.d[iϵ̂]
    end
    d
end
function Base.copy!(ϵ::∃{N,T}, ϵ̂::∃{N,T}, GOD::𝕋{T}) where {N,T}
    !haskey(GOD.ϵ̃, ϵ) && return
    d = new_parent_dims(ϵ, ϵ̂)
    ϵ̃ = ∃{N,T}(ϵ̂, ϵ.ι, d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.Φ)
    ∃!(ϵ̃, GOD, ϵ̂)
    for ϵ̃̃ = GOD.ϵ̃[ϵ]
        copy!(ϵ̃̃, ϵ̃, GOD)
    end
    ϵ̃
end
Base.hash(::∀, ::UInt) = zero(UInt)
function Base.hash(ϵ::∃, h::UInt)
    h = hash(ϵ.d, h)
    h = hash(ϵ.μ, h)
    h = hash(ϵ.ρ, h)
    h = hash(ϵ.∂, h)
    hash(objectid(ϵ.ϵ̂), h)
end
t(GOD::𝕋{T}) where {T<:Real} = one(T) - one(T) / (one(T) + T(log(GOD.Ο[GOD])))

μ̂(ϵ::∃) = ϵ.ϵ̂ isa 𝕋 ? ϵ.μ : ϵ.μ .- ϵ.ρ .+ 2 .* ϵ.ρ .* ϵ.ϵ̂.μ
ρ̂(ϵ::∃) = ϵ.ϵ̂ isa 𝕋 ? ϵ.ρ : 2 .* ϵ.ϵ̂.ρ .* ϵ.ρ
μ̃(μ::SVector{N,T}, ϵ::∃{N,T}) where {N,T<:Real} = (μ .- (ϵ.μ .- ϵ.ρ)) ./ ϵ.ρ ./ 2
ρ̃(ρ::SVector{N,T}, ϵ::∃{N,T}) where {N,T<:Real} = ρ ./ ϵ.ρ ./ 2
function μρ(ϵ::∃{N,T}, d::T) where {N,T<:Real}
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
function ∂(x::∃{N,T}, ::𝕋{T}) where {N,T<:Real}
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
function α(ϵ)
    αϵ = Set{∃}([ϵ])
    p = ϵ.ϵ̂
    while p isa ∃
        push!(αϵ, p)
        p = p.ϵ̂
    end
    αϵ
end
function α(ϵ₁::∃{N,T}, ϵ₂::∃{N,T}) where {N,T<:Real}
    αϵ₁ = α(ϵ₁)
    ϵ₂ ∈ αϵ₁ && return ϵ₂
    ϵ̂ = ϵ₂.ϵ̂
    while ϵ̂ isa ∃
        ϵ̂ ∈ αϵ₁ && return ϵ̂
        ϵ̂ = ϵ̂.ϵ̂
    end
    nothing
end
function ℼ(ϵ::∃{N,T}) where {N,T<:Real}
    ϵ̂ = ϵ.ϵ̂
    ϵ̂ isa 𝕋 && return ϵ
    ϵ̂̂ = ∃{N,T}(ϵ̂.ϵ̂, "", ϵ.d, μ̂(ϵ), ρ̂(ϵ), ϵ.∂, ϵ.Φ)
    ℼ(ϵ̂̂)
end
ℼ(ϵ, ::Nothing) = ℼ(ϵ)
function ℼ(ϵ₁::∃{N,T}, ϵ₂::∃{N,T}) where {N,T<:Real}
    ○̂ = fill(○(T), N)
    ϵ₁ === ϵ₂ && return ∃{N,T}(ϵ₂, ϵ₁.ι, ϵ₁.d, ○̂, ○̂, ϵ₁.∂, ϵ₁.Φ)
    ϵ₁.ϵ̂ === ϵ₂ && return ϵ₁
    if ϵ₂ ∈ α(ϵ₁)
        return ℼ(∃{N,T}(ϵ₁.ϵ̂.ϵ̂, ϵ₁.ι, ϵ₁.d, μ̂(ϵ₁), ρ̂(ϵ₁), ϵ₁.∂, ϵ₁.Φ), ϵ₂)
    end
    ϵ₁GOD = ℼ(ϵ₁)
    ϵ₂GOD = ℼ(ϵ₂)
    μ = μ̃(ϵ₁GOD.μ, ϵ₂GOD)
    ρ = ρ̃(ϵ₁GOD.ρ, ϵ₂GOD)
    ∃{N,T}(ϵ₂, ϵ₁.ι, ϵ₁.d, μ, ρ, ϵ₁.∂, ϵ₁.Φ)
end
⫉(ϵ, ::𝕋) = true
function ⫉(ϵ₁::∃{N,T}, ϵ₂::∃{N,T}) where {N,T<:Real}
    ϵ₁.ϵ̂ === ϵ₂.ϵ̂ && return ⪽(ϵ₁, ϵ₂)
    ϵ̂ = α(ϵ₁, ϵ₂)
    ℼ(ϵ₁, ϵ̂) ⪽ ℼ(ϵ₂, ϵ̂)
end
function β(ϵ₁::∃{N,T}, ϵ₂::∀{T}, GOD::𝕋{T}) where {N,T<:Real}
    ϵ̃ = GOD.ϵ̃[ϵ₂]
    ϵ̃₂ = filter(ϵ̃ -> ϵ̃ ≠ ϵ₁ && ϵ₁ ⫉ ϵ̃, ϵ̃)
    isempty(ϵ̃₂) && return ϵ₂
    1 < length(ϵ̃₂) && throw("Need unique fitting parent.")
    β(ϵ₁, only(ϵ̃₂), GOD)
end
function Base.:∩(zero₁::SVector{N,T}, one₁::SVector{N,T}, ∂₁::NTuple{N,Tuple{Bool,Bool}}, zero₂::SVector{N,T}, one₂::SVector{N,T}, ∂₂::NTuple{N,Tuple{Bool,Bool}}) where {N,T<:Real}
    żero = max(zero₁, zero₂)
    ȯne = min(one₁, one₂)
    żero < ȯne && return true
    żero ≠ ȯne && return false
    ∂₀₀ = zero₂ < zero₁ ? ∂₁[1] : (zero₁ < zero₂ ? ∂₂[1] : ∂₁[1] && ∂₂[1])
    ∂₀₁ = one₁ < one₂ ? ∂₁[2] : (one₂ < one₁ ? ∂₂[2] : ∂₁[2] && ∂₂[2])
    ∂₀₀ && ∂₀₁
end
function Base.:∩(ϵ₁::∃{N,T}, ϵ₂::∃{N,T}, GOD::𝕋) where {N,T<:Real}
    if ϵ₁.ϵ̂ !== ϵ₂.ϵ̂
        ϵ̂ = α(ϵ₁, ϵ₂)
        return ∩(ℼ(ϵ₁, ϵ̂), ℼ(ϵ₂, ϵ̂), GOD)
    end
    d̂ = sort(ϵ₁.d ∪ ϵ₂.d)
    if !iszero(d̂[1])
        if !isone(d̂[end])
            d̂ = [zero(T), d̂..., one(T)]
        else
            d̂ = [zero(T), d̂...]
        end
    elseif !isone(d̂[end])
        d̂ = [d̂..., one(T)]
    end
    μ₁, ρ₁, ∂₁ = μρ(ϵ₁, zero(T))
    μ₂, ρ₂, ∂₂ = μρ(ϵ₂, zero(T))
    μ₁prev, μ₂prev = μ₁, μ₂
    for (i, d) = enumerate(d̂)
        if 1 < i
            μ₁, ρ₁, ∂₁ = μρ(ϵ₁, d)
            μ₂, ρ₂, ∂₂ = μρ(ϵ₂, d)
        end
        zero₁, one₁ = μ₁ - ρ₁, μ₁ + ρ₁
        zero₂, one₂ = μ₂ - ρ₂, μ₂ + ρ₂
        !∩(zero₁, one₁, ∂₁, zero₂, one₂, ∂₂) && return false
        i == 1 && continue
        (μ₁ - μ₂) * (μ₁prev - μ₂prev) < zero(T) && return true
        μ₁prev, μ₂prev = μ₁, μ₂
    end
    ϵ̃ = GOD.ϵ̃[ϵ₂]
    isempty(ϵ̃) && return true
    ϵ̂ = ℼ(ϵ₁, ϵ₂)
    all(ϵ̃ -> ∩(ϵ̂, ϵ̃, GOD), ϵ̃)
end
function ∃̇(x::∃{N,T}, ϵ::∃{N,T}, GOD::𝕋{T}, Φ̂::AbstractVector{T}=[], x̂::AbstractVector{CartesianIndex{N}}=[]) where {N,T<:Real}
    ∂(x, ϵ) && return GOD, ○(T), true
    for ϵ̃ = filter(ϵ̃ -> x ⫉ ϵ̃, GOD.ϵ̃[ϵ])
        ∩(x, ϵ̃, GOD) && return ϵ̃, ϵ̃.Φ(x, Φ̂, x̂), true
        ϵ̂, ϵ̇, found = ∃̇(x, ϵ̃, GOD)
        found && return ϵ̂, ϵ̇, true
    end
    GOD, ○(T), false
end
function ∃!(ϵ::∃{N,T}, GOD::𝕋{T}, ϵ̂::∃{N,T}=β(ϵ, GOD, GOD)) where {N,T<:Real}
    lock(GOD.L)
    ϵ̃ = GOD.ϵ̃[ϵ̂]
    any(ϵ̃ -> ∩(ϵ, ϵ̃, GOD), ϵ̃) && (unlock(GOD.L); return nothing)
    if ϵ̂ !== ϵ.ϵ̂
        ϵ = ∃{N,T}(ϵ̂, ϵ.ι, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.Φ)
    end
    ϵ̂ !== GOD && ∩(ϵ, ϵ̂, GOD) && (unlock(GOD.L); return nothing)
    push!(ϵ̃, ϵ)
    GOD.Ο[ϵ] = GOD.Ο[GOD]
    GOD.Ο[GOD] += 1
    unlock(GOD.L)
    ϵ
end
