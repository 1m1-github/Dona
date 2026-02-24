import Pkg
Pkg.activate("gpu")

"""
TheoryOfGod

I = [ZERO < ○ < ONE] denotes a unit 1-dim space of information with origin ○ (no information) in its center including the corners ZERO and ONE.
∀ = I^I an ∞-dim metric and smooth vector space.
We have a Pretopology 𝕋 on ∀ such that ϵᵢ ∈ 𝕋:
* ϵᵢ ⊆ ∀
* ϵ₂ ∈ ϵ₁.ϵ̃ => ϵ₂|ϵ₁ ⊆ ϵ₁ <=> ϵ₂ ⫉ ϵ₁ ⩓ ϵ₂ ∈ ϵ₃.ϵ̃ => ϵ₁ = ϵ₃
* ϵ₁ ≠ ϵ₂ => ϵ₁ ∩ ϵ₂ = ∅
* x ∈ ϵᵢ ⊊ ∀: x.ρ = 0 => ϵᵢ.Φ(x) ∈ I is arbitrary, computable and smooth fuzzy existence potential towards ONE=true xor ZERO=false.

ϵ ⊊ ∀ defines its existence inside a subset of ∀ using an origin (μ), a radius (ρ) and a closed vs. open in each direction (∂) vector. These vectors are finite and all other dimensional coordinates of ϵ follow from linear interpolation.
If we use a horizontal axis for dimension and a vertical axis for coordinate in the dimension, for any ϵ, the chart looks like a stepwise linear function with finite non-zero radius intervals (active dimensions) and zero interval points within the interpolated regions.
Each child ϵ is a subset of its parent in the active dimensions declared by the parent.

god ⊊ God = ∀ = I^I = I^(.) = [ZERO < ○ < ONE]^(.)
god observes or creates, God iterates.
"""
# module tog

# export ∃, ∃̇, ∃!

using KernelAbstractions
using Metal ; const GPU_BACKEND = MetalBackend()
# using CUDA ; const GPU_BACKEND = CUDABackend()
const GPU_BACKEND_WORKGROUPSIZE = 2^2^3

const T = Float32

include("00101_TheoryOfGod∃.jl")
const God = 𝕋()
# const name = Dict{∃, String}()
# include("00103_TheoryOfGodgod.jl")

# d = SA[zero(T), T(one(T)/MathConstants.φ), T(one(T)/MathConstants.φ^2), T(one(T)/MathConstants.φ^3)]
# μ = SA[t(), ○, ○, ○]
# ρ = SA[zero(T), zero(T), zero(T), zero(T)]
# ♯ = (1, 2560, 1600, 2^3)
# # ♯ = (1, 200, 100, 2^3)
# g = god(d=d, μ=μ, ρ=ρ, ♯=♯)

d = SA[zero(T), ○, one(T)]
∂true = ((true, true), (true, true), (true, true))

μϵ₁ = SA[○, ○, ○]
ρϵ₁ = SA[T(0.1), T(0.1), T(0.1)]
# ϵ.Φ(x.μ)
# x=
# x.μ[1]
# sierpinski(x.μ)
function sierpinski(x...)
    # @show typeof(x), typeof(x[1]), x[1], x[1][1]
    depth = 8
    ix = unsafe_trunc(UInt32, x[1][1] * (1 << depth))
    iy = unsafe_trunc(UInt32, x[1][2] * (1 << depth))
    iz = unsafe_trunc(UInt32, x[1][3] * (1 << depth))
    # iszero(ix & iy) ? one(T) : zero(T)
    iszero(ix & iy & iz) ? zero(T) : one(T)
end
Φϵ₁ = sierpinski
# Φϵ₁(x...) = one(T)
ϵ₁ = ∃(God, d, μϵ₁, ρϵ₁, ∂true, Φϵ₁)
∃!(ϵ₁)

μϵ₂ = SA[T(0.75), T(0.75), T(0.75)]
ρϵ₂ = SA[T(0.1), T(0.1), T(0.1)]
Φϵ₂(x...) = T(0.75)
ϵ₂ = ∃(God, d, μϵ₂, ρϵ₂, ∂true, Φϵ₂)
∃!(ϵ₂)

