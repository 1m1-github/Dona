struct god
    ẑero::∃
    ône::∃
    ∂t₀::Bool
    v::T
    ρ::T
    Ω::𝕋
    ⚷::UInt
    ♯::NTuple
    ∇::UInt
end
function god(; d, μ, ρ, ⚷=zero(UInt), Φ=○̂, ♯=(1,), ∇=typemax(UInt))
    # @assert zero(T) ∉ d
    # d̂ = SA[zero(T), d...]
    # N = length(d̂)
    N = length(d)
    # μ₀ = SA[t(), μ...]
    # ρ₀ = SA[zero(T), ρ...]
    ∂₀ = ntuple(_ -> (true, false), N)
    # ẑero = ∃(God, d̂, μ₀, ρ₀, ∂₀, Φ)
    ẑero = ∃(God, d, μ, ρ, ∂₀, Φ)
    μ₁ = @SVector ones(T, N)
    ∂₁ = ntuple(_ -> (false, true), N)
    zeros = @SVector zeros(T, N)
    # ône = ∃(God, d̂, μ₁, zeros, ∂₁, ○̂)
    ône = ∃(God, d, μ₁, zeros, ∂₁, ○̂)
    # ♯̂ = (1, ♯...)
    # god(ẑero, ône, true, zero(T), zero(T), 𝕋(), ⚷, ♯̂, ∇)
    god(ẑero, ône, true, zero(T), zero(T), 𝕋(), ⚷, ♯, ∇)
end
# isreal(ϵ::∃) = √(ϵ) === God
# function dh(⚷, g, n)
#     powermod(g, ⚷, n)
# end
# function ⚷⚷(⚷, dh)
#     powermod(dh, ⚷, DH_N)
# end
# function ⚷i(i, ⚷, ♯)
#     ntuple(length(♯)) do d
#         mod1(i[d] + ⚷, ♯[d])
#     end
# end
# function i⚷(i, ⚷, ♯)
#     ntuple(length(♯)) do d
#         î = mod(⚷, ♯[d])
#         mod1(i[d] + ♯[d] - î, ♯[d])
#     end
# end
function create(g::god, Φ, Ω=God)
    ϵ = g.ône - g.ẑero
    ϵ = ∃(ϵ, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, Φ)
    # ϵ = ∃(ϵ, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ℼ(Φ))
    ∃!(ϵ, Ω)
