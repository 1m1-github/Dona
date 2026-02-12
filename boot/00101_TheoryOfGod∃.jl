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
        God = new(ϵ̃, Ο, ReentrantLock(), Ref(1))
        God.Ο[God] = God.s[]
        God
    end
end
Base.hash(::𝕋, h::UInt) = hash(:God, h)
t(God::𝕋) = one(T) - one(T) / (one(T) + T(log(God.Ο[God])))
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
function Base.copy!(ϵ::∃, ϵ̂::∃, God::𝕋)
    !haskey(God.ϵ̃, ϵ) && return
    d = δ(ϵ, ϵ̂)
    ϵ̃ = ∃(ϵ̂, d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.Φ)
    ∃!(ϵ̃, God, ϵ̂)
    for ϵ̃̃ = God.ϵ̃[ϵ]
        copy!(ϵ̃̃, ϵ̃, God)
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
    ϵ₁God = ℼ(ϵ₁)
    ϵ₂God = ℼ(ϵ₂)
    μ = μ̃(ϵ₁God.μ, ϵ₂God)
    ρ = ρ̃(ϵ₁God.ρ, ϵ₂God)
    ∃(ϵ₂, ϵ₁.d, μ, ρ, ϵ₁.∂, ϵ₁.Φ)
end
⫉(ϵ, ::𝕋) = true
function ⫉(ϵ₁::∃, ϵ₂::∃)
    ϵ₁.ϵ̂ === ϵ₂.ϵ̂ && return ⪽(ϵ₁, ϵ₂)
    ϵ̂ = α(ϵ₁, ϵ₂)
    ℼ(ϵ₁, ϵ̂) ⪽ ℼ(ϵ₂, ϵ̂)
end
function β(ϵ₁::∃, ϵ₂::∀, God::𝕋)
    ϵ̃ = get(God.ϵ̃, ϵ₂, ∃[])
    ϵ̃₂ = filter(ϵ̃ -> ϵ̃ ≠ ϵ₁ && ϵ₁ ⫉ ϵ̃, ϵ̃)
    isempty(ϵ̃₂) && return ϵ₂
    1 < length(ϵ̃₂) && throw("Need unique fitting parent.")
    β(ϵ₁, only(ϵ̃₂), God)
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
function Base.:∩(ϵ₁::∃, ϵ₂::∃, God::𝕋)
    if ϵ₁.ϵ̂ !== ϵ₂.ϵ̂
        ϵ̂ = α(ϵ₁, ϵ₂)
        return ∩(ℼ(ϵ₁, ϵ̂), ℼ(ϵ₂, ϵ̂), God)
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
    ϵ̃ = God.ϵ̃[ϵ₂]
    isempty(ϵ̃) && return true
    ϵ̂ = ℼ(ϵ₁, ϵ₂)
    all(ϵ̃ -> ∩(ϵ̂, ϵ̃, God), ϵ̃)
end
@kernel function Φ!(out, Φ, coords)
    i = @index(Global)
    out[i] = Φ(coords[i])
end
function gpu(Φ, x, backend=CPU())
    out = KernelAbstractions.zeros(backend, T, length(x))
    x̂ = KernelAbstractions.allocate(backend, typeof(x[1]), length(x))
    copyto!(x̂, x)
    k! = Φ!(backend, 2^2^3)
    k!(out, Φ, x̂, ndrange=length(x))
    KernelAbstractions.synchronize(backend)
    Array(out)
end
X(i, ♯::NTuple) = ntuple(î -> T(i[î] - 1) / T(♯[î] - 1), length(♯))
function X(ϵ::∃, God::𝕋, ♯::NTuple)
    Ξ = Array{∀}(undef, ♯...)
    ρ₀ = zero(ϵ.ρ)
    Threads.@threads for i in CartesianIndices(Ξ)
        x = X(i, ♯)
        xϵ = ∃(God, ϵ.d, SVector(x), ρ₀, ϵ.∂, ϵ.Φ)
        Ξ[i], _ = X(xϵ, God, ϵ)
    end
    Ξ
end
function X(x::∃, God::𝕋, ϵ::∀=β(x, God, God))
    ∂(x, ϵ) && return God, true
    ϵ̃ = get(God.ϵ̃, ϵ, ∃[])
    for ϵ̃ = filter(ϵ̃ -> x ⫉ ϵ̃, ϵ̃)
        ∩(x, ϵ̃, God) && return ϵ̃, true
        ϵ̂, found = X(x, God, ϵ̃)
        found && return ϵ̂, true
    end
    God, false
end
function ∃̇(ϵ::∃, God::𝕋, ♯::NTuple)
    ẋ = X(ϵ, God, ♯)
    ♯̇ = fill(○, ♯...)
    x = Dict{∃, Vector{CartesianIndex}}()
    for i in CartesianIndices(ẋ)
        xᵢ = ẋ[i]
        xᵢ === God && continue
        push!(get!(x, xᵢ, []), i)
    end
    for (ẋᵢ, i) in x
        xᵢ = map(i -> X(i, ♯), i)
        Φ̇ = gpu(ẋᵢ.Φ, xᵢ)
        for (i₁, i₂) in enumerate(i)
            ♯̇[i₂] = Φ̇[i₁]
        end
    end
    ♯̇
end
function ∃!(ϵ::∃, God::𝕋, ϵ̂::∀=β(ϵ, God, God))
    isbitstype(typeof(ϵ.Φ)) || return nothing
    lock(God.L)
    ϵ̃ = get(God.ϵ̃, ϵ̂, ∃[])
    any(ϵ̃ -> ∩(ϵ, ϵ̃, God), ϵ̃) && (unlock(God.L); return nothing)
    if ϵ̂ !== ϵ.ϵ̂
        ϵ = ∃(ϵ̂, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.Φ)
    end
    ϵ̂ !== God && ∩(ϵ, ϵ̂, God) && (unlock(God.L); return nothing)
    while Sys.free_memory() < God.s[] + sizeof(ϵ)
        rm!(God)
    end
    push!(get!(God.ϵ̃, ϵ̂, ∃[]), ϵ)
    God.s[] += sizeof(ϵ)
    God.Ο[ϵ] = God.Ο[God]
    God.Ο[God] += 1
    unlock(God.L)
    ϵ
end
function rm!(God::𝕋)
    ϵ̂̂ = argmin(ϵ -> God.Ο[ϵ], filter(k -> k isa ∃, keys(God.Ο)))
    God.s[] -= sizeof(ϵ̂̂)
    filter!(ϵ -> ϵ !== ϵ̂̂, God.ϵ̃[ϵ̂̂.ϵ̂])
    delete!(God.ϵ̃, ϵ̂̂)
    delete!(God.Ο, ϵ̂̂)
end
