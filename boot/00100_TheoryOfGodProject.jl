# observe.jl — god observes Ω
#
# observer = ZERO = g.ẑero.μ         (watches)
# light    = ○    = origin = center   (illuminates)
# focus    = ONE  = g.ône.μ           (direction)
# screen   = 2D disk at ○, orthogonal to view direction ○ → ONE
# radius   = g.ρ (field of view on screen)
# rays     = from ○ outward through screen pixels to boundary
# GL8      = per pixel, integrate Φ along ray, n=8 always
#
# Two-pass rendering:
#   CPU: walk pretopology to find owner ϵ for each sample point
#   GPU: evaluate Φ at each point using owner index, accumulate per pixel

using LinearAlgebra: normalize, norm, dot
using KernelAbstractions
using PNGFiles

using Metal
const GPU_BACKEND = MetalBackend()
# using CUDA ; const GPU_BACKEND = CUDABackend()
# const GPU_BACKEND_WORKGROUPSIZE = 2^2^3

# ── GL8 on [0,1]: exact for degree ≤ 15, exponential for C^∞ ────────────────

const GL_NODES = SA[
    T(0.019855071751231884),  T(0.101666761293186631),
    T(0.237233795041835507),  T(0.408282678752175098),
    T(0.591717321247824902),  T(0.762766204958164493),
    T(0.898333238706813369),  T(0.980144928248768116)]
const GL_WEIGHTS = SA[
    T(0.050614268145188129),  T(0.111190517226687235),
    T(0.156853322938943644),  T(0.181341891689180991),
    T(0.181341891689180991),  T(0.156853322938943644),
    T(0.111190517226687235),  T(0.050614268145188129)]

# ── ΦSet: tuple of Φ functions, indexable for GPU dispatch ───────────────────

struct ΦSet{Fs}
    fs::Fs  # Tuple of Φ functions
end
ΦSet(fs...) = ΦSet(fs)
Base.getindex(Φs::ΦSet, i::Int) = Φs.fs[i]
Base.length(Φs::ΦSet) = length(Φs.fs)

# ── gpu_safe: test whether Φ can run on backend ─────────────────────────────

function gpu_safe(Φ_func, N::Int, backend=GPU_BACKEND)
    try
        @kernel function _test(out, @Const(f))
            I = @index(Global)
            x = SVector(ntuple(_ -> T(0.5), N))
            out[I] = f(x...)
        end
        out = KernelAbstractions.zeros(backend, T, 1)
        _test(backend, 64)(out, Φ_func, ndrange=1)
        KernelAbstractions.synchronize(backend)
        true
    catch
        false
    end
end

# ── Orthonormal basis: 2 vectors ⊥ v̂ in ℝᴺ ──────────────────────────────────

function screen_basis(v̂::SVector{N,T}) where {N}
    axes = sortperm(SVector(ntuple(i -> abs(v̂[i]), N)))
    e₁ = SVector(ntuple(i -> i == axes[1] ? one(T) : zero(T), N))
    û = normalize(e₁ - dot(e₁, v̂) * v̂)
    e₂ = SVector(ntuple(i -> i == axes[2] ? one(T) : zero(T), N))
    ŵ = normalize(e₂ - dot(e₂, v̂) * v̂ - dot(e₂, û) * û)
    û, ŵ
end

# ── CPU pass: compute sample points + find owners ────────────────────────────

function cpu_ownership(g::god, W::Int, H::Int, ○_μ, v̂, r, û, ŵ)
    N_dims = length(g.ẑero.d)
    # points[py, px, j] = sample point SVector
    # owners[py, px, j] = index into ΦSet (0 = boundary/God = ○)
    points = Array{SVector{N_dims,T}}(undef, H, W, 8)
    owners = zeros(Int, H, W, 8)

    # collect all unique Φ owners → build index
    owner_map = Dict{UInt,Int}()  # hash(ϵ) → index
    owner_list = ∃[]              # index → ϵ

    Threads.@threads for idx in 1:(W * H)
        py, px = divrem(idx - 1, W) .+ (1, 1)
        ξ₁ = T(2px - 1) / T(W) - one(T)
        ξ₂ = T(2py - 1) / T(H) - one(T)
        d̂ = normalize(v̂ .+ g.ρ .* (ξ₁ .* û .+ ξ₂ .* ŵ))

        for j in 1:8
            p = ○_μ .+ (GL_NODES[j] * r) .* d̂
            points[py, px, j] = SVector(ntuple(i -> i ≤ length(p) ? p[i] : ○, N_dims))

            # walk pretopology to find owner
            x = ∃(g.ẑero.ϵ̂, g.ẑero.d,
                  points[py, px, j],
                  SVector(ntuple(_ -> zero(T), N_dims)),
                  ntuple(_ -> (true, true), N_dims),
                  ○̂)
            ϵ, found = X(x, g.∇)
            if !found || ϵ isa 𝕋
                owners[py, px, j] = 0
            else
                h = hash(ϵ)
                lock(g.Ω.L)
                if !haskey(owner_map, h)
                    push!(owner_list, ϵ)
                    owner_map[h] = length(owner_list)
                end
                owners[py, px, j] = owner_map[h]
                unlock(g.Ω.L)
            end
        end
    end
    points, owners, owner_list