end
# const WHITE = (one(T), one(T), one(T), one(T))
# const BLACK = (zero(T), zero(T), zero(T), one(T))
# ∃̇(g::god) = ∃̇(g.ône - g.ẑero, g.♯, g.∇)
# # ϵ=g.ône - g.ẑero
# function ∃̇(ϵ::∃, ♯, ∇)
#     ϵ̂ = X(ϵ, ♯, ∇)
#     ϵ∃ = filter(ϵ -> ϵ !== God, vec(ϵ̂))
#     isempty(ϵ∃) && return fill(WHITE, ♯[2], ♯[3])
#     unique!(t, ϵ∃)
#     sort!(ϵ∃, by=t)
#     ϵt = map(t, ϵ∃)
#     t_to_tag = Dict(ϵt[i] => UInt32(i) for i in eachindex(ϵt))
#     Φi = zeros(UInt32, ♯[2], ♯[3], ♯[4])
#     for i in CartesianIndices(ϵ̂)
#         ϵ̂ᵢ = ϵ̂[i]
#         ϵ̂ᵢ === God && continue
#         Φi[i[2], i[3], i[4]] = t_to_tag[t(ϵ̂ᵢ)]
#     end
#     φ = ΦSet(ntuple(i -> ϵ∃[i].Φ, length(ϵ∃)))
#     rgba = render(φ, Φi, ♯)
#     ℼ̂(rgba)
# end
# ℼ̂(ϕ) = begin
#     pixel = fill(WHITE, size(ϕ, 2), size(ϕ, 3))
#     # i = collect(CartesianIndices(pixel))[1]
#     for i = CartesianIndices(pixel)
#         r = ϕ[1, Tuple(i)...]
#         g = ϕ[2, Tuple(i)...]
#         b = ϕ[3, Tuple(i)...]
#         a = ϕ[4, Tuple(i)...]
#         pixel[i] = r == g == b == a == ○ ? WHITE : (r, g, b, a)
#     end
#     pixel
# end
# # # ∇(t) = t*g.ône-(1-t)*g.ẑero
# # # ∇(0) = g.ẑero
# # # ∇(1) = g.ône
# # # t(ẑero), t̂
# # # speed = dt(ẑero)/dt̂, dx/dt(ẑero), dy/dt(ẑero)
# # # t = 1 - 1/(1+log(C)) = log(C)/(1+log(C))
# # # dt(ẑero) = speed[1]*dt̂
# # # dt̂=0.01
# # # step!(g, dt̂)
# # # wip
# # function step!(g::god, dt̂)
# #     dt = g.v[1] * dt̂
# #     # g.ẑero.μ[1] += dt
# #     # dt = Ο(g.ẑero.μ[1] + g.v[1])
# #     # Ο(0.40938)
# #     # t(1)
# #     N = length(g.ẑero.μ)
# #     μ = SVector(ntuple(N) do i
# #         3 < i && return g.ẑero.μ[i]
# #         i == 1 && return min(g.ẑero.μ[1] + dt, one(T))
# #         min(g.ẑero.μ[i] + g.v[i] * dt, one(T))
# #     end)
# #     ρ = SVector(ntuple(N) do i
# #         (i == 2 || i == 3) && return min(g.ẑero.ρ[i], μ[i], one(T) - μ[i])
# #         g.ẑero.ρ[i]
# #     end)
# #     g.ẑero = ∃(g.ẑero.ϵ̂, g.ẑero.d, μ, ρ, g.ẑero.∂, g.ẑero.Φ)
# # end
# # ρ(μ) = min(μ, 1 - μ)
# function step(g::god, dt̂=one(T))
#     if g.∂t₀
#         ṫ = t()
#         μ = SVector(ntuple(i -> i == 1 ? ṫ : g.ẑero.μ[i], length(g.ẑero.μ)))
#     else
#         δμ = g.ône.μ .- g.ẑero.μ
#         all(d -> iszero(d), δμ) && return
#         α = clamp(g.v * dt̂, zero(T), one(T))
#         μ = g.ẑero.μ .+ α .* δμ
#     end
#     g = move(g, μ)
#     g.ẑero !== ○̂ && ∃!(g.ẑero)
# end
# speed(g::god, v) = god(g.ẑero, g.ône, g.∂t₀, clamp(T(v), zero(T), one(T)), g.ρ, g.Ω, g.⚷, g.♯, g.∇)
# stop(g::god) = god(g.ẑero, g.ône, g.∂t₀, zero(T), g.ρ, g.Ω, g.⚷, g.♯, g.∇)
# stoptime(g::god) = god(g.ẑero, g.ône, g.∂t₀, SA[zero(T), g.v[2:end]...], g.ρ, g.Ω, g.⚷, g.♯, g.∇)
# scale!(g::god, ♯) = god(g.ẑero, g.ône, g.∂t₀, g.v, g.ρ, g.Ω, g.⚷, ♯, g.∇)
move(g::god, ẑeroμ) =
    god(
        ∃(g.ẑero.ϵ̂, g.ẑero.d, ẑeroμ, g.ẑero.ρ, g.ẑero.∂, g.ẑero.Φ),
        g.ône, g.∂t₀, g.v, g.ρ, g.Ω, g.⚷, g.♯, g.∇
    )
# focus(g::god, ôneμ) =
#     god(
#         g.ẑero,
#         ∃(g.ône.ϵ̂, g.ône.d, ôneμ, g.ône.ρ, g.ône.∂, g.ône.Φ),
#         g.∂t₀, g.v, g.ρ, g.Ω, g.⚷, g.♯, g.∇
#     )
# home(g::god) = god(g.ẑero, g.ône, true, zero(T), g.ρ, g.Ω, g.⚷, g.♯, g.∇)