ϵ₁ ⫉ God
ϵ₂ ⫉ God
ϵ₁ ⫉ ϵ₂
ϵ₂ ⫉ ϵ₁
∩(ϵ₁, God, God)
∩(ϵ₂, God, God)
ϵ₁ ∩ ϵ₂
ϵ₂ ∩ ϵ₁

♯ = (1000, 1000)
p♯ = fill(one(T), ♯)

z = SA[zero(T), zero(T), zero(T)]
o = SA[one(T), one(T), one(T)]
ẑeroμ = SA[T(0.1), zero(T), zero(T)]
ẑero = ∃(God, d, ẑeroμ, z, ∂true, ○̂)
ôneμ = SA[○, ○, one(T)]
ône = ∃(God, d, ôneμ, z, ∂true, ○̂)
view = ône - ẑero

God.ϵ̃
ϵ₁ ∈ keys(God.ϵ̃)
ϵ₂ ∈ keys(God.ϵ̃)
God ∈ keys(God.ϵ̃)

ϵ = β(view, God)
ϵ === God
ϵ === ϵ₁
ϵ === ϵ₂

μ(::𝕋) = SA[○,○,○]
μ(ϵ::∃) = ϵ.μ
ρ(Ω::𝕋) = μ(Ω)
ρ(ϵ::∃) = ϵ.ρ

using DataStructures

# i = collect(CartesianIndices(♯))[1]
i=CartesianIndex(31,31)
Threads.@threads for i = CartesianIndices(♯)
    # p♯[i] = ○
    p = (((Tuple(i) .- one(T)) ./ (♯ .- one(T)))..., ẑero.μ[end])
    v = ône.μ .- p
    obs = SortedDict()
    # ϵ̃ = God.ϵ̃[ϵ][2]
    for ϵ̃ = God.ϵ̃[ϵ]
        t_lo = ((μ(ϵ̃) .- ρ(ϵ̃)) .- p) ./ v
        t_hi = ((μ(ϵ̃) .+ ρ(ϵ̃)) .- p) ./ v
        t_enter = min(t_lo, t_hi)
        t_exit = max(t_lo, t_hi)
        t_enter_max = maximum(t_enter)
        t_exit_min = minimum(t_exit)
        hit = t_enter_max < t_exit_min && zero(T) < t_exit_min
        hit || continue
        obs[t_enter_max] = (t_exit_min, ϵ̃)
    end
    isempty(obs) && continue
    t_enter_max, (t_exit_min, ϵ̂) = first(obs)
    t_mid = (t_enter_max + t_exit_min) / 2

    x = p .+ t_mid * v
    xϵ = ∃(God, d, x, z, ∂true, ○̂)
    # @show i
    # p♯[i] = Φ(xϵ, ϵ, typemax(UInt)) * (t_exit_min - t_enter_max)
    ϕ = Φ(xϵ, ϵ̂, typemax(UInt))
    # p♯[i] = ϕ * (t_exit_min - t_enter_max)
    p♯[i] = ϕ
end
p♯

minifb_buffer = reshape(p♯, prod(♯))
# minifb_buffer = unsafe_trunc.(UInt32,minifb_buffer .* (2^8-1))
minifb_buffer = ifelse.(minifb_buffer .> 0, 0x00000000, 0xFFFFFFFF)
# all(iszero,minifb_buffer)
using MiniFB
window = mfb_open_ex("tog", ♯[1], ♯[2], MiniFB.WF_RESIZABLE)
# minifb_buffer = zeros(UInt32, prod(♯))
MINIFBTASK = @async while true
    yield()
    sleep(2)
    state = mfb_update(window, minifb_buffer)
    state != MiniFB.STATE_OK && break
end

