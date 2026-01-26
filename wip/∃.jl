using SHA
using Serialization

# === Constants ===

const Ξ = Dict{Vector{UInt8},Real}()  # existence cache

○(::Type{T}) where {T<:Real} = one(T) / (one(T) + one(T))

# === Point ===

struct X{T<:Real}
    d::Dict{T,T}
    ∂::Symbol
end

X(d::Dict{T,T}) where {T<:Real} = X{T}(d, :ZEROZERO)

function γ(x::X{T}, d::T) where {T<:Real}
    haskey(x.d, d) && return x.d[d]
    isempty(x.d) && return ○(T)
    (x.∂ == :ZEROZERO || x.∂ == :ONEONE) && return ○(T)
    
    ks = sort(collect(keys(x.d)))
    v0 = haskey(x.d, zero(T)) ? x.d[zero(T)] : ○(T)
    v1 = haskey(x.d, one(T)) ? x.d[one(T)] : ○(T)
    
    if d < ks[1]
        x.∂ == :ZEROONE && return v0
        x.∂ == :ONEZERO && return x.d[ks[1]]
    elseif d > ks[end]
        x.∂ == :ZEROONE && return x.d[ks[end]]
        x.∂ == :ONEZERO && return v1
    else
        i = findlast(k -> k ≤ d, ks)
        x.∂ == :ZEROONE && return x.d[ks[i]]
        x.∂ == :ONEZERO && return x.d[ks[i+1]]
    end
    
    ○(T)
end

Base.getindex(x::X{T}, d::T) where {T<:Real} = γ(x, d)

# === Existence ===

struct ∃{T<:Real}
    ι::String
    d::Vector{T}
    μ::Vector{T}
    ρ::Vector{T}
    ∂::Vector{Symbol}
    ∃::Function
    ∀::Union{∃{T},Nothing}
    h::Vector{UInt8}
    ϵ::Vector{∃{T}}
end

function Base.hash(η::∃)
    io = IOBuffer()
    serialize(io, (η.ι, η.d, η.μ, η.ρ, η.∂))
    sha3_512(take!(io))
end

function γ(η::∃{T}, d::T) where {T<:Real}
    isempty(η.d) && return ○(T)
    
    ks = η.d
    n = length(ks)
    
    if d < ks[1]
        mode = η.∂[1]
        (mode == :ZEROZERO || mode == :ONEONE) && return ○(T)
        mode == :ZEROONE && return ○(T)
        mode == :ONEZERO && return η.μ[1]
    elseif d > ks[end]
        mode = η.∂[n+1]
        (mode == :ZEROZERO || mode == :ONEONE) && return ○(T)
        mode == :ZEROONE && return η.μ[n]
        mode == :ONEZERO && return ○(T)
    else
        i = findlast(k -> k ≤ d, ks)
        if d == ks[i]
            return η.μ[i]
        else
            mode = η.∂[i+1]
            (mode == :ZEROZERO || mode == :ONEONE) && return ○(T)
            mode == :ZEROONE && return η.μ[i]
            mode == :ONEZERO && return η.μ[i+1]
        end
    end
end

# === Validation ===

function □(μ::Vector{T}, ρ::Vector{T}) where {T<:Real}
    length(μ) ≠ length(ρ) && return false
    for (o, r) ∈ zip(μ, ρ)
        (r < zero(T) || o - r < zero(T) || o + r > one(T)) && return false
    end
    true
end

□(x::X{T}) where {T<:Real} = all(v -> zero(T) ≤ v ≤ one(T), values(x.d))

function □(d::Vector{T}, μ::Vector{T}, ρ::Vector{T}, ∂::Vector{Symbol}) where {T<:Real}
    n = length(d)
    length(μ) ≠ n && return false
    length(ρ) ≠ n && return false
    length(∂) ≠ n + 1 && return false
    !□(μ, ρ) && return false
    true
end

# === Bounds Check ===