# struct ΦSet{Fs}
#     fs::Fs  # Tuple of Φ functions
# end
# # eval_Φ(φ,1,0.5,0.5,0.5,0.4)
# # @generated function eval_Φ(φ::ΦSet{Fs}, idx, t, x, y, z) where Fs
# @generated function eval_Φ(φ::ΦSet{Fs}, idx, x) where Fs
#     N = length(Fs.parameters)
#     branches = []
#     for i in 1:N
#         push!(branches, quote
#             if idx == $i
#                 # return φ.fs[$i](t, x, y, z)
#                 return φ.fs[$i](x)
#             end
#         end)
#     end
#     quote
#         $(branches...)
#         return (zero(T), zero(T), zero(T), zero(T))
#     end
# end
# @kernel function κ!(rgba, φ::ΦSet, Φi, ♯)
#     xi, yi = @index(Global, NTuple)
#     # xi, yi = 2,2
#     _, W, H, D = ♯
#     x = isone(W) ? ○ : (T(xi) - 1) / T(W - 1)
#     y = isone(H) ? ○ : (T(yi) - 1) / T(H - 1)
#     r, g, b, a = zero(T), zero(T), zero(T), zero(T)
#     # zi = collect(1:D)[2]
#     for zi = 1:D
#         one(T) ≤ a && break
#         z = isone(D) ? ○ : T(zi - 1) / T(D - 1)
#         idx = Φi[xi, yi, zi]
#         iszero(idx) && continue
#         # ṙ, ġ, ḃ, ȧ = eval_Φ(φ, idx, ○, x, y, z)
#         ṙ, ġ, ḃ, ȧ = eval_Φ(φ, idx, (○, x, y, z))
#         iszero(ȧ) && continue
#         rem = one(T) - a
#         r += ṙ * ȧ * rem
#         g += ġ * ȧ * rem
#         b += ḃ * ȧ * rem
#         a += ȧ * rem
#     end
#     rgba[1, xi, yi] = r
#     rgba[2, xi, yi] = g
#     rgba[3, xi, yi] = b
#     rgba[4, xi, yi] = a
# end
# # ♯=g.♯
# # φ, Φi, ♯
# function render(φ::ΦSet, Φi, ♯)
#     rgba = KernelAbstractions.zeros(GPU_BACKEND, T, 4, ♯[2], ♯[3])
#     i̇ = KernelAbstractions.allocate(GPU_BACKEND, UInt32, size(Φi))
#     copyto!(i̇, Φi)
#     Base.invokelatest() do
#         κ!(GPU_BACKEND, GPU_BACKEND_WORKGROUPSIZE)(
#             rgba, φ, i̇, ♯,
#             ndrange=(♯[2], ♯[3])
#         )
#     end
#     KernelAbstractions.synchronize(GPU_BACKEND)
#     Array(rgba)
# end
# # X(i, ♯::NTuple) = SVector{length(♯)}([isone(♯[î]) ? ○ : T(i[î] - 1) / T(♯[î] - 1) for î = eachindex(♯)])
# X(i, ♯) = ntuple(î -> begin
#         isone(♯[î]) && return ○
#         # î == 4 && return # todo depth log spacing
#         T(i[î] - 1) / T(♯[î] - 1)
#         # T(i[î]) / T(♯[î] + 1)
#     end, length(♯))
# # ♯
# # iμ(i, ♯) # index to center
# # μi(μ, ♯) # center to index
# # function owners(ẑerod, ẑeroμ, ∇, ♯)
# #     N = length(ẑerod)
# #     ẑeroρ = SVector(ntuple(_ -> zero(T), N))
# #     ẑero∂ = ntuple(_ -> (true,true), N)
# #     μ = ∃(God, ẑerod, ẑeroμ, ẑeroρ, ẑero∂, ○̂)
# #     ϵ = X(μ, ∇)
# #     ôneμ = ẑeroμ .+ 2ϵ.ρ
# #     ônei = μi(ôneμ, ♯)
# #     ôneCartesian = ?(ônei, ♯)
# #     ϵ̂ = Dict{Int, ∃}()
# #     Threads.@threads for i = 1:N
# #         ẑeroCartesianOfSubHyperBalli = ?(ôneCartesian)
# #         ẑeroμOfSubHyperBalli = ?(ẑeroCartesianOfSubHyperBalli) # maybe via ẑeroi if better
# #         ♯OfSubHyperBalli = ?(♯) # smaller
# #         subHyperBalli = owners(ẑerod, ẑeroμOfSubHyperBalli, ∇, ♯OfSubHyperBalli)
# #         ϵ̂[globali(i, ôneCartesian)] = subHyperBalli
# #     end
# #     unique(collect(values(ϵ̂)))
# # end

