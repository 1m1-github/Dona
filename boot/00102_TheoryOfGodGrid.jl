# struct Grid
#     n::Vector{Int}
# end
# function ∃̇(♯::Grid, ϵ::∃{T}, k::Int, Ξ::Dict{∃, Tuple{Pretopology{T}, T}}) where {T<:Real}
function ∃̇(♯::NTuple{N,Int}, F::Function) where N
    Ns = ntuple(d -> (1 << ks[d]) + 1, N)
    maxk = maximum(ks)
    
    grid = fill(NaN, Ns...)
    
    center = CartesianIndex(ntuple(d -> (Ns[d]+1)>>1, N))
    grid[center] = F(center, Float64[], CartesianIndex{N}[])
    
    for b in 0:(1<<N)-1
        ci = CartesianIndex(ntuple(d -> 1 + (Ns[d]-1)*((b>>(d-1))&1), N))
        grid[ci] = F(ci, [grid[center]], [center])
    end
    
    for ℓ in 1:maxk
        ss = ntuple(d -> ℓ ≤ ks[d] ? 1 << (ks[d]-ℓ) : 0, N)
        strides = ntuple(d -> max(ss[d], 1), N)
        ci = CartesianIndices(ntuple(d -> 1:strides[d]:Ns[d], N))
        
        @threads for pt in ci
            isnan(grid[pt]) || continue
            
            odd_mask = ntuple(d -> ss[d] > 0 && isodd((pt[d]-1) ÷ ss[d]), N)
            nodd = count(odd_mask)
            nodd == 0 && continue
            
            bit_pos = MVector{N,Int}(undef)
            j = 0
            for d in 1:N
                if odd_mask[d]
                    bit_pos[d] = j
                    j += 1
                end
            end
            
            pvals = MVector{1 << N, Float64}(undef)
            pcoords = MVector{1 << N, CartesianIndex{N}}(undef)
            np = 0
            for b in 0:(1 << nodd)-1
                valid = true
                coords = MVector{N,Int}(undef)
                for d in 1:N
                    if odd_mask[d]
                        coords[d] = pt[d] + ss[d] * (2*((b >> bit_pos[d]) & 1) - 1)
                        if coords[d] < 1 || coords[d] > Ns[d]
                            valid = false
                            break
                        end
                    else
                        coords[d] = pt[d]
                    end
                end
                if valid
                    np += 1
                    pvals[np] = grid[coords...]
                    pcoords[np] = CartesianIndex(Tuple(coords))
                end
            end
            grid[pt] = F(pt, view(pvals, 1:np), view(pcoords, 1:np))
        end
    end
    grid
end
# index(n) = Iterators.product((1:n̂ for n̂ ∈ n)...)
# function ∃̇(♯::Grid, ϵ::∃{T}, k::Int, Ξ::Dict{∃, Tuple{Pretopology{T}, T}}) where {T<:Real}
#     # consider length(♯.n)-dim squares/pixels covering the area defined in ϵ such that:
#     # ♯.n is the number of squares in each dimension (1 square for undeclared dimensions)
#     # the corners of ϵ are centers of the corner squares
#     # all points in ϵ belong to at least 1 square, some points to multiple (edges or corners of squares)
#     # we bisect the space starting at the center, then all the corners of the full space, then each mid point between each point that exists
#     # each of these steps (k) is one after another, as the potential function ∃̇ is run given the coordinate and value of the points that made this center
#     # each step itself runs the points in parallel (@threads for)
#     # the points are all in the continuous space and map to potentially multiple squares (any that it is touching considering the squares as closed sets), if a latter theoretical point paints a square that already had a value, we just overwrite, as in, the iterator delivers the square index and value, no problem, its an update
#     # could we return an iterator that adds points as k advances (and within k the threads return results going into the cache Ξ) ?
#     # the first steps are technically also centers between corners, the corners as centers between the center, the center the center between nothing and everything (center=origin), so each step takes the center of what exists, runs those in parallel and delivers to the caller by asap (iterator)
#     #
#     if k == 0
#         # center
#         x = X(ϵ, ϵ.μ)
#         ϵ̂, ϵ̇, _ = ∃̇(x, ϵ) # owner, value, _
#         Ξ[x] = ϵ̂, ϵ̇
# # ... return # something for iterator
#     elseif k == 1
#         # all corners
#         n = filter(n -> n ≠ 1, ♯.n...)
    # n = findall(n -> 1 < n, ♯.n)


#         for i = 1:2^n
# # ...  find μ such that x = X(ϵ, μ) gives a corner and then ϵ̂, ϵ̇, _ = ∃̇(x, ϵ) ; Ξ[x] = ϵ̂, ϵ̇
#         end
# # ... return # something for iterator
#     end
#     ϵ̇ = ∃̇(♯, ϵ, k-1, Ξ)
#     # 1 < k: enumerate all centers of all points that exist (Ξ) such that
#     # no doubles (no need to run ∃̇(x, ϵ) if haskey(Ξ,x))
#     # run all these points in parallel using:
# # @threads for i = ...
# # ... onex, zerox = ... two existing points
#     onex∃, zero∃ = Ξ[onex], Ξ[zerox] # their values
#     ϵ̂, ϵ̇, _ = ∃̇(onex, onex∃, zerox, zero∃, x, ϵ) # ... new center value
# # end @threads for
# # ... return iterator
# end
# old:
# function ∃̇(♯::Grid, ϵ::∃{T}) where {T<:Real}
#     ○̂ = ○(T)
#     ϵ̂ = fill(○̂, ♯.n...)
#     μẑero = ϵ.μ .- ϵ.ρ
#     @threads for i = collect(index(♯.n))
#         μ = fill(○̂, length(ϵ.d))
#         for î = eachindex(ϵ.d)
#             μ[î] = isone(♯.n[î]) ? ϵ.μ[î] : μẑero[î] + 2 * ϵ.ρ[î] * T(i[î] - 1) / T(♯.n[î] - 1)
#         end
#         x = X(ϵ, μ) # x ∈ cl(ϵ)
#         ϵ̂[i...] = ∃̇(x, ϵ)
#     end
#     ϵ̂
# end