function ⫉(x::X{T}, η::∃{T}) where {T<:Real}
    for (i, d) ∈ enumerate(η.d)
        v = x[d]
        lo, hi = η.μ[i] - η.ρ[i], η.μ[i] + η.ρ[i]
        (v < lo || v > hi) && return false
    end
    true
end

# === Boundary Modes ===

closed_zero(mode::Symbol) = mode == :ONEZERO || mode == :ONEONE
closed_one(mode::Symbol) = mode == :ZEROONE || mode == :ONEONE

# === Membership ===

function ∈(x::X{T}, η::∃{T}) where {T<:Real}
    n = length(η.d)
    n == 0 && return true
    
    ks = sort(collect(keys(x.d)))
    
    for d ∈ ks
        if d ∉ η.d
            v = x.d[d]
            ηv = γ(η, d)
            v ≠ ηv && return false
        end
    end
    
    for (i, d) ∈ enumerate(η.d)
        v = x[d]
        lo, hi = η.μ[i] - η.ρ[i], η.μ[i] + η.ρ[i]
        
        if lo == hi
            v ≠ lo && return false
            continue
        end
        
        cl = closed_zero(η.∂[i])
        cr = closed_one(η.∂[i+1])
        
        if cl
            v < lo && return false
        else
            v ≤ lo && return false
        end
        if cr
            v > hi && return false
        else
            v ≥ hi && return false
        end
    end
    true
end

# === At Boundary ===

function ∂(x::X{T}, η::∃{T}) where {T<:Real}
    for (i, d) ∈ enumerate(η.d)
        η.ρ[i] == zero(T) && continue
        v = x[d]
        lo, hi = η.μ[i] - η.ρ[i], η.μ[i] + η.ρ[i]
        (v == lo || v == hi) && return true
    end
    false
end

# === Disjoint Intervals ===

function ∅(lo₁, hi₁, cl₁, cr₁, lo₂, hi₂, cl₂, cr₂)
    if cr₁ && cl₂
        hi₁ < lo₂ && return true
    else
        hi₁ ≤ lo₂ && return true
    end
    if cr₂ && cl₁
        hi₂ < lo₁ && return true
    else
        hi₂ ≤ lo₁ && return true
    end
    false
end

# === Intersection ===

function ∩(η::∃{T}, η′::∃{T}) where {T<:Real}
    for (i, d) ∈ enumerate(η.d)
        if d ∉ η′.d
            v = γ(η′, d)
            lo, hi = η.μ[i] - η.ρ[i], η.μ[i] + η.ρ[i]
            cl = closed_zero(η.∂[i])
            cr = closed_one(η.∂[i+1])
            
            if cl
                (v < lo) && return false
            else
                (v ≤ lo) && return false
            end
            if cr
                (v > hi) && return false
            else
                (v ≥ hi) && return false
            end
        end
    end
    
    for (j, d) ∈ enumerate(η′.d)
        if d ∉ η.d
            v = γ(η, d)
            lo, hi = η′.μ[j] - η′.ρ[j], η′.μ[j] + η′.ρ[j]
            cl = closed_zero(η′.∂[j])
            cr = closed_one(η′.∂[j+1])
            
            if cl
                (v < lo) && return false
            else
                (v ≤ lo) && return false
            end
            if cr
                (v > hi) && return false
            else
                (v ≥ hi) && return false
            end
        end
    end
    
    for (i, d) ∈ enumerate(η.d)
        j = findfirst(==(d), η′.d)
        j === nothing && continue
        
        lo₁, hi₁ = η.μ[i] - η.ρ[i], η.μ[i] + η.ρ[i]
        lo₂, hi₂ = η′.μ[j] - η′.ρ[j], η′.μ[j] + η′.ρ[j]
        
        cl₁ = closed_zero(η.∂[i])
        cr₁ = closed_one(η.∂[i+1])
        cl₂ = closed_zero(η′.∂[j])
        cr₂ = closed_one(η′.∂[j+1])
        
        ∅(lo₁, hi₁, cl₁, cr₁, lo₂, hi₂, cl₂, cr₂) && return false
    end
    
    n, m = length(η.d), length(η′.d)
    if n > 0 && m > 0
        mode₁ = η.∂[n+1]
        mode₂ = η′.∂[m+1]
        mode₁ ≠ mode₂ && return false
        if mode₁ == :ZEROONE
            tail₁ = η.μ[n]
            tail₂ = η′.μ[m]
            tail₁ ≠ tail₂ && return false
        end
    end
    
    true
