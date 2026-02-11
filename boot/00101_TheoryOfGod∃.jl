# using StaticArrays
# const T = Float64

export ∃, ∃̇, ∃!

const THEORYOFGOD = """
I = [ZERO < ○ < ONE] denotes a unit 1-dim space of information with origin ○ (no information) in its center including the corners ZERO and ONE.
∀ = I^I an ∞-dim metric and smooth vector space.
We have a Pretopology 𝕋 on ∀ such that ϵᵢ ∈ 𝕋:
* ϵᵢ ⊆ ∀
* ϵ₂ ∈ ϵ₁.ϵ̃ => ϵ₂|ϵ₁ ⊆ ϵ₁ <=> ϵ₂ ⫉ ϵ₁ ⩓ ϵ₂ ∈ ϵ₃.ϵ̃ => ϵ₁ = ϵ₃
* ϵ₁ ≠ ϵ₂ => ϵ₁ ∩ ϵ₂ = ∅
* x ∈ ϵᵢ ⊊ ∀: x.ρ = 0 => ϵᵢ.Φ(x) ∈ I is arbitrary, computable and smooth fuzzy existence potential towards ONE=true xor ZERO=false.

ϵ ⊊ ∀ defines its existence inside a subset of ∀ using an origin (μ), a radius (ρ) and a closed vs. open in each direction (∂) vector. These vectors are finite and all other dimensional coordinates of ϵ follow from linear interpolation.
If we use a horizontal axis for dimension and a vertical axis for coordinate in the dimension, for any ϵ, the chart looks like a stepwise linear function with finite non-zero radius intervals and zero interval points within the interpolated regions.
Each child ϵ is a subset of its parent in the active dimensions (0 < ρ) declared by the parent (as opposed to undeclared dimensions where 0==ρ).

god ⊊ God ⊊ GOD = ∀ = I^I = I^(.) = [ZERO < ○ < ONE]^(.)

god can observe all, God can create in non-existing non-past, GOD can iterate all.
god observes, God creates, GOD iterates.
"""

const ○ = one(T) / (one(T) + one(T))
abstract type ∀ end
struct ∃{N,F} <: ∀
    ϵ̂::∀
    d::SVector{N,T}
    μ::SVector{N,T}
    ρ::SVector{N,T}
    ∂::NTuple{N,Tuple{Bool,Bool}}
    Φ::F
    h::UInt
    function ∃(ϵ̂::∀, d::SVector{N,T}, μ::SVector{N,T}, ρ::SVector{N,T}, ∂::NTuple{N,Tuple{Bool,Bool}}, Φ::F) where {N,F}
        @assert 1 ≤ N
        p = sortperm(d)
        d, μ, ρ = map(x -> x[p], (d, μ, ρ))
        ∂ = ntuple(i -> ∂[p[i]], N)
        h = hash(d, hash(μ, hash(ρ, hash(∂, hash(ϵ̂)))))
        new{N,F}(ϵ̂, d, μ, ρ, ∂, Φ, h)
    end
end
Base.hash(ϵ::∃, h) = hash(ϵ.h, h)
struct 𝕋 <: ∀
    ϵ̃::Dict{∀,Vector{∃}}
    Ο::Dict{∀,Int}
    L::ReentrantLock
    s::Ref{Int}
    function 𝕋()
        ϵ̃ = Dict{∀,Vector{∃}}()
        Ο = Dict{∀,Int}()
        GOD = new(ϵ̃, Ο, ReentrantLock(), Ref(1))
        GOD.Ο[GOD] = GOD.s[]
        GOD
    end
end
Base.hash(::𝕋, h) = hash(:GOD, h)
t(GOD::𝕋) = one(T) - one(T) / (one(T) + T(log(GOD.Ο[GOD])))
function δ(ϵ::∃, ϵ̂::∃)
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
function Base.copy!(ϵ::∃, ϵ̂::∃, GOD::𝕋)
    !haskey(GOD.ϵ̃, ϵ) && return
    d = δ(ϵ, ϵ̂)
    ϵ̃ = ∃(ϵ̂, d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.Φ)
    ∃!(ϵ̃, GOD, ϵ̂)
    for ϵ̃̃ = GOD.ϵ̃[ϵ]
        copy!(ϵ̃̃, ϵ̃, GOD)
    end
    ϵ̃
