struct Grid
    n::Vector{Int}
end
# ♯=g.♯
# n=[1]
# collect(index(n))
# i = collect(index(n))[1]
index(n) = (collect(i) for i ∈ Iterators.product((1:n̂ for n̂ ∈ n)...))
# function ∃(♯::Grid, ϵ::Pretopology{T}) where {T<:Real}
function ∃(♯::Grid, ϵ::∃{T}) where {T<:Real}
    ○̂ = ○(T)
    ϵ̂ = fill(○̂, ♯.n...)
    ẑero = zero(ϵ)
    # i = collect(index(♯.n))[22]
    @threads for i = collect(index(♯.n))
        try
        μ = fill(○̂, length(ϵ.d))
        for î = eachindex(ϵ.d)
            μ[î] = isone(♯.n[î]) ? ϵ.μ[î] : ẑero.μ[î] + 2 * ϵ.ρ[î] * T(i[î] - 1) / T(♯.n[î] - 1)
        end
        x = X(ϵ, μ) # x ∈ cl(ϵ)
        # if haskey(Ξ, x)
        #     ϵ̂[i...] = Ξ[x]
        #     continue
        # end
        # Ξ[x] = ϵ̂[i...] = ∃̇(x, ϵ)
        # ϵ̂[i...] = ∃̇(x, ϵ)
        ϵ̂[i...] = ∃̇(x)
    catch e @show e end
    end
    ϵ̂
end
