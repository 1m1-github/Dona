const ○ = one(T) / (one(T) + one(T))
abstract type ∀ end
struct ∃{N,F,P<:∀} <: ∀
    ϵ̂::P
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
        new{N,F,typeof(ϵ̂)}(ϵ̂, d, μ, ρ, ∂, Φ, h)
    end
end
Base.hash(ϵ::∃, h::UInt) = hash(ϵ.h, h)
struct 𝕋 <: ∀
    ϵ̃::Dict{∀,Vector{∃}}
    Ο::Dict{∀,Int}
    L::ReentrantLock
    s::Ref{Int}
    function 𝕋()
        ϵ̃ = Dict{∀,Vector{∃}}()
        Ο = Dict{∀,Int}()
        God = new(ϵ̃, Ο, ReentrantLock(), Ref(1))
        God.ϵ̃[God] = ∃[]
        God.Ο[God] = God.s[]
        God
    end
end
Base.hash(::𝕋, h::UInt) = hash(:God, h)
Ο(t::T) = exp(t / (1 - t))
t(Ο::Int) = one(T) - one(T) / (one(T) + T(log(Ο)))
t(ϵ::∀=God) = t(God.Ο[ϵ])
# δ(ϵ, ϵ)
# function δ(ϵ::∃, ϵ̂::∃)
#     nϵ̂ = length(ϵ.ϵ̂.d)
#     SVector(ntuple(length(ϵ.d)) do i
#         dᵢ = ϵ.d[i]
#         iϵ̂ = searchsortedfirst(ϵ.ϵ̂.d, dᵢ)
#         iϵ̂ ≤ nϵ̂ && !iszero(ϵ.ϵ̂.ρ[iϵ̂]) && return ϵ̂.d[iϵ̂]
#         dᵢ
#     end)
# end
# function Base.copy!(ϵ::∃, ϵ̂::∃, God::𝕋)
#     ϵϵ̃ = God.ϵ̃[ϵ]
#     d = δ(ϵ, ϵ̂)
#     ϵ̃ = ∃(ϵ̂, d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.Φ)
#     ∃!(ϵ̃, God, ϵ̂)
#     for ϵ̃̃ = ϵϵ̃
#         copy!(ϵ̃̃, ϵ̃, God)
#     end
#     ϵ̃
# end
ρ̂(ϵ::∃) = 2 .* ϵ.ϵ̂.ρ .* ϵ.ρ
μ̂(ϵ::∃) = ϵ.ϵ̂.μ .- ϵ.ϵ̂.ρ .+ 2 .* ϵ.ϵ̂.ρ .* ϵ.μ
# μ̂(ϵ::∃) = ϵ.μ : ϵ.μ .- ϵ.ρ .+ 2 .* ϵ.ρ .* ϵ.ϵ̂.μ
# ρ̂(ϵ::∃) = ϵ.ρ : 2 .* ϵ.ϵ̂.ρ .* ϵ.ρ
μ̃(ϵ::∃, μ) = (μ .- (ϵ.μ .- ϵ.ρ)) ./ ϵ.ρ ./ 2
ρ̃(ϵ::∃, ρ) = ρ ./ ϵ.ρ ./ 2
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
    any(==(zero(T)), zeroₓ) && return true
    oneₓ = x.μ .+ x.ρ
    any(==(one(T)), oneₓ)
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
# (i₂, d₂) = collect(enumerate(ϵ₂.d))[4]
function ⪽(ϵ₁::∃, ϵ₂::∃)
    x = true
    for (i₂, d₂) = enumerate(ϵ₂.d)
        ρ₂ = ϵ₂.ρ[i₂]
        iszero(ρ₂) && continue
        x && ( x = false )
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
    God
end
function ℼ(ϵ::∃)
    ϵ̂ = ϵ.ϵ̂
    ϵ̂ isa 𝕋 && return ϵ
    ϵ̂̂ = ∃(ϵ̂.ϵ̂, ϵ.d, μ̂(ϵ), ρ̂(ϵ), ϵ.∂, ϵ.Φ)
    ℼ(ϵ̂̂)
