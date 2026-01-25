# Improved Fractal Animations

include("something.jl")
include("something_demo.jl")

T = Rational{BigInt}

# ============================================================
# MANDELBROT ZOOM - into the famous spiral region
# ============================================================

println("Creating Mandelbrot zoom into spiral region...")

empty!(Ω.children)
empty!(CACHE)

create("mandelbrot",
    T[1//2, 1//2],
    T[1//2, 1//2],
    T[0, 1],
    ω -> begin
        px = Float64(get_dim(ω, T(0)))
        py = Float64(get_dim(ω, T(1)))
        
        # Map [0,1] to [-2.5, 1.0] x [-1.5, 1.5]
        x0 = px * 3.5 - 2.5
        y0 = py * 3.0 - 1.5
        
        x, y = 0.0, 0.0
        iter = 0
        max_iter = 100
        
        while x*x + y*y <= 4 && iter < max_iter
            x, y = x*x - y*y + x0, 2*x*y + y0
            iter += 1
        end
        
        # Smooth coloring
        if iter == max_iter
            0.1  # inside = dark
        else
            0.5 + 0.4 * (iter / max_iter)
        end
    end
)

# Zoom into seahorse valley: approximately (-0.75, 0.1)
# In our [0,1] coords: x = (-0.75 + 2.5) / 3.5 ≈ 0.5, y = (0.1 + 1.5) / 3.0 ≈ 0.53

zoom_frames = Array{Real,2}[]
n_zoom = 50

# Target in [0,1] coordinates
target_x = T(50//100)  # seahorse valley
target_y = T(53//100)

for i in 0:n_zoom-1
    # Exponential zoom: start at 1/2, shrink by 0.92 each frame
    scale = Float64(1//2) * (0.92 ^ i)
    scale_r = T(round(Int, scale * 1000)) // 1000
    
    screen = Peripheral{T}(
        "zoom",
        Dict{T,T}(),
        T[0, 1],
        [120, 120],
        T[target_x, target_y],
        T[scale_r, scale_r]
    )
    
    empty!(CACHE)
    push!(zoom_frames, render(screen))
    print(".")
end
println()

to_gif(zoom_frames, "mandelbrot_zoom2.gif", scale=3, delay=6)
println("✓ Saved mandelbrot_zoom2.gif")

# ============================================================
# ROTATING MANDELBROT - rotate view angle over time
# ============================================================

println("\nCreating rotating Mandelbrot...")

function mandelbrot_rotated(px, py, angle)
    # Map and rotate
    x0 = px * 3.5 - 2.5
    y0 = py * 3.0 - 1.5
    
    # Rotate around (-0.5, 0)
    cx, cy = -0.5, 0.0
    x0r = (x0 - cx) * cos(angle) - (y0 - cy) * sin(angle) + cx
    y0r = (x0 - cx) * sin(angle) + (y0 - cy) * cos(angle) + cy
    
    x, y = 0.0, 0.0
    iter = 0
    max_iter = 80
    
    while x*x + y*y <= 4 && iter < max_iter
        x, y = x*x - y*y + x0r, 2*x*y + y0r
        iter += 1
    end
    
    iter == max_iter ? 0.1 : 0.5 + 0.4 * (iter / max_iter)
end

rotate_frames = Array{Real,2}[]
n_rotate = 60

for i in 0:n_rotate-1
    angle = 2π * i / n_rotate
    
    # Create fresh for each angle
    empty!(Ω.children)
    empty!(CACHE)
    
    create("mandelbrot_rot",
        T[1//2, 1//2],
        T[1//2, 1//2],
        T[0, 1],
        ω -> begin
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            mandelbrot_rotated(px, py, angle)
        end
    )
    
    screen = Peripheral{T}(
        "rot",
        Dict{T,T}(),
        T[0, 1],
        [100, 100],
        T[1//2, 1//2],
        T[1//2, 1//2]
    )
    
    push!(rotate_frames, render(screen))
    print(".")
end
println()

to_gif(rotate_frames, "mandelbrot_rotate.gif", scale=3, delay=5)
println("✓ Saved mandelbrot_rotate.gif")

# ============================================================
# PULSING JULIA SET - single interesting c, zoom in/out
# ============================================================

println("\nCreating pulsing Julia set...")

function julia(px, py, c_re, c_im, max_iter)
    x = px * 3.0 - 1.5
    y = py * 3.0 - 1.5
    
    iter = 0
    while x*x + y*y <= 4 && iter < max_iter
        x, y = x*x - y*y + c_re, 2*x*y + c_im
        iter += 1
    end
    
    iter == max_iter ? 0.1 : 0.5 + 0.45 * (iter / max_iter)
end

pulse_frames = Array{Real,2}[]
n_pulse = 40

# Beautiful Julia set at c = -0.7269 + 0.1889i
c_re, c_im = -0.7269, 0.1889

for i in 0:n_pulse-1
    # Pulse: zoom in then out
    t = i / n_pulse
    scale = 0.3 + 0.2 * sin(2π * t)
    scale_r = T(round(Int, scale * 1000)) // 1000
    
    empty!(Ω.children)
    empty!(CACHE)
    
    create("julia",
        T[1//2, 1//2],
        T[1//2, 1//2],
        T[0, 1],
        ω -> begin
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            julia(px, py, c_re, c_im, 80)
        end
    )
    
    screen = Peripheral{T}(
        "pulse",
        Dict{T,T}(),
        T[0, 1],
        [100, 100],
        T[1//2, 1//2],
        T[scale_r, scale_r]
    )
    
    push!(pulse_frames, render(screen))
    print(".")
end
println()

to_gif(pulse_frames, "julia_pulse.gif", scale=3, delay=5)
println("✓ Saved julia_pulse.gif")

# ============================================================
# MORPHING JULIA - smoothly change c parameter
# ============================================================

println("\nCreating morphing Julia set...")

morph_frames = Array{Real,2}[]
n_morph = 60

# Trace a path through interesting c values
for i in 0:n_morph-1
    t = i / n_morph
    
    # Trace a circle in c-space that hits interesting Julia sets
    angle = 2π * t
    radius = 0.7885
    c_re = radius * cos(angle)
    c_im = radius * sin(angle)
    
    empty!(Ω.children)
    empty!(CACHE)
    
    create("julia_morph",
        T[1//2, 1//2],
        T[1//2, 1//2],
        T[0, 1],
        ω -> begin
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            julia(px, py, c_re, c_im, 60)
        end
    )
    
    screen = Peripheral{T}(
        "morph",
        Dict{T,T}(),
        T[0, 1],
        [100, 100],
        T[1//2, 1//2],
        T[2//5, 2//5]
    )
    
    push!(morph_frames, render(screen))
    print(".")
end
println()

to_gif(morph_frames, "julia_morph.gif", scale=3, delay=5)
println("✓ Saved julia_morph.gif")

# ============================================================
println("\n" * "="^50)
println("All animations generated!")
println("="^50)
println("""
Files:
  - mandelbrot_zoom2.gif  : Zoom into seahorse valley
  - mandelbrot_rotate.gif : Mandelbrot rotating
  - julia_pulse.gif       : Julia set breathing (zoom in/out)
  - julia_morph.gif       : Julia set morphing (c rotates)
""")