end
μ̂(ϵ::∃) = ϵ.ϵ̂ isa 𝕋 ? ϵ.μ : ϵ.μ .- ϵ.ρ .+ 2 .* ϵ.ρ .* ϵ.ϵ̂.μ
ρ̂(ϵ::∃) = ϵ.ϵ̂ isa 𝕋 ? ϵ.ρ : 2 .* ϵ.ϵ̂.ρ .* ϵ.ρ
μ̃(μ, ϵ::∃) = (μ .- (ϵ.μ .- ϵ.ρ)) ./ ϵ.ρ ./ 2
ρ̃(ρ, ϵ::∃) = ρ ./ ϵ.ρ ./ 2
function μρ(ϵ::∃, d)
    i = searchsortedfirst(ϵ.d, d)
    N = length(ϵ.d)
    if i ≤ N && ϵ.d[i] == d
        return ϵ.μ[i], ϵ.ρ[i], ϵ.∂[i]
    end
    d₀ = d₁ = ϵ.d[1]
    dₙ = ϵ.d[N]
    μ₀ = μ₁ = ○
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
function ∂(x::∃, ::𝕋)
    zeroₓ = x.μ .- x.ρ
    any(zeroₓ .== zero(T)) && return true
    oneₓ = x.μ .+ x.ρ
    any(oneₓ .== one(T))
end
function ∂(x::∃, ϵ::∃)
    zeroμ, oneμ = ϵ.μ .- ϵ.ρ, ϵ.μ .+ ϵ.ρ
    for (i, d) = enumerate(ϵ.d)
        iszero(ϵ.ρ[i]) && continue
        μₓ, _ = μρ(x, d)
        (μₓ == zeroμ[i] || μₓ == oneμ[i]) && return true
    end
    false
end
function Base.:(⊆)(zero₁, one₁, ∂₁::Tuple{Bool,Bool}, zero₂, one₂, ∂₂::Tuple{Bool,Bool})
    żero = zero₂ < zero₁ || (zero₂ == zero₁ && (!∂₁[1] || ∂₂[1]))
    ȯne = one₁ < one₂ || (one₁ == one₂ && (!∂₁[2] || ∂₂[2]))
    żero && ȯne
end
function ⪽(ϵ₁::∃, ϵ₂::∃)
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
function α(ϵ₁::∃, ϵ₂::∃)
    αϵ₁ = α(ϵ₁)
    ϵ₂ ∈ αϵ₁ && return ϵ₂
    ϵ̂ = ϵ₂.ϵ̂
    while ϵ̂ isa ∃
        ϵ̂ ∈ αϵ₁ && return ϵ̂
        ϵ̂ = ϵ̂.ϵ̂
    end
    nothing
end
function ℼ(ϵ::∃)
    ϵ̂ = ϵ.ϵ̂
    ϵ̂ isa 𝕋 && return ϵ
    ϵ̂̂ = ∃(ϵ̂.ϵ̂, ϵ.d, μ̂(ϵ), ρ̂(ϵ), ϵ.∂, ϵ.Φ)
    ℼ(ϵ̂̂)
end
ℼ(ϵ, ::Nothing) = ℼ(ϵ)
function ℼ(ϵ₁::∃, ϵ₂::∃)
    ○̂ = fill(○, length(ϵ₁.d))
    ϵ₁ === ϵ₂ && return ∃(ϵ₂, ϵ₁.d, ○̂, ○̂, ϵ₁.∂, ϵ₁.Φ)
    ϵ₁.ϵ̂ === ϵ₂ && return ϵ₁
    if ϵ₂ ∈ α(ϵ₁)
        return ℼ(∃(ϵ₁.ϵ̂.ϵ̂, ϵ₁.d, μ̂(ϵ₁), ρ̂(ϵ₁), ϵ₁.∂, ϵ₁.Φ), ϵ₂)
    end
    ϵ₁GOD = ℼ(ϵ₁)
    ϵ₂GOD = ℼ(ϵ₂)
    μ = μ̃(ϵ₁GOD.μ, ϵ₂GOD)
    ρ = ρ̃(ϵ₁GOD.ρ, ϵ₂GOD)
    ∃(ϵ₂, ϵ₁.d, μ, ρ, ϵ₁.∂, ϵ₁.Φ)
end
⫉(ϵ, ::𝕋) = true
function ⫉(ϵ₁::∃, ϵ₂::∃)
    ϵ₁.ϵ̂ === ϵ₂.ϵ̂ && return ⪽(ϵ₁, ϵ₂)
    ϵ̂ = α(ϵ₁, ϵ₂)
    ℼ(ϵ₁, ϵ̂) ⪽ ℼ(ϵ₂, ϵ̂)
end
# ϵ₁,ϵ₂=ϵ, GOD
function β(ϵ₁::∃, ϵ₂::∀, GOD::𝕋)
    ϵ̃ = get(GOD.ϵ̃, ϵ₂, ∃[])
    ϵ̃₂ = filter(ϵ̃ -> ϵ̃ ≠ ϵ₁ && ϵ₁ ⫉ ϵ̃, ϵ̃)
    isempty(ϵ̃₂) && return ϵ₂
    1 < length(ϵ̃₂) && throw("Need unique fitting parent.")
    β(ϵ₁, only(ϵ̃₂), GOD)