end

# ── GPU kernel: evaluate Φ and accumulate per pixel ──────────────────────────

@kernel function κ_observe!(img, @Const(points), @Const(owners),
                            @Const(gl_w), @Const(r), Φs::ΦSet)
    idx = @index(Global)
    H, W = size(img)
    py, px = divrem(idx - 1, W) .+ (1, 1)

    val = zero(T)
    for j in 1:8
        ow = owners[py, px, j]
        if ow == 0
            val += gl_w[j] * ○
        else
            p = points[py, px, j]
            val += gl_w[j] * Φs[ow](p...)
        end
    end
    img[py, px] = val * r
end

# ── Observe: two-pass render ─────────────────────────────────────────────────

function observe(g::god, W::Int, H::Int; backend=GPU_BACKEND)
    ○_μ = (g.ẑero.μ .+ g.ône.μ) ./ 2
    v = g.ône.μ .- ○_μ
    r = norm(v)
    r < eps(T) && return fill(○, H, W)
    v̂ = v ./ r
    û, ŵ = screen_basis(v̂)

    # pass 1: CPU — find owners
    points, owners, owner_list = cpu_ownership(g, W, H, ○_μ, v̂, r, û, ŵ)

    # build ΦSet from discovered owners
    Φs = ΦSet(Tuple(ϵ.Φ for ϵ in owner_list))

    # pass 2: GPU — evaluate and accumulate
    img_gpu = KernelAbstractions.zeros(backend, T, H, W)
    pts_gpu = adapt(backend, points)
    own_gpu = adapt(backend, owners)
    glw_gpu = adapt(backend, GL_WEIGHTS)

    κ_observe!(backend, 256)(img_gpu, pts_gpu, own_gpu, glw_gpu, T(r), Φs,
                              ndrange=W*H)
    KernelAbstractions.synchronize(backend)
    Array(img_gpu)
end

# ── CPU fallback (no GPU) ───────────────────────────────────────────────────

function observe_cpu(g::god, W::Int, H::Int)
    ○_μ = (g.ẑero.μ .+ g.ône.μ) ./ 2
    v = g.ône.μ .- ○_μ
    r = norm(v)
    r < eps(T) && return fill(○, H, W)
    v̂ = v ./ r
    û, ŵ = screen_basis(v̂)
    N_dims = length(g.ẑero.d)
    img = fill(○, H, W)

    Threads.@threads for idx in 1:(W * H)
        py, px = divrem(idx - 1, W) .+ (1, 1)
        ξ₁ = T(2px - 1) / T(W) - one(T)
        ξ₂ = T(2py - 1) / T(H) - one(T)
        d̂ = normalize(v̂ .+ g.ρ .* (ξ₁ .* û .+ ξ₂ .* ŵ))

        val = zero(T)
        for j in 1:8
            p = ○_μ .+ (GL_NODES[j] * r) .* d̂
            x = ∃(g.ẑero.ϵ̂, g.ẑero.d,
                  SVector(ntuple(i -> i ≤ length(p) ? p[i] : ○, N_dims)),
                  SVector(ntuple(_ -> zero(T), N_dims)),
                  ntuple(_ -> (true, true), N_dims),
                  ○̂)
            val += GL_WEIGHTS[j] * Φ(x, g.Ω, g.∇)
        end
        img[py, px] = val * r
    end
    img
end

# ── PPM ──────────────────────────────────────────────────────────────────────

# function save_ppm(img::Matrix, path::String)
#     H, W = size(img)
#     open(path, "w") do io
#         println(io, "P3\n$W $H\n255")
#         for py in 1:H
#             for px in 1:W
#                 c = round(Int, clamp(img[py, px], zero(eltype(img)), one(eltype(img))) * 255)
#                 print(io, c, ' ', c, ' ', c, ' ')
#             end
#             println(io)
#         end
#     end
# end

# function observe!(g::god, W::Int=512, H::Int=512; kwargs...)
# function observe!(g::god, path::String, W::Int=512, H::Int=512; kwargs...)
    # img = observe(g, W, H; kwargs...)
    # save_ppm(img, path)
    # img
# end
# observe(g::god) = observe!(g::god, g.♯[1], g.♯[2]; backend=GPU_BACKEND)