end
ℼ(ϵ, ::𝕋) = ℼ(ϵ)
function ℼ(ϵ₁::∃, ϵ₂::∃)
    ○̂ = SVector(ntuple(_->○, length(ϵ₁.d)))
    ϵ₁ === ϵ₂ && return ∃(ϵ₂, ϵ₁.d, ○̂, ○̂, ϵ₁.∂, ϵ₁.Φ)
    ϵ₁.ϵ̂ === ϵ₂ && return ϵ₁
    if ϵ₂ ∈ α(ϵ₁)
        return ℼ(∃(ϵ₁.ϵ̂.ϵ̂, ϵ₁.d, μ̂(ϵ₁), ρ̂(ϵ₁), ϵ₁.∂, ϵ₁.Φ), ϵ₂)
    end
    ϵ₁God = ℼ(ϵ₁)
    ϵ₂God = ℼ(ϵ₂)
    μ = μ̃(ϵ₂God, ϵ₁God.μ)
    ρ = ρ̃(ϵ₂God, ϵ₁God.ρ)
    ∃(ϵ₂, ϵ₁.d, μ, ρ, ϵ₁.∂, ϵ₁.Φ)
end
⫉(ϵ, ::𝕋) = true
# ϵ₁ , ϵ₂ = ϵ₁,ϵ̃
function ⫉(ϵ₁::∃, ϵ₂::∃)
    ϵ₁.ϵ̂ === ϵ₂.ϵ̂ && return ϵ₁ ⪽ ϵ₂
    ϵ̂ = α(ϵ₁, ϵ₂)
    ℼ(ϵ₁, ϵ̂) ⪽ ℼ(ϵ₂, ϵ̂)
end
# ϵ₁=x
# ϵ₂=God
# ϵ̃ = filter(ϵ̃ -> ϵ̃ ≠ ϵ₁, ϵ̃)[1]
# ϵ₁ ⫉ ϵ̃
function β(ϵ₁::∃, ϵ₂::∀)
    ϵ̃ = God.ϵ̃[ϵ₂]
    ϵ̃₂ = filter(ϵ̃ -> ϵ̃ ≠ ϵ₁ && ϵ₁ ⫉ ϵ̃, ϵ̃)
    isempty(ϵ̃₂) && return ϵ₂
    β(ϵ₁, only(ϵ̃₂))
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
Base.:∩(ϵ₁::∃, ::𝕋, ::𝕋) = true
# ϵ₁, ϵ₂=ϵ,ϵ̂
function Base.:∩(ϵ₁::∃, ϵ₂::∃)
    if ϵ₁.ϵ̂ !== ϵ₂.ϵ̂
        ϵ̂ = α(ϵ₁, ϵ₂)
        return ℼ(ϵ₁, ϵ̂) ∩ ℼ(ϵ₂, ϵ̂)
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
        μ₁prev < μ₂prev && μ₂ < μ₁ && return true
        μ₂prev < μ₁prev && μ₁ < μ₂ && return true
        μ₁prev, μ₂prev = μ₁, μ₂
    end
    ϵ̃ = get(God.ϵ̃, ϵ₂, ∃[])
    isempty(ϵ̃) && return true
    ϵ̂ = ℼ(ϵ₁, ϵ₂)
    all(ϵ̃ -> ϵ̂ ∩ ϵ̃, ϵ̃)
end
@kernel function Φ!(out, Φ, coords)
    i = @index(Global)
    out[i] = Φ(coords[i])
end
X(i, ♯::NTuple) = ntuple(î -> isone(♯[î]) ? ○ : T(i[î] - 1) / T(♯[î] - 1), length(♯))
# x=xϵ
# ϵ=β(x, God, God)
# ϵ.Φ(1)
function X(x::∃)
    ϵ = β(x, God)
    ϵ === God && return God, true
    ∂(x, ϵ) && return God, true 
    x ∩ ϵ && return ϵ, true # ?
    ϵ̃ = God.ϵ̃[ϵ]
    for ϵ̃ = filter(ϵ̃ -> x ⫉ ϵ̃, ϵ̃)
        x ∩ ϵ̃ && return ϵ̃, true
        ϵ̂, found = X(x)
        found && return ϵ̂, true
    end
    God, false
end
# i = collect(CartesianIndices(Ξ))[23]
# Ξ[i].Φ(1)
function X(ϵ::∃, ♯::NTuple)
    Ξ = Array{∀}(undef, ♯...)
    ρ₀ = zero(ϵ.ρ)
    # Threads.@threads 
    for i in CartesianIndices(Ξ)
        x = X(i, ♯)
        xϵ = ∃(God, ϵ.d, SVector(x), ρ₀, ϵ.∂, ϵ.Φ)
        Ξ[i], _ = X(xϵ)
    end
    Ξ
