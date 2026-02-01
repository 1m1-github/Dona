# ═══════════════════════════════════════════════════════════════════
# 4D COLOR MODEL: (t, x, y, c)
# 
# Dimensions:
#   d[1] = t (time)
#   d[2] = x (horizontal space)  
#   d[3] = y (vertical space)
#   d[4] = c (color channel: 0→H, ○→S, 1→L)
#
# The ∃ value at each point encodes the HSL component value.
# ═══════════════════════════════════════════════════════════════════

module ColorPeripheralModule

# using Base.Threads

# # Import from Main (assuming these are defined there)
# import Main: ○, ∃, ∀, Pretopology, AbstractPeripheral, Peripheral, TravelPeripheral
# import Main: observe, teleport, scale, move, X, Ξ

# ═══════════════════════════════════════════════════════════════════
# HSL ↔ RGB CONVERSION
# ═══════════════════════════════════════════════════════════════════

struct RGB{T<:Real}
    r::T
    g::T
    b::T
end

struct HSL{T<:Real}
    h::T  # 0-1
    s::T  # 0-1
    l::T  # 0-1
end

function hsl_to_rgb(hsl::HSL{T}) where {T<:Real}
    h, s, l = hsl.h, hsl.s, hsl.l
    
    # Achromatic (gray)
    s ≤ zero(T) && return RGB{T}(l, l, l)
    
    function hue_to_rgb(p, q, t)
        t < zero(T) && (t += one(T))
        t > one(T) && (t -= one(T))
        t < T(1//6) && return p + (q - p) * T(6) * t
        t < T(1//2) && return q
        t < T(2//3) && return p + (q - p) * (T(2//3) - t) * T(6)
        p
    end
    
    q = l < T(1//2) ? l * (one(T) + s) : l + s - l * s
    p = T(2) * l - q
    
    r = hue_to_rgb(p, q, h + T(1//3))
    g = hue_to_rgb(p, q, h)
    b = hue_to_rgb(p, q, h - T(1//3))
    
    RGB{T}(r, g, b)
end

function rgb_to_hsl(rgb::RGB{T}) where {T<:Real}
    r, g, b = rgb.r, rgb.g, rgb.b
    
    max_c = max(r, g, b)
    min_c = min(r, g, b)
    l = (max_c + min_c) / T(2)
    
    # Achromatic
    max_c == min_c && return HSL{T}(○(T), zero(T), l)
    
    d = max_c - min_c
    s = l > T(1//2) ? d / (T(2) - max_c - min_c) : d / (max_c + min_c)
    
    h = if max_c == r
        (g - b) / d + (g < b ? T(6) : zero(T))
    elseif max_c == g
        (b - r) / d + T(2)
    else
        (r - g) / d + T(4)
    end
    h /= T(6)
    
    HSL{T}(h, s, l)
end

# ═══════════════════════════════════════════════════════════════════
# COLOR CHANNEL INTERPRETATION
# ═══════════════════════════════════════════════════════════════════

# c dimension values for each channel
c_hue(::Type{T}) where {T<:Real} = zero(T)
c_sat(::Type{T}) where {T<:Real} = ○(T)
c_lit(::Type{T}) where {T<:Real} = one(T)

# Which channel does this c value represent?
# Samples at 1/4 (H), 1/2 (S), 3/4 (L)
function which_channel(c::T) where {T<:Real}
    c < T(3//8) && return :hue        # 1/4 region
    c < T(5//8) && return :saturation  # 1/2 region
    :lightness                          # 3/4 region
end

# ═══════════════════════════════════════════════════════════════════
# SHAPE HELPERS - Creating colored shapes
# ═══════════════════════════════════════════════════════════════════

"""
    shape_colored(shape_2d, hsl::HSL)

Wrap a 2D spatial shape with a fixed color.
shape_2d: μ → Bool/T (returns whether point is inside shape, using μ.μ[2], μ.μ[3] for x, y)
Returns a 4D shape function for (t, x, y, c) that returns HSL values.
"""
function shape_colored(shape_2d, hsl::HSL{T}) where {T<:Real}
    μ -> begin
        Tμ = eltype(μ.μ)
        ○_val = ○(Tμ)
        
        # Get spatial mask from 2D shape
        in_shape = shape_2d(μ)
        (in_shape isa Bool ? !in_shape : in_shape ≤ ○_val) && return ○_val  # outside → no info
        
        # Inside shape: return appropriate HSL channel
        c = length(μ.μ) ≥ 4 ? μ.μ[4] : ○_val
        
        channel = which_channel(c)
        if channel == :hue
            Tμ(hsl.h)
        elseif channel == :saturation
            Tμ(hsl.s)
        else
            Tμ(hsl.l)
        end
    end
end

function shape_colored(shape_2d, rgb::RGB{T}) where {T<:Real}
    shape_colored(shape_2d, rgb_to_hsl(rgb))
end

"""
    shape_colored(shape_2d, r, g, b)

Convenience: wrap 2D shape with RGB color components.
"""
shape_colored(shape_2d, r, g, b) = shape_colored(shape_2d, RGB(r, g, b))

# ═══════════════════════════════════════════════════════════════════
# STANDARD 2D SHAPES (for use with shape_colored)
# ═══════════════════════════════════════════════════════════════════

shape_disk_2d(; cx=1//2, cy=1//2, r=1//10) = μ -> begin
    T = eltype(μ.μ)
    x, y = μ.μ[2], μ.μ[3]
    (x - T(cx))^2 + (y - T(cy))^2 < T(r)^2
end

shape_rect_2d(; cx=1//2, cy=1//2, rx=1//10, ry=1//10) = μ -> begin
    T = eltype(μ.μ)
    x, y = μ.μ[2], μ.μ[3]
    abs(x - T(cx)) < T(rx) && abs(y - T(cy)) < T(ry)
end

shape_ring_2d(; cx=1//2, cy=1//2, r=3//10, thickness=1//20) = μ -> begin
    T = eltype(μ.μ)
    x, y = μ.μ[2], μ.μ[3]
    dist2 = (x - T(cx))^2 + (y - T(cy))^2
    inner2 = (T(r) - T(thickness))^2
    outer2 = (T(r) + T(thickness))^2
    inner2 < dist2 < outer2
end

shape_full_2d() = μ -> true  # fills entire space

# ═══════════════════════════════════════════════════════════════════
# 4D TRAVEL PERIPHERAL
# ═══════════════════════════════════════════════════════════════════

"""
    TravelPeripheral4D{T}

A peripheral configured for 4D (t, x, y, c) observation and creation.
"""
struct TravelPeripheral4D{T<:Real} <: AbstractPeripheral{T}
    peripheral::Peripheral{T}
    dt::T
    default_hsl::HSL{T}  # default color for ○ values
end

# Standard 4D dimensions
dims_4d(::Type{T}) where {T<:Real} = T[0, 1, 2, 3]  # t, x, y, c

"""
    TravelPeripheral4D(name, target; T=Rational{BigInt}, ...)

Create a 4D peripheral at given position with given view radius.
"""
function TravelPeripheral4D(
    name::String,
    target::Pretopology{T};
    μ_t::T = ○(T),
    μ_x::T = ○(T),
    μ_y::T = ○(T),
    ρ_t::T = ○(T),
    ρ_x::T = ○(T),
    ρ_y::T = ○(T),
    default_hsl::HSL{T} = HSL{T}(○(T), zero(T), one(T))  # default: white
) where {T<:Real}
    d = dims_4d(T)
    μ = T[μ_t, μ_x, μ_y, ○(T)]  # c centered at ○
    ρ = T[ρ_t, ρ_x, ρ_y, ○(T)]  # c spans full range
    
    focus = ∃{T}(name, d, μ, ρ, fill(true, 2length(d)), _ -> ○(T), target, ∃{T}[])
    peripheral = Peripheral{T}(target, focus, [1, 1, 1, 3])  # default res, 3 for HSL
    
    TravelPeripheral4D{T}(peripheral, ○(T), default_hsl)
end

# Accessors
Base.getproperty(p::TravelPeripheral4D, s::Symbol) = 
    s ∈ (:peripheral, :dt, :default_hsl) ? getfield(p, s) : getproperty(p.peripheral, s)

# ═══════════════════════════════════════════════════════════════════
# OBSERVATION → RGB
# ═══════════════════════════════════════════════════════════════════

"""
    observe_hsl(p::TravelPeripheral4D, x_res, y_res; t_res=1)

Observe and return raw HSL arrays.
Returns (H, S, L) where each is a Matrix{T} of size (x_res, y_res).
"""
function observe_hsl(p::TravelPeripheral4D{T}, x_res::Int, y_res::Int; t_res::Int=1) where {T<:Real}
    # Set resolution: [t, x, y, c]
    # Use 5 samples for c: at 0, 1/4, 1/2, 3/4, 1
    # Then extract indices 1, 3, 5 which give 0, 1/2, 1 but are interior to nothing...
    # 
    # Better approach: use resolution 5 for c, range [0,1], take samples 2,3,4 (at 1/4, 1/2, 3/4)
    # These are interior points.
    resolution = [t_res, x_res, y_res, 5]
    
    d = dims_4d(T)
    μ = copy(p.peripheral.focus.μ)
    ρ = copy(p.peripheral.focus.ρ)
    ρ[4] = ○(T)  # c spans [0, 1]
    
    focus = ∃{T}(p.peripheral.focus.ι, d, μ, ρ, p.peripheral.focus.∂, 
                  _ -> ○(T), p.peripheral.target, ∃{T}[])
    
    # Observe
    peripheral = Peripheral{T}(p.peripheral.target, focus, resolution)
    raw = observe(peripheral)
    
    # Extract HSL channels from indices 2, 3, 4 (samples at 1/4, 1/2, 3/4)
    # raw shape: [t_res, x_res, y_res, 5]
    H = raw[1, :, :, 2]  # c = 1/4 → hue
    S = raw[1, :, :, 3]  # c = 1/2 → saturation  
    L = raw[1, :, :, 4]  # c = 3/4 → lightness
    
    (H, S, L)
end

"""
    observe_rgb(p::TravelPeripheral4D, x_res, y_res; t_res=1)

Observe and return RGB matrix.
Applies default color only where ALL HSL channels are ○ (no information).
"""
function observe_rgb(p::TravelPeripheral4D{T}, x_res::Int, y_res::Int; t_res::Int=1) where {T<:Real}
    H, S, L = observe_hsl(p, x_res, y_res; t_res=t_res)
    
    ○_val = ○(T)
    ε = T(1//1000)
    default = p.default_hsl
    
    rgb = Matrix{RGB{T}}(undef, x_res, y_res)
    
    for i in 1:x_res, j in 1:y_res
        h = H[i, j]
        s = S[i, j]
        l = L[i, j]
        
        # Only replace with default if ALL channels are ○ (no information)
        h_is_default = abs(h - ○_val) < ε
        s_is_default = abs(s - ○_val) < ε
        l_is_default = abs(l - ○_val) < ε
        
        if h_is_default && s_is_default && l_is_default
            # No entity here - use default color
            rgb[i, j] = hsl_to_rgb(default)
        else
            # Entity present - use actual values, but fill in ○ channels with neutral defaults
            h_final = h_is_default ? T(0) : h      # default hue = red (arbitrary)
            s_final = s_is_default ? T(0) : s      # default saturation = gray
            l_final = l_is_default ? ○_val : l     # default lightness = mid
            rgb[i, j] = hsl_to_rgb(HSL{T}(h_final, s_final, l_final))
        end
    end
    
    rgb
end

# ═══════════════════════════════════════════════════════════════════
# CREATION HELPERS
# ═══════════════════════════════════════════════════════════════════

"""
    create_colored!(p::TravelPeripheral4D, Ω, name, shape_2d, hsl; duration=1//10, ρ_x=1//4, ρ_y=1//4)

Create a colored entity at the peripheral's current position.
"""
function create_colored!(
    p::TravelPeripheral4D{T},
    Ω::∀{T},
    name::String,
    shape_2d,
    hsl::HSL{T};
    duration::T = T(1//10),
    ρ_x::T = T(1//4),
    ρ_y::T = T(1//4)
) where {T<:Real}
    
    t_now = p.peripheral.focus.μ[1]
    t_end = min(t_now + duration, one(T))
    t_center = (t_now + t_end) / T(2)
    t_radius = (t_end - t_now) / T(2)
    
    d = dims_4d(T)
    μ = T[t_center, p.peripheral.focus.μ[2], p.peripheral.focus.μ[3], ○(T)]
    ρ = T[t_radius, ρ_x, ρ_y, ○(T)]  # full c range
    
    shape = shape_colored(shape_2d, hsl)
    
    ϵ = ∃{T}(name, d, μ, ρ, fill(true, 2length(d)), shape, Ω, ∃{T}[])
    push!(Ω, ϵ)
end

function create_colored!(p::TravelPeripheral4D{T}, Ω::∀{T}, name::String, shape_2d, rgb::RGB{T}; kwargs...) where {T<:Real}
    create_colored!(p, Ω, name, shape_2d, rgb_to_hsl(rgb); kwargs...)
end

function create_colored!(p::TravelPeripheral4D{T}, Ω::∀{T}, name::String, shape_2d, r, g, b; kwargs...) where {T<:Real}
    create_colored!(p, Ω, name, shape_2d, RGB{T}(T(r), T(g), T(b)); kwargs...)
end

# ═══════════════════════════════════════════════════════════════════
# MOVEMENT
# ═══════════════════════════════════════════════════════════════════

function teleport(p::TravelPeripheral4D{T}, μ) where {T<:Real}
    old_focus = p.peripheral.focus
    new_focus = ∃{T}(old_focus.ι, old_focus.d, μ, old_focus.ρ, old_focus.∂, old_focus.∃, old_focus.∃̂, old_focus.ϵ)
    new_peripheral = Peripheral{T}(p.peripheral.target, new_focus, p.peripheral.resolution)
    TravelPeripheral4D{T}(new_peripheral, p.dt, p.default_hsl)
end

function move(p::TravelPeripheral4D{T}, Δμ) where {T<:Real}
    old_focus = p.peripheral.focus
    μ = clamp.(old_focus.μ .+ Δμ, zero(T), one(T))
    teleport(p, μ)
end

function goto_time(p::TravelPeripheral4D{T}, t) where {T<:Real}
    μ = copy(p.peripheral.focus.μ)
    μ[1] = T(t)
    teleport(p, μ)
end

function goto_xy(p::TravelPeripheral4D{T}, x, y) where {T<:Real}
    μ = copy(p.peripheral.focus.μ)
    μ[2] = T(x)
    μ[3] = T(y)
    teleport(p, μ)
end

forward(p::TravelPeripheral4D, Δt) = goto_time(p, min(p.peripheral.focus.μ[1] + eltype(p.peripheral.focus.μ)(Δt), one(eltype(p.peripheral.focus.μ))))
backward(p::TravelPeripheral4D, Δt) = goto_time(p, max(p.peripheral.focus.μ[1] - eltype(p.peripheral.focus.μ)(Δt), zero(eltype(p.peripheral.focus.μ))))

# ═══════════════════════════════════════════════════════════════════
# DISPLAY HELPER
# ═══════════════════════════════════════════════════════════════════

"""
    show_ascii(rgb::Matrix{RGB{T}})

Display RGB matrix as ASCII art.
Dark pixels (low luminance) show as filled, light pixels as empty.
"""
function show_ascii(rgb::Matrix{RGB{T}}) where {T<:Real}
    for j in size(rgb, 2):-1:1
        row = ""
        for i in 1:size(rgb, 1)
            c = rgb[i, j]
            luminance = T(299//1000) * c.r + T(587//1000) * c.g + T(114//1000) * c.b
            # Dark = filled, light = empty
            row *= luminance < T(1//2) ? "██" : (luminance < T(9//10) ? "░░" : "  ")
        end
        println(row)
    end
end

"""
    look!(p::TravelPeripheral4D; resolution=21)

Observe and display current view as ASCII.
"""
function look!(p::TravelPeripheral4D; resolution::Int=21)
    rgb = observe_rgb(p, resolution, resolution)
    show_ascii(rgb)
    rgb
end

# ═══════════════════════════════════════════════════════════════════
# QUICK START
# ═══════════════════════════════════════════════════════════════════

"""
    new_world_4d(T=Rational{BigInt})

Create a new 4D world with a peripheral ready to explore.
"""
function new_world_4d(T::Type{<:Real}=Rational{BigInt})
    Ω = ∀{T}(∃{T}[])
    
    me = TravelPeripheral4D(
        "me", Ω;
        μ_t = ○(T),
        μ_x = ○(T),
        μ_y = ○(T),
        ρ_t = T(1//1000),  # thin time slice
        ρ_x = ○(T),        # see full x
        ρ_y = ○(T),        # see full y
        default_hsl = HSL{T}(○(T), zero(T), one(T))  # white background
    )
    
    (Ω=Ω, me=me)
end

export RGB, HSL, hsl_to_rgb, rgb_to_hsl
export shape_colored, shape_disk_2d, shape_rect_2d, shape_ring_2d, shape_full_2d
export TravelPeripheral4D, observe_hsl, observe_rgb, create_colored!
export teleport, move, goto_time, goto_xy, forward, backward
export show_ascii, look!, new_world_4d

end # module
