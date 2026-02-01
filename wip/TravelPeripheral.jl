# dimensions are dt, dx, dy, ...
abstract type Peripheral{T<:Real} end

struct TravelPeripheral{T<:Real} <: Peripheral{T}
    focus::∃{T}           # where I am (region in Ω)
    resolution::Vector{Int}  # how fine I observe
    dt::T                 # traversal speed ∈ [0,1], ○ = sync
end

# Time from complexity
t_now(Ω::∀) = let C = Θ(Ω)
    log(C) / (1 + log(C))
end

# Create peripheral at position
function TravelPeripheral{T}(name::String, d::Vector{T}, μ::Vector{T}, ρ::Vector{T}, resolution::Vector{Int}) where T
    focus = ∃{T}(name, d, μ, ρ, fill(true, 2length(d)), _ -> ○(T), ∀{T}([]), ∃{T}[])
    TravelPeripheral{T}(focus, resolution, ○(T))
end

# Observe: rasterize at my position
function observe(p::TravelPeripheral{T}) where T
    # focus = ∃{T}(
    #     p.focus.ι,
    #     p.focus.d,
    #     p.focus.μ,
    #     p.focus.ρ,
    #     p.focus.∂,
    #     _ -> ○(T),
    #     Ω,
    #     Ω.ϵ
    # )
    # ∃(p.resolution, focus)
    ∃(p.resolution, p.focus)
end
# Move: shift position
function move!(p::TravelPeripheral{T}, Δμ::Vector{T}) where T
    new_μ = p.focus.μ .+ Δμ
    new_μ = clamp.(new_μ, zero(T), one(T))
    new_focus = ∃{T}(p.focus.ι, p.focus.d, new_μ, p.focus.ρ, p.focus.∂, p.focus.∃, p.focus.∃̂, p.focus.ϵ)
    TravelPeripheral{T}(new_focus, p.resolution, p.dt)
end

# Teleport: jump to position
function teleport(p::TravelPeripheral{T}, μ::Vector{T}) where T
    new_focus = ∃{T}(p.focus.ι, p.focus.d, μ, p.focus.ρ, p.focus.∂, p.focus.∃, p.focus.∃̂, p.focus.ϵ)
    TravelPeripheral{T}(new_focus, p.resolution, p.dt)
end

# Scale: change observation radius
function scale(p::TravelPeripheral{T}, ρ::Vector{T}) where T
    new_focus = ∃{T}(p.focus.ι, p.focus.d, p.focus.μ, ρ, p.focus.∂, p.focus.∃, p.focus.∃̂, p.focus.ϵ)
    TravelPeripheral{T}(new_focus, p.resolution, p.dt)
end

# Set traversal speed
function set_speed(p::TravelPeripheral{T}, dt::T) where T
    TravelPeripheral{T}(p.focus, p.resolution, clamp(dt, zero(T), one(T)))
end

# Step through time
function step!(p::TravelPeripheral{T}, Δs::T) where T
    t_obs = p.focus.μ[1]  # current time position (dim 0 = time)
    
    # Traversal rate: dt/(1-dt) maps [0,1] → [0,∞]
    p.dt ≥ one(T) && return teleport(p, setindex!(copy(p.focus.μ), one(T), 1))  # jump to end
    p.dt ≤ zero(T) && return p  # paused
    
    rate = p.dt / (one(T) - p.dt)
    sync_rate = (one(T) - t_obs)^2  # time dilation
    
    Δt = rate * sync_rate * Δs
    new_t = clamp(t_obs + Δt, zero(T), one(T))
    
    new_μ = copy(p.focus.μ)
    new_μ[1] = new_t
    teleport(p, new_μ)
end

# Create something at my position
function create!(p::TravelPeripheral{T}, Ω::∀{T}, ι::String, ρ::Vector{T}, ∃_func::Function) where T
    t_inner = t_now(Ω)
    t_create = p.focus.μ[1]
    
    # Check: cannot create fully in past
    t_end = t_create + ρ[1]
    t_end < t_inner && error("Cannot create in past")
    
    # Create at my position
    ϵ = ∃{T}(ι, p.focus.d, p.focus.μ, ρ, fill(true, 2length(ρ)), ∃_func, Ω, ∃{T}[])
    ∃!(ϵ, Ω)
    ϵ
end

# Observe with privacy (pin shifts coordinates)
function observe(p::TravelPeripheral{T}, Ω::∀{T}, pin::UInt64) where T
    shifted_μ = shift(p.focus.μ, pin)
    shifted_p = teleport(p, shifted_μ)
    observe(shifted_p, Ω)
end

function shift(μ::Vector{T}, pin::UInt64) where T
    h = hash(pin)
    [mod(μ[i] + T(hash(h, UInt64(i))) / T(typemax(UInt64)), one(T)) for i in eachindex(μ)]
end

# Create with privacy
function create!(p::TravelPeripheral{T}, Ω::∀{T}, pin::UInt64, ι::String, ρ::Vector{T}, ∃_func::Function) where T
    shifted_μ = shift(p.focus.μ, pin)
    shifted_p = teleport(p, shifted_μ)
    create!(shifted_p, Ω, ι, ρ, ∃_func)
end