end
function Base.:∩(zero₁, one₁, ∂₁::Tuple{Bool,Bool}, zero₂, one₂, ∂₂::Tuple{Bool,Bool})
    żero = max(zero₁, zero₂)
    ȯne = min(one₁, one₂)
    żero < ȯne && return true
    żero ≠ ȯne && return false
    ∂₀₀ = zero₂ < zero₁ ? ∂₁[1] : (zero₁ < zero₂ ? ∂₂[1] : ∂₁[1] && ∂₂[1])
    ∂₀₁ = one₁ < one₂ ? ∂₁[2] : (one₂ < one₁ ? ∂₂[2] : ∂₁[2] && ∂₂[2])
    ∂₀₀ && ∂₀₁
end
function Base.:∩(ϵ₁::∃, ϵ₂::∃, GOD::𝕋)
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
# function observe(ϵ::∃, ♯::NTuple)
#     g = fill(○, ♯...)
#     N = length(♯)
#     Threads.@threads for idx in CartesianIndices(g)
#         x = ntuple(i -> T(idx[i] - 1) / T(♯[i] - 1), N)
#         g[idx] = ϵ.Φ(x)
#     end
#     g
# end
function gpu_eval(Φ, coords)
    out = Vector{T}(undef, length(coords))
    Threads.@threads for i in eachindex(coords)
        out[i] = Φ(coords[i])
    end
    out
end
idx_to_coord(idx, ♯) = ntuple(i -> T(idx[i] - 1) / T(♯[i] - 1), length(♯))
function observe(ϵ::∃, GOD::𝕋, ♯::NTuple)
    owners = assign_owners(ϵ, GOD, ♯)
    grid = fill(○, ♯...)
    
    # group indices by owner
    groups = Dict{∃, Vector{CartesianIndex}}()
    for idx in CartesianIndices(owners)
        push!(get!(groups, owners[idx], []), idx)
    end
    
    # one GPU kernel per owner
    for (owner, indices) in groups
        # all points in this group share the same Φ
        # launch as single kernel
        coords = map(idx -> idx_to_coord(idx, ♯), indices)
        values = gpu_eval(owner.Φ, coords)  # single kernel, fully parallel
        for (i, idx) in enumerate(indices)
            grid[idx] = values[i]
        end
    end
    grid
end
function X(x::∃, GOD::𝕋, ϵ::∀=β(x, GOD, GOD))
    ∂(x, ϵ) && return GOD, true
    ϵ̃ = get(GOD.ϵ̃, ϵ, ∃[])
    for ϵ̃ = filter(ϵ̃ -> x ⫉ ϵ̃, ϵ̃)
        ∩(x, ϵ̃, GOD) && return ϵ̃, true
        ϵ̂, found = ∃̇(x, ϵ̃, GOD)
        found && return ϵ̂, true
    end
    GOD, false
end
function assign_owners(ϵ::∃, GOD::𝕋, ♯::NTuple)
    Ξ = Array{∃}(undef, ♯...)
    Threads.@threads for i in CartesianIndices(Ξ)
        x = idx_to_coord(i, ♯)
        ξ, _ = X(x, GOD, ϵ)
        Ξ[i] = ξ
    end
    Ξ
end
# ϵ=ϵ̃
# ϵ̂=β(ϵ, GOD, GOD)
function ∃!(ϵ::∃, GOD::𝕋, ϵ̂::∀=β(ϵ, GOD, GOD))
    lock(GOD.L)
    ϵ̃ = get(GOD.ϵ̃, ϵ̂, ∃[])
    any(ϵ̃ -> ∩(ϵ, ϵ̃, GOD), ϵ̃) && (unlock(GOD.L); return nothing)
    if ϵ̂ !== ϵ.ϵ̂
        ϵ = ∃(ϵ̂, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.Φ)
    end
    ϵ̂ !== GOD && ∩(ϵ, ϵ̂, GOD) && (unlock(GOD.L); return nothing)
    while Sys.free_memory() < GOD.s[] + sizeof(ϵ)
        rm!(GOD)
    end
    push!(get!(GOD.ϵ̃, ϵ̂, ∃[]), ϵ)
    GOD.Ο[ϵ] = GOD.Ο[GOD]
    GOD.Ο[GOD] += 1
    unlock(GOD.L)
    ϵ
end
function rm!(GOD::𝕋)
    ϵ̂̂ = argmin(ϵ -> GOD.Ο[ϵ], filter(k -> k isa ∃, keys(GOD.Ο)))
    GOD.s[] -= sizeof(ϵ̂̂)
    filter!(ϵ -> ϵ !== ϵ̂̂, GOD.ϵ̃[ϵ̂̂.ϵ̂])
    delete!(GOD.ϵ̃, ϵ̂̂)
    delete!(GOD.Ο, ϵ̂̂)
end