end
# ♯=g.♯
# all(ϵ -> ϵ isa ∀, ϵ̂)
# ẋ[2,2] !== God
# (ϵ̂, i) = collect(ϵ̂x)[1]
# ẋᵢ.Φ(1)
# God.Ο[ϵ]
# ϵ=ϵ̃
function ∃̇(ϵ::∃, ♯::NTuple)
    ϵ̂ = X(ϵ, ♯)
    ♯̇ = fill(○, ♯...)
    ϵ̂x = Dict{∃, Vector{CartesianIndex}}()
    for i = CartesianIndices(ϵ̂)
        ϵ̂ᵢ = ϵ̂[i]
        ϵ̂ᵢ === God && continue
        push!(get!(ϵ̂x, ϵ̂ᵢ, []), i)
    end
    for (ϵ̂, i) = ϵ̂x
        x = map(i -> X(i, ♯), i)
        Φ̇ = gpu(ϵ̂.Φ, x)
        for (i₁, i₂) = enumerate(i)
            ♯̇[i₂] = Φ̇[i₁]
        end
    end
    ♯̇
end
# ϵ=ϵ̂
function ∃!(ϵ::∃)
    gpu_safe(ϵ.Φ, [zeros(length(ϵ.d))]) || return nothing
    lock(God.L)
    ϵ̂ = β(ϵ, God)
    ϵ̃ = God.ϵ̃[ϵ̂]
    any(ϵ̃ -> ϵ ∩ ϵ̃, ϵ̃) && (unlock(God.L); return nothing)
    if ϵ̂ !== ϵ.ϵ̂
        ϵ = ∃(ϵ̂, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ϵ.Φ)
    end
    ϵ̂ !== God && ϵ ∩ ϵ̂ && (unlock(God.L); return nothing)
    while Sys.free_memory() < God.s[] + sizeof(ϵ)
        rm!(God)
    end
    God.s[] += sizeof(ϵ)
    God.Ο[God] += 1
    God.Ο[ϵ] = God.Ο[God]
    push!(God.ϵ̃[ϵ̂], ϵ)
    God.ϵ̃[ϵ] = ∃[]
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
# ϵ₁, ϵ₂ = ône, ẑero
# (i, d) = collect(enumerate(d̂))[2]
function Base.:(-)(ϵ₁::∃, ϵ₂::∃)
    d̂ = sort!(ϵ₂.d ∪ ϵ₁.d)
    N = length(d̂)
    μ = MVector{N,T}(undef)
    ρ = MVector{N,T}(undef)
    ∂out = Vector{Tuple{Bool,Bool}}(undef, N)
    for (i, d) in enumerate(d̂)
        ϵ₂μ, ϵ₂ρ, ϵ₂∂ = μρ(ϵ₂, d)
        ϵ₁μ, ϵ₁ρ, ϵ₁∂ = μρ(ϵ₁, d)
        żero = ϵ₂μ - ϵ₂ρ
        ȯne = ϵ₁μ + ϵ₁ρ
        ρ[i] = (ȯne - żero) / 2
        μ[i] = żero + ρ[i]
        ∂out[i] = (ϵ₂∂[1], ϵ₁∂[2])
    end
    ϵ̂ = α(ϵ₁, ϵ₂)
    ∃(ϵ̂, SVector{N}(d̂), SVector{N}(μ), SVector{N}(ρ), NTuple{N}(∂out), ϵ₁.Φ)
end
# ϵ̂.Φ, x
# Φ = ẋᵢ.Φ
# x = ẋᵢ
# backend = CPU()
# Φ(1)
function gpu(Φ, x, backend=CPU())
    out = KernelAbstractions.zeros(backend, T, length(x))
    ẋ = KernelAbstractions.allocate(backend, typeof(x[1]), length(x))
    copyto!(ẋ, x)
    k! = Φ!(backend, 2^2^3)
    k!(out, Φ, ẋ, ndrange=length(x))
    KernelAbstractions.synchronize(backend)
    Array(out)
end
function gpu_safe(Φ, x, backend=CPU())
    try
        gpu(Φ, x, backend)
        true
    catch
        false
    end
end