# # function i2μ(i::Int, N::Int)
# #     isone(N) && return ○
# #     one(T) - log(T(N - i + 1)) / log(T(N)) # log(T(N)) const
# # end
# # function μ2i(μ::T, N::Int)
# #     isone(N) && return 1
# #     clamp(round(Int, T(N) + one(T) - T(N)^(one(T) - μ)), 1, N)
# # end
# # i2μ(i::NTuple{N}, ♯::NTuple{N}) where N = ntuple(d -> i2μ(i[d], ♯[d]), N)
# # μ2i(μ, ♯::NTuple{N}) where N = ntuple(d -> μ2i(T(μ[d]), ♯[d]), N)
# # i2μ((1,2,3,4,5,6,7,8,9,10), (10,10,10,10,10,10,10,10,10,10))
# # function make_slab(region, box, d, N)
# #     ntuple(N) do d2
# #         if d2 < d
# #             first(box[d2]):last(box[d2])
# #         elseif d2 == d
# #             (last(box[d])+1):last(region[d])
# #         else
# #             first(region[d2]):last(region[d2])
# #         end
# #     end
# # end
# # function owners(ϵ_root, region, ♯, ∇)
# #     N = length(♯)
# #     corner = ntuple(d -> first(region[d]), N)
# #     x = iμ(corner, ♯)
# #     xϵ = ∃(God, ϵ_root.d, SVector(x), zero(ϵ_root.ρ), ϵ_root.∂, ϵ_root.Φ)
# #     owner, _ = X(xϵ, ∇)
    
# #     result = Vector{Tuple{∀, NTuple{N,UnitRange{Int}}}}()
    
# #     if owner === God
# #         # find any entity in subtree intersecting region
# #         node = β(xϵ, God)  # deepest ancestor
# #         for ϵ in God.ϵ̃[node]
# #             ϵ_box = grid_box(ℼ(ϵ), ϵ_root, ♯)
# #             clipped = clip(ϵ_box, region)
# #             isempty_region(clipped) && continue
# #             # recurse starting at this entity's corner within region
# #             append!(result, owners(ϵ_root, clipped, ♯, ∇))
# #             # slabs: remainder of region minus clipped
# #             append_slabs!(result, ϵ_root, region, clipped, ♯, ∇)
# #             return result
# #         end
# #         # nothing intersects — entire region is God
# #         return result
# #     end
    
# #     box = clip(grid_box(ℼ(owner), ϵ_root, ♯), region)
# #     push!(result, (owner, box))
    
# #     # N slabs in parallel
# #     tasks = Vector{Task}()
# #     for d in 1:N
# #         slab = make_slab(region, box, d, N)
# #         isempty_region(slab) && continue
# #         t = Threads.@spawn owners(ϵ_root, slab, ♯, ∇)
# #         push!(tasks, t)
# #     end
# #     for t in tasks
# #         append!(result, fetch(t))
# #     end
    
# #     result
# # end
# # i = collect(CartesianIndices(Ξ))[2678]
# # Ξ[i].Φ(1)
# # ∇=typemax(UInt32)
# function X(ϵ::∃, ♯, ∇)
#     Ξ = Array{∀}(undef, ♯...)
#     ρ₀ = zero(ϵ.ρ)
#     # for i in CartesianIndices(Ξ)
#     # î = collect(1:length(Ξ))[1]
#     @time Threads.@threads for î in 1:length(Ξ)
#         # @time begin 
#         i = CartesianIndices(Ξ)[î]
#         x = X(i, ♯)
#         # xϵ = ∃(God, ϵ.d, x, ρ₀, ϵ.∂, ϵ.Φ)
#         xϵ = ∃(God, ϵ.d, SVector(x), ρ₀, ϵ.∂, ϵ.Φ)
#         Ξ[i], _ = X(xϵ, ∇)
#         # end;
#     end
#     Ξ
# end
# # t0=time()
# # @time begin i = CartesianIndices(Ξ)[î]
# #         x = X(i, ♯)
# #         # xϵ = ∃(God, ϵ.d, x, ρ₀, ϵ.∂, ϵ.Φ)
# #         xϵ = ∃(God, ϵ.d, SVector(x), ρ₀, ϵ.∂, ϵ.Φ)
# #         Ξ[i], _ = X(xϵ, ∇) end;
# # time()-t0
# # 0.09*prod(size(Ξ))