# using Images, FileIO
# function val_to_u32(v)
#     c = round(UInt32, clamp(v, 0.0, 1.0) * 255)
#     (c << 16) | (c << 8) | c
# end
# function save_png(buffer, width, height, path)
#     img = Matrix{RGB{N0f8}}(undef, height, width)
#     for i in eachindex(buffer)
#         p = buffer[i]
#         r = N0f8(((p >> 16) & 0xFF) / 255)
#         g = N0f8(((p >> 8) & 0xFF) / 255)
#         b = N0f8((p & 0xFF) / 255)
#         y = (i - 1) ÷ width + 1
#         x = (i - 1) % width + 1
#         img[y, x] = RGB(r, g, b)
#     end
#     save(path, img)
# end
# save_png(val_to_u32.(p♯), ♯..., "output.png")

x=1

# using REPL
# function game_loop_raw()
#     term = REPL.Terminals.TTYTerminal("", stdin, stdout, stderr)
#     REPL.Terminals.raw!(term, true)
#     try
#         while true
#             yield()
#             if bytesavailable(stdin) > 0
#                 c = read(stdin, String)
#                 c == "q" && break
#                 println("Key: $c ($(Int(c)))")
#                 key(c)
#             end
#         end
#     finally
#         REPL.Terminals.raw!(term, false)
#     end
# end
# const KEYBOARDTASK = @async game_loop_raw()
# function key(k)
#     k == "w" && return println("w")
#     k == "s" && return println("s")
#     k == "a" && return println("a")
#     k == "d" && return println("d")
#     k == "\e[A" && return println("\e[A")
#     k == "\e[B" && return println("\e[B")
#     k == "\e[C" && return println("\e[C")
#     k == "\e[D" && return println("\e[D")
# end

# include("00103_TheoryOfGodTypst.jl")

# include("00090_BroadcastBrowser2Module.jl")
# import Main.BroadcastBrowserModule: BroadcastBrowser, start
# include("00105_TheoryOfGodgodBrowser.jl")
# const BROWSERTASK = Threads.@spawn start(b -> godBrowser(b))
# g=collect(values(godBROWSER[]))[1].g

# Φ(x...) = x

# dimx, dimy, dimz = T(0.1),T(0.2),T(0.3)
# x, y, z = T(0.1),T(0.1),T(0.1)
# g = god(d=SA[dimx, dimy, dimz], μ=SA[x, y, z], ρ=SA[T(0.05), T(0.05), T(0.05)], ♯=(Int(3), Int(3), Int(3)))

# d = SA[T(0.1),T(0.2),T(0.3)]
# μ = SA[T(0.1),T(0.1),T(0.1)]
# ρ = SA[T(0.05),T(0.05),T(0.05)]
# ♯=(3,3,3)
# Φ(x...) = x
# g=god(d=d, μ=μ,ρ=ρ,♯=♯,Φ=Φ)
# g.ẑero
# g.ône
# ϵ = g.ône-g.ẑero
# ϵ=∃(God, SA[T(0.1)], SA[T(0.1)], SA[T(0.1)], ((true,true),), _->one(T))
# ϵ=∃(God, SA[T(0.1)], SA[T(0.1)], SA[T(0.1)], ((true,true),), _->rand(T))
# ϵ=∃(God, SA[T(0.1)], SA[T(0.1)], SA[T(0.1)], ((true,true),), _->begin
#     f=open("w.jl");close(f)
# end)

