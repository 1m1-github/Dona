# Fractal in Something space
# A Sierpinski-like triangle that exists at multiple scales

include("something.jl")
include("something_demo.jl")  # for to_gif, render, Peripheral

# ============================================================
# SIERPINSKI TRIANGLE via nested Somethings
# ============================================================

function create_sierpinski(depth::Int, T::Type{<:Real}=Rational{BigInt})
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create triangular regions recursively
    # Each level: 3 triangles at corners of parent
    
    function add_triangle(name, cx, cy, r, level)
        level > depth && return
        
        # Create this triangle (approximated as small square for simplicity)
        create(name,
            T[cx, cy],
            T[r, r],
            T[0, 1],
            ω -> begin
                x = Float64(get_dim(ω, T(0)) - cx)
                y = Float64(get_dim(ω, T(1)) - cy)
                rf = Float64(r)
                # Triangle: y < r - |x| * (r/r) scaled
                if abs(x) < rf && y > -rf && y < rf - abs(x) * 1.5
                    0.9
                else
                    0.5
                end
            end
        )
        
        # Recurse: three sub-triangles
        nr = r / 2
        # Bottom left
        add_triangle(name * "L", cx - r/2, cy - r/2, nr, level + 1)
        # Bottom right  
        add_triangle(name * "R", cx + r/2, cy - r/2, nr, level + 1)
        # Top
        add_triangle(name * "T", cx, cy + r/2, nr, level + 1)
    end
    
    add_triangle("S", T(1//2), T(1//2), T(1//4), 0)
end

# ============================================================
# MANDELBROT-LIKE via existence function
# ============================================================

function create_mandelbrot(T::Type{<:Real}=Rational{BigInt})
    empty!(Ω.children)
    empty!(CACHE)
    
    create("mandelbrot",
        T[1//2, 1//2],
        T[1//2, 1//2],  # full space
        T[0, 1],
        ω -> begin
            # Map [0,1] to [-2,1] for x and [-1.5,1.5] for y
            px = Float64(get_dim(ω, T(0)))
            py = Float64(get_dim(ω, T(1)))
            
            x0 = px * 3.0 - 2.0  # [-2, 1]
            y0 = py * 3.0 - 1.5  # [-1.5, 1.5]
            
            x, y = 0.0, 0.0
            iter = 0
            max_iter = 50
            
            while x*x + y*y <= 4 && iter < max_iter
                x, y = x*x - y*y + x0, 2*x*y + y0
                iter += 1
            end
            
            # Map iterations to existence
            0.5 + 0.5 * (iter / max_iter)
        end
    )
end

# ============================================================
# JULIA SET with animation (varying c parameter over time)
# ============================================================

function create_julia_animated(T::Type{<:Real}=Rational{BigInt})
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create Julia sets at different time slices
    # c parameter varies with time dimension
    
    n_frames = 30
    for i in 0:n_frames-1
        t = T(i) / T(n_frames)
        
        # c traces a circle in complex plane
        θ = Float64(t) * 2 * π
        c_re = 0.7885 * cos(θ)
        c_im = 0.7885 * sin(θ)
        
        create("julia_t$i",
            T[1//2, 1//2, t],
            T[1//2, 1//2, 1//(2*n_frames)],  # thin time slice
            T[0, 1, 2],
            ω -> begin
                px = Float64(get_dim(ω, T(0)))
                py = Float64(get_dim(ω, T(1)))
                
                # Map to [-1.5, 1.5]
                x = px * 3.0 - 1.5
                y = py * 3.0 - 1.5
                
                iter = 0
                max_iter = 40
                
                while x*x + y*y <= 4 && iter < max_iter
                    x, y = x*x - y*y + c_re, 2*x*y + c_im
                    iter += 1
                end
                
                0.5 + 0.4 * (iter / max_iter)
            end
        )
    end
    
    n_frames
end

# ============================================================
# RENDER AND SAVE
# ============================================================

println("Creating Mandelbrot set...")
create_mandelbrot(Rational{BigInt})

screen = Peripheral{Rational{BigInt}}(
    "mandelbrot_view",
    Dict{Rational{BigInt},Rational{BigInt}}(),
    Rational{BigInt}[0, 1],
    [128, 128],
    Rational{BigInt}[1//2, 1//2],
    Rational{BigInt}[1//2, 1//2]
)

img = render(screen)
to_png(img, "mandelbrot.png", scale=4)
println("✓ Saved mandelbrot.png")

# ============================================================

println("\nCreating animated Julia set...")
T = Rational{BigInt}
n_frames = create_julia_animated(T)

# Render each time slice
frames = Array{Real,2}[]
for i in 0:n_frames-1
    t = T(i) / T(n_frames)
    
    screen = Peripheral{T}(
        "julia_frame",
        Dict{T,T}(T(2) => t + T(1)//(T(4)*T(n_frames))),  # center of time slice
        T[0, 1],
        [100, 100],
        T[1//2, 1//2],
        T[1//2, 1//2]
    )
    
    empty!(CACHE)
    push!(frames, render(screen))
    print(".")
end
println()

to_gif(frames, "julia_animated.gif", scale=4, delay=8)
println("✓ Saved julia_animated.gif")

# ============================================================

println("\nCreating Sierpinski triangle...")
create_sierpinski(4, Rational{BigInt})

screen = Peripheral{Rational{BigInt}}(
    "sierpinski_view",
    Dict{Rational{BigInt},Rational{BigInt}}(),
    Rational{BigInt}[0, 1],
    [128, 128],
    Rational{BigInt}[1//2, 1//2],
    Rational{BigInt}[1//3, 1//3]
)

empty!(CACHE)
img = render(screen)
to_png(img, "sierpinski.png", scale=4)
println("✓ Saved sierpinski.png")

# ============================================================

println("\nCreating zoom animation into Mandelbrot...")
create_mandelbrot(Rational{BigInt})

# Zoom into an interesting point
zoom_frames = Array{Real,2}[]
center_x = Rational{BigInt}(3//10)  # interesting region
center_y = Rational{BigInt}(1//2)
n_zoom = 40

for i in 0:n_zoom-1
    # Exponential zoom
    scale = Rational{BigInt}(1//2) * (Rational{BigInt}(9//10) ^ i)
    
    screen = Peripheral{Rational{BigInt}}(
        "zoom_frame",
        Dict{Rational{BigInt},Rational{BigInt}}(),
        Rational{BigInt}[0, 1],
        [100, 100],
        Rational{BigInt}[center_x, center_y],
        Rational{BigInt}[scale, scale]
    )
    
    empty!(CACHE)
    push!(zoom_frames, render(screen))
    print(".")
end
println()

to_gif(zoom_frames, "mandelbrot_zoom.gif", scale=4, delay=10)
println("✓ Saved mandelbrot_zoom.gif")

# ============================================================

println("\n" * "="^50)
println("All fractals generated!")
println("="^50)
println("""
Files:
  - mandelbrot.png       : Static Mandelbrot set
  - sierpinski.png       : Sierpinski triangle (depth 4)
  - julia_animated.gif   : Julia set with rotating c parameter
  - mandelbrot_zoom.gif  : Zoom into Mandelbrot set
""")
