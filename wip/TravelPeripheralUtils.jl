# ═══════════════════════════════════════════════════════════════════
# CREATION HELPERS
# ═══════════════════════════════════════════════════════════════════

function create_for!(p, Ω, name, duration, shape)
    T = eltype(p.focus.μ)
    t_now = p.focus.μ[1]
    t_end = min(t_now + T(duration), one(T))
    t_center = (t_now + t_end) / 2
    t_radius = (t_end - t_now) / 2
    
    μ = copy(p.focus.μ)
    μ[1] = t_center
    
    ρ = copy(p.focus.ρ)
    ρ[1] = t_radius
    
    ϵ = ∃{T}(name, p.focus.d, μ, ρ, fill(true, 2length(μ)), shape, Ω, ∃{T}[])
    push!(Ω, ϵ)
end

create_eternal!(p, Ω, name, shape) = create_for!(p, Ω, name, one(eltype(p.focus.μ)) - p.focus.μ[1], shape)

create_instant!(p, Ω, name, shape) = create_for!(p, Ω, name, 1//1000, shape)

function copy_to!(ϵ, Ω, new_μ)
    T = eltype(ϵ.μ)
    ϵ_new = ∃{T}(ϵ.ι * "_copy", ϵ.d, new_μ, ϵ.ρ, ϵ.∂, ϵ.∃, Ω, ∃{T}[])
    push!(Ω, ϵ_new)
end

function copy_to_time!(ϵ, Ω, new_t)
    new_μ = copy(ϵ.μ)
    new_μ[1] = eltype(ϵ.μ)(new_t)
    copy_to!(ϵ, Ω, new_μ)
end

# ═══════════════════════════════════════════════════════════════════
# STANDARD SHAPES
# ═══════════════════════════════════════════════════════════════════

shape_dot(; r=1//10) = μ -> begin
    T = eltype(μ.μ)
    x, y = μ.μ[2], μ.μ[3]
    (x - T(1//2))^2 + (y - T(1//2))^2 < T(r)^2 ? one(T) : ○(T)
end

shape_ring(; r=4//10, thickness=1//20) = μ -> begin
    T = eltype(μ.μ)
    x, y = μ.μ[2], μ.μ[3]
    dist2 = (x - T(1//2))^2 + (y - T(1//2))^2
    inner2 = (T(r) - T(thickness))^2
    outer2 = (T(r) + T(thickness))^2
    inner2 < dist2 < outer2 ? one(T) : ○(T)
end

shape_disk(; r=3//10) = shape_dot(r=r)

shape_square(; size=3//10) = μ -> begin
    T = eltype(μ.μ)
    x, y = μ.μ[2], μ.μ[3]
    abs(x - T(1//2)) < T(size) && abs(y - T(1//2)) < T(size) ? one(T) : ○(T)
end

shape_or(s1, s2) = μ -> max(s1(μ), s2(μ))
shape_and(s1, s2) = μ -> min(s1(μ), s2(μ))
shape_not(s) = μ -> one(eltype(μ.μ)) - s(μ)

# ═══════════════════════════════════════════════════════════════════
# OBSERVATION HELPERS
# ═══════════════════════════════════════════════════════════════════

function observe_now(p, Ω; resolution=21)
    T = eltype(p.focus.μ)
    me = TravelPeripheral{T}(p.focus.ι, p.focus.d, p.focus.μ, 
        T[1//1000, p.focus.ρ[2], p.focus.ρ[3]], [1, resolution, resolution])
    v = observe(me, Ω)
    v[1, :, :]
end

function show_slice(slice)
    T = eltype(slice)
    for i in size(slice, 1):-1:1
        println(join([slice[i, j] > ○(T) ? "●●" : "  " for j in 1:size(slice, 2)]))
    end
end

function look!(p, Ω; resolution=21)
    slice = observe_now(p, Ω; resolution=resolution)
    show_slice(slice)
    slice
end

# ═══════════════════════════════════════════════════════════════════
# TIME TRAVEL
# ═══════════════════════════════════════════════════════════════════

function goto_time(p, t)
    T = eltype(p.focus.μ)
    new_μ = copy(p.focus.μ)
    new_μ[1] = T(t)
    teleport(p, new_μ)
end

forward(p, Δt) = goto_time(p, min(p.focus.μ[1] + eltype(p.focus.μ)(Δt), one(eltype(p.focus.μ))))
backward(p, Δt) = goto_time(p, max(p.focus.μ[1] - eltype(p.focus.μ)(Δt), zero(eltype(p.focus.μ))))
goto_start(p) = goto_time(p, zero(eltype(p.focus.μ)))
goto_end(p) = goto_time(p, one(eltype(p.focus.μ)))

# ═══════════════════════════════════════════════════════════════════
# QUICK START
# ═══════════════════════════════════════════════════════════════════

function new_world(T=Rational{BigInt})
    Ω = ∀{T}([])
    dims = T[0, 1, 2]
    me = TravelPeripheral{T}("me", dims, T[1//2, 1//2, 1//2], T[1//2, 1//2, 1//2], [21, 21, 21])
    (Ω=Ω, me=me)
end