# create(g, Φ)
# create(g, Φ2)
# God.Ο[God]
# collect(keys(God.ϵ̃))
# ϵ=God.ϵ̃[God][1]
# t()
# t(ϵ̃)
# Before launching the kernel, from the thread that fails:
# @show typeof(ϵ.Φ)
# @show fieldnames(typeof(ϵ.Φ))
# @show fieldtypes(typeof(ϵ.Φ))
# isconcretetype(typeof(ϵ.Φ))
# Look for Any, abstract types, or types that contain pointers/heap objects
# ϕ = ∃̇(g)
# all(==(ntuple(_->zero(T),4)),ϕ)
# map(sum,ϕ)
# all(==(ntuple(_->one(T),4)),ϕ)
# step(g)
# function sierpinski3d(x)
#     mask = UInt32(0x007FFFFF)
#     ix = reinterpret(UInt32, x[2]) & mask
#     iy = reinterpret(UInt32, x[3]) & mask
#     iz = reinterpret(UInt32, x[4]) & mask
#     (ix ⊻ iy ⊻ iz) == zero(UInt32) ? WHITE : BLACK
# end
# function sierpinski3d(x)
#     mask = UInt32(0x007FFFFF)
#     ix = reinterpret(UInt32, x[2]) & mask
#     iy = reinterpret(UInt32, x[3]) & mask
#     iz = reinterpret(UInt32, x[4]) & mask
#     if (ix ⊻ iy ⊻ iz) == zero(UInt32)
#         return (x[2], x[3], x[4], one(T))  # fractal structure: colored by position
#     else
#         return (zero(T), zero(T), zero(T), zero(T))  # empty: transparent
#     end
# end
# x=(0.1,0.3)
# function sierpinski3d(x)
#     # Classic sierpinski tetrahedron via iterative address checking
#     # Map to [0,1]³ local coordinates
#     # px, py, pz = x.μ[1], x.μ[2], x.μ[3]
#     px, py, pz = x[1], x[2], x[3]
    
#     # Iterate: at each level, check which octant and whether it's filled
#     for _ in 1:8  # 8 levels of detail
#         px *= T(2)
#         py *= T(2)
#         pz *= T(2)
        
#         ix = px ≥ one(T)
#         iy = py ≥ one(T)
#         iz = pz ≥ one(T)
        
#         # Sierpinski tetrahedron: 4 of 8 octants are filled
#         # Filled: (0,0,0), (1,1,0), (1,0,1), (0,1,1)
#         count = Int(ix) + Int(iy) + Int(iz)
#         if count == 1 || count == 3
#             # Empty octant
#             return zero(T)
#         end
        
#         # Recurse into filled octant
#         ix && (px -= one(T))
#         iy && (py -= one(T))
#         iz && (pz -= one(T))
#     end
    
#     # Survived all levels: part of the fractal
#     # Color by position
#     # return (x.μ[1], x.μ[2], x.μ[3])
#     # return mfb_rgb(round(Int, x.μ[1]*255), round(Int, x.μ[2]*255), round(Int, x.μ[3]*255))
#     return one(T)
# end
# d1 = SA[zero(T), T(0.1), T(0.2), T(0.3)]
# μ1 = SA[○, ○, ○, ○]
# ρ1 = SA[T(0.1), T(0.1), T(0.1), T(0.1)]
# ∂1 = ntuple(_ -> (true, true), length(d1))
# ϵ1 = ∃(God, d1, μ1, ρ1, ∂1, sierpinski3d)
# ∃!(ϵ1, God)
# ♯ = (1,3,3,3)
# ∇ = 10
# ∃̇(ϵ1, ♯, ∇)
# ϵ=ϵ1
# create(g, sierpinski3d)
# God.Ο[God]

# function sierpinski_smooth(x)
#     px = T(2) * (x[2] - T(0.5))
#     py = T(2) * (x[3] - T(0.5))
#     pz = T(2) * (x[4] - T(0.5))
    
#     (px < zero(T) || px > one(T)) && return (zero(T), zero(T), zero(T), zero(T))
#     (py < zero(T) || py > one(T)) && return (zero(T), zero(T), zero(T), zero(T))
#     (pz < zero(T) || pz > one(T)) && return (zero(T), zero(T), zero(T), zero(T))
    
#     alpha = one(T)
    
#     for _ in 1:12
#         px *= T(2)
#         py *= T(2)
#         pz *= T(2)
        
#         ix = px ≥ one(T) ? 1 : 0
#         iy = py ≥ one(T) ? 1 : 0
#         iz = pz ≥ one(T) ? 1 : 0
        
#         s = ix + iy + iz
        
#         if s == 1 || s == 3
#             # Distance from boundary of this cell: how close to being "in"
#             # Fractional position within cell
#             fx = px - T(ix)
#             fy = py - T(iy)
#             fz = pz - T(iz)
#             # Distance to nearest filled octant center
#             d = min(fx, one(T)-fx, fy, one(T)-fy, fz, one(T)-fz)
#             # Smooth falloff: closer to boundary = more alpha
#             alpha *= exp(-T(4) * d)
#         end
        
