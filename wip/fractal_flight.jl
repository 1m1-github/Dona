
# Flying into the Mandelbrot Set
# Deep zoom into interesting regions

include("something.jl")
include("something_demo.jl")

T = Rational{BigInt}

# ============================================================
# DEEP ZOOM INTO MANDELBROT - Seahorse Valley
# ============================================================

println("Flying into Mandelbrot - Seahorse Valley...")
println("This may take a few minutes...")

function mandelbrot_value(px, py, center_x, center_y, radius, max_iter)
    # Map [0,1] pixel coords to complex plane centered at (center_x, center_y)
    x0 = center_x + (px - 0.5) * 2 * radius
    y0 = center_y + (py - 0.5) * 2 * radius
    
    x, y = 0.0, 0.0
    iter = 0
    
    while x*x + y*y <= 4 && iter < max_iter
        x, y = x*x - y*y + x0, 2*x*y + y0
        iter += 1
    end
    
    if iter == max_iter
        0.0  # inside = black
    else
        # Smooth coloring
        0.3 + 0.7 * (iter / max_iter)
    end
end

# Seahorse valley coordinates (in complex plane)
target_re = -0.743643887037151
target_im = 0.131825904205330

frames = Array{Real,2}[]
n_frames = 120
resolution = 150

# Zoom from radius 1.5 down to 0.0000001 (10^7 zoom)
start_radius = 1.5
end_radius = 0.00001

for i in 0:n_frames-1
    # Exponential interpolation for smooth zoom
    t = i / (n_frames - 1)
    radius = start_radius * (end_radius / start_radius) ^ t
    
    # Increase iterations as we zoom deeper
    max_iter = 100 + round(Int, t * 400)
    
    empty!(Ω.children)
    empty!(CACHE)
    
    create("mandelbrot_frame",
        T[1//2, 1//2],
        T[1//2, 1//2],
        T[0, 1],
        ω -> begin
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            mandelbrot_value(px, py, target_re, target_im, radius, max_iter)
        end
    )
    
    screen = Peripheral{T}(
        "frame",
        Dict{T,T}(),
        T[0, 1],
        [resolution, resolution],
        T[1//2, 1//2],
        T[1//2, 1//2]
    )
    
    push!(frames, render(screen))
    print("\rFrame $(i+1)/$(n_frames)")
end
println()

to_gif(frames, "mandelbrot_flight.gif", scale=3, delay=4)
println("✓ Saved mandelbrot_flight.gif")

# ============================================================
# DEEP ZOOM INTO MANDELBROT - Spiral
# ============================================================

println("\nFlying into Mandelbrot - Double Spiral...")

# Double spiral coordinates
target_re2 = -0.7436438870371
target_im2 = 0.1318259043124

frames2 = Array{Real,2}[]

for i in 0:n_frames-1
    t = i / (n_frames - 1)
    radius = start_radius * (end_radius / start_radius) ^ t
    max_iter = 100 + round(Int, t * 500)
    
    empty!(Ω.children)
    empty!(CACHE)
    
    create("spiral_frame",
        T[1//2, 1//2],
        T[1//2, 1//2],
        T[0, 1],
        ω -> begin
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            mandelbrot_value(px, py, target_re2, target_im2, radius, max_iter)
        end
    )
    
    screen = Peripheral{T}(
        "frame",
        Dict{T,T}(),
        T[0, 1],
        [resolution, resolution],
        T[1//2, 1//2],
        T[1//2, 1//2]
    )
    
    push!(frames2, render(screen))
    print("\rFrame $(i+1)/$(n_frames)")
end
println()

to_gif(frames2, "mandelbrot_spiral.gif", scale=3, delay=4)
println("✓ Saved mandelbrot_spiral.gif")

# ============================================================
# FLYING THROUGH JULIA SETS - morphing as we travel
# ============================================================

println("\nFlying through Julia set space...")

function julia_value(px, py, c_re, c_im, max_iter)
    x = (px - 0.5) * 3.0
    y = (py - 0.5) * 3.0
    
    iter = 0
    while x*x + y*y <= 4 && iter < max_iter
        x, y = x*x - y*y + c_re, 2*x*y + c_im
        iter += 1
    end
    
    if iter == max_iter
        0.0
    else
        0.3 + 0.7 * (iter / max_iter)
    end
end

frames3 = Array{Real,2}[]
n_frames3 = 90

# Travel along the boundary of the Mandelbrot set (where interesting Julias live)
for i in 0:n_frames3-1
    t = i / n_frames3
    
    # Trace cardioid boundary: c = (e^(iθ)/2 - e^(2iθ)/4)
    θ = 2π * t
    c_re = 0.5 * cos(θ) - 0.25 * cos(2θ)
    c_im = 0.5 * sin(θ) - 0.25 * sin(2θ)
    
    # Scale to stay in interesting region
    c_re = c_re * 0.8 - 0.1
    c_im = c_im * 0.8
    
    empty!(Ω.children)
    empty!(CACHE)
    
    create("julia_travel",
        T[1//2, 1//2],
        T[1//2, 1//2],
        T[0, 1],
        ω -> begin
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            julia_value(px, py, c_re, c_im, 80)
        end
    )
    
    screen = Peripheral{T}(
        "frame",
        Dict{T,T}(),
        T[0, 1],
        [resolution, resolution],
        T[1//2, 1//2],
        T[1//2, 1//2]
    )
    
    push!(frames3, render(screen))
    print("\rFrame $(i+1)/$(n_frames3)")
end
println()

to_gif(frames3, "julia_journey.gif", scale=3, delay=5)
println("✓ Saved julia_journey.gif")

# ============================================================
# ZOOM + ROTATE simultaneously
# ============================================================

println("\nSpiral dive into Mandelbrot...")

frames4 = Array{Real,2}[]
n_frames4 = 100

# Zoom while rotating view
for i in 0:n_frames4-1
    t = i / (n_frames4 - 1)
    radius = 1.5 * (0.0001 / 1.5) ^ t
    angle = t * 4π  # 2 full rotations during zoom
    max_iter = 100 + round(Int, t * 400)
    
    empty!(Ω.children)
    empty!(CACHE)
    
    create("spiral_dive",
        T[1//2, 1//2],
        T[1//2, 1//2],
        T[0, 1],
        ω -> begin
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            
            # Rotate coordinates around center
            cx, cy = 0.5, 0.5
            dx, dy = px - cx, py - cy
            rx = dx * cos(angle) - dy * sin(angle) + cx
            ry = dx * sin(angle) + dy * cos(angle) + cy
            
            mandelbrot_value(rx, ry, target_re, target_im, radius, max_iter)
        end
    )
    
    screen = Peripheral{T}(
        "frame",
        Dict{T,T}(),
        T[0, 1],
        [resolution, resolution],
        T[1//2, 1//2],
        T[1//2, 1//2]
    )
    
    push!(frames4, render(screen))
    print("\rFrame $(i+1)/$(n_frames4)")
end
println()

to_gif(frames4, "mandelbrot_spiral_dive.gif", scale=3, delay=4)
println("✓ Saved mandelbrot_spiral_dive.gif")

# ============================================================
println("\n" * "="^50)
println("All flight animations generated!")
println("="^50)
println("""
Files:
  - mandelbrot_flight.gif      : Deep zoom into seahorse valley (10^5 zoom)
  - mandelbrot_spiral.gif      : Deep zoom into double spiral
  - julia_journey.gif          : Traveling through Julia set parameter space
  - mandelbrot_spiral_dive.gif : Zoom + rotate simultaneously
  
Total frames rendered: $(n_frames + n_frames + n_frames3 + n_frames4)
""")