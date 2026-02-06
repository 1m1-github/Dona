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
    @show ♯.n
    ○̂ = ○(T)
    ϵ̂ = fill(○̂, ♯.n...)
    ẑero = zero(ϵ)
    # i = collect(index(♯.n))[1]
    # @threads for i = collect(index(♯.n))
    for i = collect(index(♯.n)) # DEBUG
        try
        μ = fill(○̂, length(ϵ.d))
        for î = eachindex(ϵ.d)
            μ[î] = isone(♯.n[î]) ? ϵ.μ[î] : ẑero.μ[î] + 2 * ϵ.ρ[î] * T(i[î] - 1) / T(♯.n[î] - 1)
        end
        x = X(ϵ, μ) # x ∈ cl(ϵ)
        # ϵ̂[i...] = ∃̇(x, ϵ)
        ϵ̂[i...] = ∃̇(x)
        # @show i, x.μ, ϵ̂[i...]
    catch e 
        @show e, i 
        break
    end
    end
    ϵ̂
end