#         ix == 1 && (px -= one(T))
#         iy == 1 && (py -= one(T))
#         iz == 1 && (pz -= one(T))
#     end
    
#     (zero(T), zero(T), zero(T), alpha)
# end
# create(g, sierpinski_smooth)
# function menger(x)
#     px = T(2) * (x[2] - T(0.5))
#     py = T(2) * (x[3] - T(0.5))
#     pz = T(2) * (x[4] - T(0.5))
    
#     (px < zero(T) || px > one(T)) && return (zero(T), zero(T), zero(T), zero(T))
#     (py < zero(T) || py > one(T)) && return (zero(T), zero(T), zero(T), zero(T))
#     (pz < zero(T) || pz > one(T)) && return (zero(T), zero(T), zero(T), zero(T))
    
#     alpha = one(T)
    
#     for _ in 1:6
#         px *= T(3); py *= T(3); pz *= T(3)
        
#         # Which third: 0, 1, or 2 (using T arithmetic, no Int)
#         ix = px ≥ T(2) ? T(2) : (px ≥ one(T) ? one(T) : zero(T))
#         iy = py ≥ T(2) ? T(2) : (py ≥ one(T) ? one(T) : zero(T))
#         iz = pz ≥ T(2) ? T(2) : (pz ≥ one(T) ? one(T) : zero(T))
        
#         # Center = 1. Count how many coords are in center third
#         cx = (ix == one(T)) ? one(T) : zero(T)
#         cy = (iy == one(T)) ? one(T) : zero(T)
#         cz = (iz == one(T)) ? one(T) : zero(T)
#         c = cx + cy + cz
        
#         if c ≥ T(2)
#             fx = px - ix; fy = py - iy; fz = pz - iz
#             d = min(fx, one(T)-fx, fy, one(T)-fy, fz, one(T)-fz)
#             alpha *= exp(-T(6) * d)
#         end
        
#         px -= ix; py -= iy; pz -= iz
#     end
    
#     shade = alpha
#     (shade * T(0.9), shade * T(0.7), shade * T(0.4), alpha)
# end
# create(g, menger)
# function menger(x)
#     px = T(2) * (x[2] - T(0.5))
#     py = T(2) * (x[3] - T(0.5))
#     pz = T(2) * (x[4] - T(0.5))
    
#     (px < zero(T) || px > one(T)) && return (zero(T), zero(T), zero(T), zero(T))
#     (py < zero(T) || py > one(T)) && return (zero(T), zero(T), zero(T), zero(T))
#     (pz < zero(T) || pz > one(T)) && return (zero(T), zero(T), zero(T), zero(T))
    
#     alpha = one(T)
    
#     for _ in 1:6
#         px *= T(3); py *= T(3); pz *= T(3)
        
#         ix = px ≥ T(2) ? T(2) : (px ≥ one(T) ? one(T) : zero(T))
#         iy = py ≥ T(2) ? T(2) : (py ≥ one(T) ? one(T) : zero(T))
#         iz = pz ≥ T(2) ? T(2) : (pz ≥ one(T) ? one(T) : zero(T))
        
#         cx = ix == one(T) ? one(T) : zero(T)
#         cy = iy == one(T) ? one(T) : zero(T)
#         cz = iz == one(T) ? one(T) : zero(T)
#         c = cx + cy + cz
        
#         if c ≥ T(2)
#             fx = px - ix; fy = py - iy; fz = pz - iz
#             d = min(fx, one(T)-fx, fy, one(T)-fy, fz, one(T)-fz)
#             alpha *= exp(-T(6) * d)
#         end
        
#         px -= ix; py -= iy; pz -= iz
#     end
    
#     shade = alpha
#     (shade * T(0.9), shade * T(0.7), shade * T(0.4), alpha)
# end
# create(g, menger)
# function carpet(x)
#     px = T(2) * (x[2] - T(0.5))
#     py = T(2) * (x[3] - T(0.5))
#     pz = T(2) * (x[4] - T(0.5))
    
