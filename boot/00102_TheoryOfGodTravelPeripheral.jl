# dimensions are dt, dx, dy, ... ?

struct TravelPeripheral{T<:Real} <: AbstractPeripheral{T}
    peripheral::Peripheral
    dt::T
end

# Time from complexity
t_now(Ω::∀) = let C = Θ(Ω)
    log(C) / (1 + log(C))
end

# Create peripheral at position
function TravelPeripheral{T}(name, d, μ, ρ, resolution, target) where {T<:Real}
    focus = ∃{T}(name, d, μ, ρ, fill(true, 2length(d)), _ -> ○(T), target, [])
    peripheral = Peripheral{T}(target, focus, resolution)
    TravelPeripheral{T}(peripheral, ○(T))
end

# Set traversal speed
function set_speed(p::TravelPeripheral, dt)
    T = eltype(p.peripheral.focus.μ)
    TravelPeripheral(p.peripheral, clamp(dt, zero(T), one(T)))
end

# Step through time
function step!(p::TravelPeripheral, Δs)
    T = eltype(p.peripheral.focus.μ)

    t_obs = p.peripheral.focus.μ[1]  # current time position (dim 0 = time)
    
    # Traversal rate: dt/(1-dt) maps [0,1] → [0,∞]
    p.dt ≥ one(T) && return teleport(p, setindex!(copy(p.peripheral.focus.μ), one(T), 1))  # jump to end
    p.dt ≤ zero(T) && return p  # paused
    
    rate = p.dt / (one(T) - p.dt)
    sync_rate = (one(T) - t_obs)^2  # time dilation
    
    Δt = rate * sync_rate * Δs
    new_t = clamp(t_obs + Δt, zero(T), one(T))
    
    new_μ = copy(p.peripheral.focus.μ)
    new_μ[1] = new_t
    teleport(p, new_μ)
end

# Create something at my position
function create!(p::TravelPeripheral, Ω, ι, ρ, ∃_func)
    T = eltype(p.focus.μ)

    t_inner = t_now(Ω)
    t_create = p.focus.μ[1]
    
    # Check: cannot create fully in past
    t_end = t_create + ρ[1]
    t_end < t_inner && error("Cannot create in past")
    
    # Create at my position
    ϵ = ∃{T}(ι, p.focus.d, p.focus.μ, ρ, fill(true, 2length(ρ)), ∃_func, Ω, [])
    ∃!(ϵ, Ω)
    ϵ
end

# Observe with privacy (pin shifts coordinates)
function observe(p::TravelPeripheral, pin=0)
    shifted_μ = shift(p.focus.μ, pin)
    shifted_p = teleport(p, shifted_μ)
    p̂ = Peripheral(Ω, shifted_p.focus, shifted_p.resolution)
    observe(p̂)
end

# Shift coordinates for privacy
function shift(μ, pin)
    T = eltype(μ)
    h = hash(pin)
    [mod(μ[i] + T(hash(h, UInt64(i))) / T(typemax(UInt64)), one(T)) for i in eachindex(μ)]
end

# Create with privacy
function create!(p::TravelPeripheral, Ω, ι, ρ, ∃_func, pin=0)
    shifted_μ = shift(p.focus.μ, pin)
    shifted_p = teleport(p, shifted_μ)
    create!(shifted_p, Ω, ι, ρ, ∃_func)
end

teleport(p::TravelPeripheral, μ) = TravelPeripheral(teleport(p.peripheral, μ), p.dt)

scale(p::TravelPeripheral, ρ) = TravelPeripheral(scale(p.peripheral, ρ),p.dt)

function move(p::TravelPeripheral, Δμ)
    T = eltype(p.focus.μ)
    μ = clamp.(p.focus.μ .+ Δμ, zero(T), one(T))
    teleport(p, μ)
end
