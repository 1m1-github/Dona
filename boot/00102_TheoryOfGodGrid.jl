struct Grid
    n::Vector{Int}
end
index(n) = Iterators.product((1:n̂ for n̂ ∈ n)...)
function ∃̇(♯::Grid, ϵ::∃{T}) where {T<:Real}
    ○̂ = ○(T)
    ϵ̂ = fill(○̂, ♯.n...)
    μẑero = ϵ.μ .- ϵ.ρ
    @threads for i = collect(index(♯.n))
        μ = fill(○̂, length(ϵ.d))
        for î = eachindex(ϵ.d)
            μ[î] = isone(♯.n[î]) ? ϵ.μ[î] : μẑero[î] + 2 * ϵ.ρ[î] * T(i[î] - 1) / T(♯.n[î] - 1)
        end
        x = X(ϵ, μ) # x ∈ cl(ϵ)
        ϵ̂[i...] = ∃̇(x, ϵ)
    end
    ϵ̂
end

# ♯::Grid, ϵ::∃{T} = Grid([3,3]), one(Ω)
# ∃(Grid([3,3]), one(Ω)) 