#     # Only exists as a thin slab in z: [0.4, 0.6]
#     (pz < T(0.4) || pz > T(0.6)) && return (zero(T), zero(T), zero(T), zero(T))
#     (px < zero(T) || px > one(T)) && return (zero(T), zero(T), zero(T), zero(T))
#     (py < zero(T) || py > one(T)) && return (zero(T), zero(T), zero(T), zero(T))
    
#     # Sierpinski carpet: divide into 3x3, remove center
#     for _ in 1:6
#         px *= T(3); py *= T(3)
        
#         ix = px ≥ T(2) ? T(2) : (px ≥ one(T) ? one(T) : zero(T))
#         iy = py ≥ T(2) ? T(2) : (py ≥ one(T) ? one(T) : zero(T))
        
#         # Center cell = hole
#         if ix == one(T) && iy == one(T)
#             return (zero(T), zero(T), zero(T), zero(T))
#         end
        
#         px -= ix; py -= iy
#     end
    
#     # Solid: color by position
#     (T(0.8), T(0.5), T(0.2), one(T))
# end
# create(g, carpet)
# function carpet(x)
#     px = T(2) * (x[2] - T(0.5))
#     py = T(2) * (x[3] - T(0.5))
#     pz = T(2) * (x[4] - T(0.5))
    
#     # Thicker slab: [0.2, 0.8] in z
#     (pz < T(0.2) || pz > T(0.8)) && return (zero(T), zero(T), zero(T), zero(T))
#     (px < zero(T) || px > one(T)) && return (zero(T), zero(T), zero(T), zero(T))
#     (py < zero(T) || py > one(T)) && return (zero(T), zero(T), zero(T), zero(T))
    
#     depth = zero(T)
#     qx = px; qy = py
    
#     for lev in 1:4
#         qx *= T(3); qy *= T(3)
        
#         ix = qx ≥ T(2) ? T(2) : (qx ≥ one(T) ? one(T) : zero(T))
#         iy = qy ≥ T(2) ? T(2) : (qy ≥ one(T) ? one(T) : zero(T))
        
#         if ix == one(T) && iy == one(T)
#             return (zero(T), zero(T), zero(T), zero(T))
#         end
        
#         qx -= ix; qy -= iy
#         depth = T(lev)
#     end
    
#     # Color by fractal level + position
#     d = depth / T(4)
#     r = T(0.3) + T(0.6) * px
#     g = T(0.2) + T(0.5) * py
#     b = T(0.4) + T(0.4) * d
#     (r, g, b, one(T))
# end
# create(g, carpet)
# run_viewer(g; num_steps=Int32(256))

# run_viewer(g; num_steps=Int32(64))
# include("00104_TheoryOfGodRayMarch.jl")
# run_viewer(g; num_steps=Int32(128))
# run_viewer(g; n=16)


# ϕ = ∃̇(g)
# buffer = mfb_rgb(ϕ)

# using KernelAbstractions
# using Metal ; const GPU_BACKEND = MetalBackend()
# const GPU_BACKEND_WORKGROUPSIZE = 2^2^3
# const T = Float32
# function sierpinski3d(x)
#     mask = UInt32(0x007FFFFF)
#     ix = reinterpret(UInt32, x[2]) & mask
#     iy = reinterpret(UInt32, x[3]) & mask
#     iz = reinterpret(UInt32, x[4]) & mask
#     (ix ⊻ iy ⊻ iz) == zero(UInt32)  # just return Bool
# end
# struct ΦSet{Fs}
#     fs::Fs
# end
# @generated function eval_Φ(φ::ΦSet{Fs}, idx, x) where Fs
#     N = length(Fs.parameters)
#     branches = []
#     for i in 1:N
#         push!(branches, quote
#             if idx == $i
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
#     eval_Φ(φ, 1, (zero(T),zero(T),zero(T),zero(T)))
# end
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
# φ = ΦSet((sierpinski3d,))
# ♯ = (1,3,3,3)
# Φi = zeros(UInt32, ♯)
# Φi[1,2,2,2] = 1
# render(φ, Φi, ♯)
