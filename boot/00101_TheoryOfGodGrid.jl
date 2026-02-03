struct Grid
    n::Vector{Int}
end

index(n) = (collect(i) for i ∈ Iterators.product((1:n̂ for n̂ ∈ n)...))
function ∃(♯::Grid, ϵ::∃{T}) where {T<:Real}
    ○̂ = ○(T)
    ϵ̂ = fill(○̂, ♯.n...)
    ẑero = ϵ.μ - ϵ.ρ
    @threads for i = collect(index(♯.n))
        μ = fill(○̂, length(ϵ.d))
        for î = eachindex(ϵ.d)
            μ[î] = isone(♯.n[î]) ? ϵ.μ[î] : ẑero[î] + 2 * ϵ.ρ[î] * T(i[î] - 1) / T(♯.n[î] - 1)
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