end

# === Containment ===

function ⊂(η′::∃{T}, η::∃{T}) where {T<:Real}
    for (i, d) ∈ enumerate(η.d)
        lo, hi = η.μ[i] - η.ρ[i], η.μ[i] + η.ρ[i]
        j = findfirst(==(d), η′.d)
        if j === nothing
            v = γ(η′, d)
            (v < lo || v > hi) && return false
        else
            lo′, hi′ = η′.μ[j] - η′.ρ[j], η′.μ[j] + η′.ρ[j]
            (lo′ < lo || hi′ > hi) && return false
        end
    end
    true
end

# === Find Parent ===

function ∀(η′::∃{T}, Ω::∃{T}) where {T<:Real}
    for c ∈ Ω.ϵ
        ⊂(η′, c) && return ∀(η′, c)
    end
    Ω
end

# === Create ===

function ∃!(Ω::∃{T}, ι::String, d::Vector{T}, μ::Vector{T}, ρ::Vector{T},
            ∂::Vector{Symbol}, E::Function) where {T<:Real}
    !□(d, μ, ρ, ∂) && return nothing
    η′ = ∃{T}(ι, d, μ, ρ, ∂, E, nothing, UInt8[], ∃{T}[])
    p = ∀(η′, Ω)
    p ≢ Ω && ∩(p, η′) && return nothing
    any(c -> ∩(c, η′), p.ϵ) && return nothing
    η = ∃{T}(ι, d, μ, ρ, ∂, E, p, hash(p), ∃{T}[])
    push!(p.ϵ, η)
    η
end

# === Hash Point ===

function h(x::X{T}) where {T<:Real}
    io = IOBuffer()
    serialize(io, (x.d, x.∂))
    sha3_512(take!(io))
end

# === Observe ===

function ∃(x::X{T}, η::∃{T}) where {T<:Real}
    !□(x) && return (○(T), η, false)
    
    for c ∈ η.ϵ
        if ⫉(x, c)
            r = ∃(x, c)
            r[2] ≢ η && return r
        end
    end
    
    x ∈ η || return (○(T), η, true)
    ∂(x, η) && return (○(T), η, true)
    
    k = h(x)
    haskey(Ξ, k) && return (Ξ[k], η, true)
    Ξ[k] = η.∃(x)
    (Ξ[k], η, true)
end

# === Grid ===

struct ♯{T<:Real}
    d::Vector{T}
    μ::Vector{T}
    ρ::Vector{T}
    n::Vector{Int}
    ∂::Symbol
end

♯(d::Vector{T}, μ::Vector{T}, ρ::Vector{T}, n::Vector{Int}) where {T<:Real} = ♯{T}(d, μ, ρ, n, :ZEROZERO)

function X(g::♯{T}, idx::Vector{Int}) where {T<:Real}
    p = Dict{T,T}()
    for (i, d) ∈ enumerate(g.d)
        lo, hi = g.μ[i] - g.ρ[i], g.μ[i] + g.ρ[i]
        p[d] = g.n[i] == 1 ? g.μ[i] : lo + T(idx[i] - 1) / T(g.n[i] - 1) * (hi - lo)
    end
    X{T}(p, g.∂)
end

i(g::♯) = (collect(idx) for idx ∈ Iterators.product((1:n for n ∈ g.n)...))

function ∃(g::♯{T}, η::∃{T}) where {T<:Real}
    Dict(collect(idx) => ∃(X(g, collect(idx)), η)[1] for idx ∈ i(g))
end

function array(g::♯{T}, r::Dict{Vector{Int},T}) where {T<:Real}
    [r[[i,j]] for i ∈ 1:g.n[1], j ∈ 1:g.n[2]]
end