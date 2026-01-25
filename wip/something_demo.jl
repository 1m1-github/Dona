# Something World - End-to-End Demo
# Include the core library first
include("something.jl")

using Printf

# ============================================================
# PERIPHERALS - Projections from n-dim to observable screens
# ============================================================

"""
A Peripheral projects from the infinite-dimensional existence field
onto an observable output (2D screen, 3D volume, audio, etc.)

- observer_position: Dict{T,T} - where the observer is in Ω
- view_dims: which dimensions to project onto screen axes
- screen_resolution: pixels per view dimension
- screen_origin: center of view in each view_dim
- screen_radius: half-width of view in each view_dim
"""
struct Peripheral{T<:Real}
    name::String
    observer_position::Dict{T,T}  # fixed coordinates in non-view dims
    view_dims::Vector{T}          # dims that map to screen axes
    screen_resolution::Vector{Int}
    screen_origin::Vector{T}      # center of view
    screen_radius::Vector{T}      # zoom level
end

"""
Create a 2D screen peripheral.
"""
function Screen2D(T::Type{<:Real}, name::String;
                  observer=nothing,
                  x_dim=nothing, y_dim=nothing,
                  resolution::Tuple{Int,Int}=(64, 64),
                  origin=nothing,
                  radius=nothing)
    obs = observer === nothing ? Dict{T,T}() : observer
    xd = x_dim === nothing ? T(0) : x_dim
    yd = y_dim === nothing ? T(1) : y_dim
    org = origin === nothing ? (T(1//2), T(1//2)) : origin
    rad = radius === nothing ? (T(1//4), T(1//4)) : radius
    Peripheral{T}(
        name,
        obs,
        T[xd, yd],
        [resolution...],
        T[org...],
        T[rad...]
    )
end

"""
Render the view through a peripheral, returning a 2D array of existence values.
"""
function render(p::Peripheral{T}, S::Something{T}=Ω) where {T<:Real}
    # Build grid from peripheral spec
    g = Grid{T}(p.view_dims, p.screen_origin, p.screen_radius, p.screen_resolution)
    
    # For each grid point, merge with observer position
    results = Dict{Vector{Int},Real}()
    for idx in grid_indices(g)
        ω = grid_to_coords(g, collect(idx))
        # Merge observer's fixed position with view coordinates
        for (d, v) in p.observer_position
            if d ∉ p.view_dims
                ω[d] = v
            end
        end
        ∃_val, _, _ = observe(ω, S)
        results[collect(idx)] = Real(∃_val)
    end
    
    grid_to_array(g, results)
end

"""
Convert existence array to ASCII art.
"""
function to_ascii(arr::Array{Real,2}; chars::String=" .:-=+*#%@")
    w, h = size(arr)
    lines = String[]
    for y in h:-1:1  # flip y for natural orientation
        line = ""
        for x in 1:w
            v = clamp(arr[x, y], 0, 1)
            idx = round(Int, v * (length(chars) - 1)) + 1
            line *= chars[idx]
        end
        push!(lines, line)
    end
    join(lines, "\n")
end

"""
Convert existence array to ANSI colored blocks.
"""
function to_ansi(arr::Array{Real,2})
    h, w = size(arr)
    lines = String[]
    for y in h:-1:1
        line = ""
        for x in 1:w
            v = clamp(arr[x, y], 0, 1)
            # Map to grayscale: 232-255 are grays in 256-color mode
            gray = round(Int, v * 23) + 232
            line *= "\e[48;5;$(gray)m  \e[0m"
        end
        push!(lines, line)
    end
    join(lines, "\n")
end

# ============================================================
# PNG/GIF OUTPUT
# ============================================================

"""
Write a minimal PNG file (grayscale, no compression).
Uses raw PNG format with no external dependencies.
"""
function to_png(arr::Array{Real,2}, filename::String; scale::Int=4)
    w, h = size(arr)
    sw, sh = w * scale, h * scale
    
    # PNG signature
    signature = UInt8[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    
    # CRC32 table
    crc_table = zeros(UInt32, 256)
    for i in 0:255
        c = UInt32(i)
        for _ in 1:8
            if (c & 1) != 0
                c = 0xedb88320 ⊻ (c >> 1)
            else
                c >>= 1
            end
        end
        crc_table[i + 1] = c
    end
    
    function crc32(data::Vector{UInt8})
        c = 0xffffffff
        for b in data
            c = crc_table[(c ⊻ b) & 0xff + 1] ⊻ (c >> 8)
        end
        c ⊻ 0xffffffff
    end
    
    function write_chunk(io, chunk_type::String, data::Vector{UInt8})
        len = UInt32(length(data))
        write(io, hton(len))
        type_bytes = Vector{UInt8}(chunk_type)
        write(io, type_bytes)
        write(io, data)
        crc_data = vcat(type_bytes, data)
        write(io, hton(crc32(crc_data)))
    end
    
    # IHDR chunk
    ihdr = IOBuffer()
    write(ihdr, hton(UInt32(sw)))  # width
    write(ihdr, hton(UInt32(sh)))  # height
    write(ihdr, UInt8(8))          # bit depth
    write(ihdr, UInt8(0))          # color type (grayscale)
    write(ihdr, UInt8(0))          # compression
    write(ihdr, UInt8(0))          # filter
    write(ihdr, UInt8(0))          # interlace
    ihdr_data = take!(ihdr)
    
    # Image data (uncompressed via zlib stored block)
    raw_data = IOBuffer()
    for y in sh:-1:1  # flip y
        write(raw_data, UInt8(0))  # filter type: none
        for x in 1:sw
            ox, oy = div(x - 1, scale) + 1, div(y - 1, scale) + 1
            v = clamp(arr[ox, oy], 0, 1)
            gray = round(UInt8, v * 255)
            write(raw_data, gray)
        end
    end
    raw_bytes = take!(raw_data)
    
    # Wrap in zlib format (stored blocks, no compression)
    zlib_data = IOBuffer()
    write(zlib_data, UInt8(0x78), UInt8(0x01))  # zlib header (no compression)
    
    # Split into 65535-byte blocks
    pos = 1
    while pos <= length(raw_bytes)
        block_end = min(pos + 65534, length(raw_bytes))
        block = raw_bytes[pos:block_end]
        is_final = block_end >= length(raw_bytes)
        write(zlib_data, UInt8(is_final ? 0x01 : 0x00))  # final flag
        len = UInt16(length(block))
        write(zlib_data, len)           # length (little endian)
        write(zlib_data, ~len)          # one's complement
        write(zlib_data, block)
        pos = block_end + 1
    end
    
    # Adler-32 checksum
    a, b = UInt32(1), UInt32(0)
    for byte in raw_bytes
        a = (a + byte) % 65521
        b = (b + a) % 65521
    end
    adler = (b << 16) | a
    write(zlib_data, hton(adler))
    
    idat_data = take!(zlib_data)
    
    # Write PNG file
    open(filename, "w") do io
        write(io, signature)
        write_chunk(io, "IHDR", ihdr_data)
        write_chunk(io, "IDAT", idat_data)
        write_chunk(io, "IEND", UInt8[])
    end
    
    filename
end

"""
Create an animated GIF from multiple frames.
Uses minimal LZW (no compression, just literal codes).
"""
function to_gif(frames::Vector{<:Array{Real,2}}, filename::String; 
                scale::Int=4, delay::Int=20)
    if isempty(frames)
        error("No frames provided")
    end
    
    w, h = size(frames[1])
    sw, sh = w * scale, h * scale
    
    open(filename, "w") do io
        # GIF89a header
        write(io, "GIF89a")
        
        # Logical screen descriptor
        write(io, UInt16(sw))  # width (little endian)
        write(io, UInt16(sh))  # height
        write(io, UInt8(0xF7)) # global color table, 8 bits, 256 colors
        write(io, UInt8(0))    # background color index
        write(io, UInt8(0))    # pixel aspect ratio
        
        # Global color table (256 grays)
        for i in 0:255
            write(io, UInt8(i), UInt8(i), UInt8(i))
        end
        
        # Netscape extension for looping
        write(io, UInt8(0x21), UInt8(0xFF), UInt8(0x0B))
        write(io, "NETSCAPE2.0")
        write(io, UInt8(0x03), UInt8(0x01))
        write(io, UInt16(0))  # loop forever
        write(io, UInt8(0))   # block terminator
        
        for arr in frames
            # Graphics control extension (for delay)
            write(io, UInt8(0x21), UInt8(0xF9), UInt8(0x04))
            write(io, UInt8(0x00))        # no transparency
            write(io, UInt16(delay))      # delay in 1/100 sec
            write(io, UInt8(0), UInt8(0)) # transparent color, terminator
            
            # Image descriptor
            write(io, UInt8(0x2C))
            write(io, UInt16(0), UInt16(0))  # left, top
            write(io, UInt16(sw), UInt16(sh)) # width, height
            write(io, UInt8(0))               # no local color table
            
            # LZW minimum code size
            min_code_size = 8
            write(io, UInt8(min_code_size))
            
            # Build pixel data
            pixels = UInt8[]
            for y in 1:sh
                for x in 1:sw
                    ox = div(x - 1, scale) + 1
                    oy = div(y - 1, scale) + 1
                    v = clamp(arr[ox, oy], 0, 1)
                    push!(pixels, round(UInt8, v * 255))
                end
            end
            
            # Simple LZW encoding with frequent clears to avoid complexity
            clear_code = 256
            eoi_code = 257
            
            output_bytes = UInt8[]
            bit_buffer = UInt32(0)
            bits_in_buffer = 0
            code_size = 9
            
            function emit_code(code)
                bit_buffer |= UInt32(code) << bits_in_buffer
                bits_in_buffer += code_size
                while bits_in_buffer >= 8
                    push!(output_bytes, UInt8(bit_buffer & 0xFF))
                    bit_buffer >>= 8
                    bits_in_buffer -= 8
                end
            end
            
            emit_code(clear_code)
            
            # Emit pixels with periodic clears (simple, no dictionary building)
            count = 0
            for pixel in pixels
                emit_code(Int(pixel))
                count += 1
                if count >= 100  # clear frequently to keep code_size at 9
                    emit_code(clear_code)
                    count = 0
                end
            end
            
            emit_code(eoi_code)
            
            # Flush remaining bits
            if bits_in_buffer > 0
                push!(output_bytes, UInt8(bit_buffer & 0xFF))
            end
            
            # Write in sub-blocks (max 255 bytes each)
            pos = 1
            while pos <= length(output_bytes)
                block_size = min(255, length(output_bytes) - pos + 1)
                write(io, UInt8(block_size))
                write(io, output_bytes[pos:pos+block_size-1])
                pos += block_size
            end
            write(io, UInt8(0))  # block terminator
        end
        
        # GIF trailer
        write(io, UInt8(0x3B))
    end
    
    filename
end

"""
Render multiple time slices as frames for animation.
"""
function render_animation(p::Peripheral{T}, time_dim::T, time_values::Vector{T}, 
                          S::Something{T}=Ω) where {T<:Real}
    frames = Array{Real,2}[]
    for t in time_values
        # Set time in observer position
        obs = copy(p.observer_position)
        obs[time_dim] = t
        p_frame = Peripheral{T}(p.name, obs, p.view_dims, p.screen_resolution, 
                                 p.screen_origin, p.screen_radius)
        empty!(CACHE)
        push!(frames, render(p_frame, S))
    end
    frames
end

# ============================================================
# DEMO 1: Static 2D Art - A Circle
# ============================================================

println("\n" * "="^60)
println("DEMO 1: Static Circle in 2D")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create a circular region: existence = 1 inside, fades at edge
    # Circle at center (1/2, 1/2), radius 1/5 in dims 0,1
    circle = create("circle", 
        T[1//2, 1//2],           # origin
        T[1//5, 1//5],           # radius
        T[0, 1],                 # dims x, y
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r_max = 0.2
            r < r_max * 0.8 ? 1.0 : 0.5  # solid inside, ORIGIN at boundary
        end
    )
    
    # Create peripheral: 2D screen looking at x,y
    screen = Screen2D(T, "main_view",
        resolution=(32, 32),
        origin=(T(1//2), T(1//2)),
        radius=(T(1//3), T(1//3))
    )
    
    img = render(screen)
    println("\nCircle (existence = 1.0 inside, 0.5 outside):")
    println(to_ascii(img))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 2: Nested Structures - Ball with Hidden Room
# ============================================================

println("\n" * "="^60)
println("DEMO 2: Bowling Ball with Hidden Jacuzzi")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # The bowling ball: visible in dims 0,1 (x,y)
    # Solid existence = 0.9
    ball = create("bowling_ball",
        T[1//2, 1//2],
        T[1//5, 1//5],
        T[0, 1],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.15 ? 0.9 : 0.5  # dark solid ball
        end
    )
    
    # The hidden jacuzzi: same x,y center, but shifted in dim 2 (z)
    # z = 0.75 with radius 0.1 means bounds [0.65, 0.85] - excludes ORIGIN (0.5)
    jacuzzi = create("jacuzzi",
        T[1//2, 1//2, 3//4],     # same x,y but z=0.75
        T[1//10, 1//10, 1//10],  # radius 0.1 in z: [0.65, 0.85]
        T[0, 1, 2],              # lives in x,y,z
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.08 ? 1.0 : 0.5  # bright jacuzzi!
        end
    )
    
    println("Ball created: ", ball !== nothing)
    println("Jacuzzi created: ", jacuzzi !== nothing)
    
    # Observer 1: Normal view (z = 0.5 = ORIGIN)
    # Can only see the bowling ball
    screen_normal = Peripheral{T}(
        "normal_observer",
        Dict{T,T}(T(2) => T(1//2)),  # z at ORIGIN
        T[0, 1],
        [32, 32],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    # Observer 2: Secret view (z = 0.75)
    # Can see the jacuzzi!
    screen_secret = Peripheral{T}(
        "secret_observer",
        Dict{T,T}(T(2) => T(3//4)),  # z at 0.75
        T[0, 1],
        [32, 32],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    println("\nNormal view (z=0.5) - just the bowling ball:")
    img_normal = render(screen_normal)
    println(to_ascii(img_normal))
    
    println("\nSecret view (z=0.75) - the hidden jacuzzi inside!")
    empty!(CACHE)
    img_secret = render(screen_secret)
    println(to_ascii(img_secret))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 3: Time Dimension - Animation
# ============================================================

println("\n" * "="^60)
println("DEMO 3: Moving Ball (time dimension)")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # A ball that moves in x as t increases
    # At t=0.3: ball at x=0.3
    # At t=0.5: ball at x=0.5
    # At t=0.7: ball at x=0.7
    # The trick: ball's x-position is tied to t
    
    # We create multiple balls at different t-slices
    for (i, t) in enumerate([3//10, 4//10, 5//10, 6//10, 7//10])
        x_pos = t  # ball moves with time
        ball = create("ball_t$i",
            T[x_pos, 1//2, t],      # x follows t, y=center, t=specific
            T[1//20, 1//10, 1//100], # small in x,y, very thin in t
            T[0, 1, 2],             # dims: x, y, t
            _ -> 0.95
        )
    end
    
    println("\nFrames of animation (t = 0.3, 0.4, 0.5, 0.6, 0.7):\n")
    
    for t in [3//10, 4//10, 5//10, 6//10, 7//10]
        screen = Peripheral{T}(
            "frame_t=$t",
            Dict{T,T}(T(2) => T(t)),  # fix time
            T[0, 1],                   # view x,y
            [40, 16],
            T[1//2, 1//2],
            T[1//2, 1//4]
        )
        empty!(CACHE)
        img = render(screen)
        println("t = $t:")
        println(to_ascii(img, chars=" .o"))
        println()
    end
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 4: Different Physics - Gravity Subspace
# ============================================================

println("\n" * "="^60)
println("DEMO 4: Subspace with Different Physics")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create a "gravity zone" - existence increases downward (higher y = less existence)
    gravity_zone = create("gravity_zone",
        T[1//2, 1//2],
        T[2//5, 2//5],
        T[0, 1],
        ω -> begin
            y = Float64(get_dim(ω, T(1)))
            # Gravity: existence higher at bottom
            0.5 + 0.4 * (1.0 - y)  # varies from 0.9 at bottom to 0.5 at top
        end
    )
    
    # Create a "floating zone" inside - reversed physics!
    # Must be in different dim to be disjoint
    floating_zone = create("floating_zone",
        T[1//2, 1//2, 1//5],      # shift in z to be disjoint
        T[1//5, 1//5, 1//10],
        T[0, 1, 2],
        ω -> begin
            y = Float64(get_dim(ω, T(1)))
            # Anti-gravity: existence higher at top
            0.5 + 0.4 * y
        end
    )
    
    println("\nGravity zone (brighter at bottom, observer at z=0.5):")
    screen_gravity = Peripheral{T}(
        "gravity_view",
        Dict{T,T}(T(2) => T(1//2)),
        T[0, 1],
        [32, 16],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    img_gravity = render(screen_gravity)
    println(to_ascii(img_gravity))
    
    println("\nFloating zone (brighter at top, observer at z=0.2):")
    screen_floating = Peripheral{T}(
        "floating_view",
        Dict{T,T}(T(2) => T(1//5)),
        T[0, 1],
        [32, 16],
        T[1//2, 1//2],
        T[1//5, 1//5]
    )
    empty!(CACHE)
    img_floating = render(screen_floating)
    println(to_ascii(img_floating))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 5: God's Eye View - Observing from Different Angles
# ============================================================

println("\n" * "="^60)
println("DEMO 5: Same Structure, Different Projections")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create a 3D cross shape
    # Vertical bar in y
    create("cross_vertical",
        T[1//2, 1//2, 1//5],
        T[1//20, 1//5, 1//10],
        T[0, 1, 2],
        _ -> 0.9
    )
    
    # Horizontal bar in x
    create("cross_horizontal",
        T[1//2, 1//2, 3//10],    # different z to be disjoint
        T[1//5, 1//20, 1//10],
        T[0, 1, 2],
        _ -> 0.9
    )
    
    # View from front (x,y plane, z=0.2)
    println("\nFront view (x,y at z=0.2) - sees vertical bar:")
    screen_front = Peripheral{T}("front", Dict{T,T}(T(2) => T(1//5)), T[0, 1], [24, 24], T[1//2, 1//2], T[1//4, 1//4])
    println(to_ascii(render(screen_front)))
    
    # View at z=0.3 - sees horizontal bar
    println("\nFront view (x,y at z=0.3) - sees horizontal bar:")
    empty!(CACHE)
    screen_front2 = Peripheral{T}("front2", Dict{T,T}(T(2) => T(3//10)), T[0, 1], [24, 24], T[1//2, 1//2], T[1//4, 1//4])
    println(to_ascii(render(screen_front2)))
    
    # Side view (y,z plane, x=0.5)
    println("\nSide view (y,z at x=0.5) - sees both bars as dots:")
    empty!(CACHE)
    screen_side = Peripheral{T}("side", Dict{T,T}(T(0) => T(1//2)), T[1, 2], [24, 24], T[1//2, 1//4], T[1//4, 1//6])
    println(to_ascii(render(screen_side)))
    
    empty!(Ω.children)
end

# ============================================================
# DEMO 6: The Multiverse - Same Location, Different Dimensions
# ============================================================

println("\n" * "="^60)
println("DEMO 6: Parallel Worlds at Same x,y")
println("="^60)

let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # World 1: A house (at dimension 3 = 0.2)
    create("house_floor",
        T[1//2, 3//10, 1//5],
        T[1//5, 1//20, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    create("house_roof",
        T[1//2, 13//20, 3//10],   # different dim 3 to be disjoint
        T[1//6, 1//10, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    
    # World 2: An ocean (at dimension 3 = 0.8)
    create("ocean",
        T[1//2, 3//10, 4//5],
        T[2//5, 1//10, 1//10],
        T[0, 1, 3],
        ω -> begin
            x = Float64(get_dim(ω, T(0)))
            0.6 + 0.1 * sin(x * 20)  # waves
        end
    )
    
    # God at dimension 3 = 0.2 sees a house
    println("\nWorld 1 (dim3=0.2) - The House:")
    screen_house = Peripheral{T}("house_world", Dict{T,T}(T(3) => T(1//5)), T[0, 1], [32, 20], T[1//2, 1//2], T[1//3, 1//3])
    println(to_ascii(render(screen_house)))
    
    # God at dimension 3 = 0.8 sees an ocean
    println("\nWorld 2 (dim3=0.8) - The Ocean:")
    empty!(CACHE)
    screen_ocean = Peripheral{T}("ocean_world", Dict{T,T}(T(3) => T(4//5)), T[0, 1], [32, 20], T[1//2, 1//2], T[1//3, 1//3])
    println(to_ascii(render(screen_ocean)))
    
    println("\nSame x,y coordinates, completely different realities!")
    println("Move in dimension 3 to travel between worlds.")
    
    empty!(Ω.children)
end

# ============================================================
println("\n" * "="^60)
println("END OF ASCII DEMOS")
println("="^60)

# ============================================================
# IMAGE OUTPUT DEMOS
# ============================================================

println("\n" * "="^60)
println("GENERATING PNG AND GIF FILES")
println("="^60)

# Demo: Circle as PNG
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    circle = create("circle", 
        T[1//2, 1//2],
        T[1//5, 1//5],
        T[0, 1],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r_max = 0.2
            r < r_max * 0.8 ? 1.0 : 0.5
        end
    )
    
    screen = Screen2D(T, "circle_view",
        resolution=(64, 64),
        origin=(T(1//2), T(1//2)),
        radius=(T(1//3), T(1//3))
    )
    
    img = render(screen)
    to_png(img, "circle.png", scale=4)
    println("✓ Saved circle.png")
    
    empty!(Ω.children)
end

# Demo: Bowling ball and jacuzzi as PNGs
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    ball = create("bowling_ball",
        T[1//2, 1//2],
        T[1//5, 1//5],
        T[0, 1],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.15 ? 0.9 : 0.5
        end
    )
    
    jacuzzi = create("jacuzzi",
        T[1//2, 1//2, 3//4],
        T[1//10, 1//10, 1//10],
        T[0, 1, 2],
        ω -> begin
            x = Float64(get_dim(ω, T(0)) - T(1//2))
            y = Float64(get_dim(ω, T(1)) - T(1//2))
            r = sqrt(x^2 + y^2)
            r < 0.08 ? 1.0 : 0.5
        end
    )
    
    println("Ball created: ", ball !== nothing)
    println("Jacuzzi created: ", jacuzzi !== nothing)
    if jacuzzi !== nothing
        println("Jacuzzi parent: ", jacuzzi.parent.name)
    end
    
    # Normal view
    screen_normal = Peripheral{T}(
        "normal_observer",
        Dict{T,T}(T(2) => T(1//2)),
        T[0, 1],
        [64, 64],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    img_normal = render(screen_normal)
    to_png(img_normal, "ball_normal.png", scale=4)
    println("✓ Saved ball_normal.png (z=0.5, sees ball)")
    
    # Secret view
    screen_secret = Peripheral{T}(
        "secret_observer",
        Dict{T,T}(T(2) => T(3//4)),
        T[0, 1],
        [64, 64],
        T[1//2, 1//2],
        T[1//3, 1//3]
    )
    
    empty!(CACHE)
    img_secret = render(screen_secret)
    to_png(img_secret, "ball_secret.png", scale=4)
    println("✓ Saved ball_secret.png (z=0.75, sees jacuzzi)")
    
    empty!(Ω.children)
end

# Demo: Animated moving ball as GIF
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create balls at different time slices
    for (i, t) in enumerate([2//10, 3//10, 4//10, 5//10, 6//10, 7//10, 8//10])
        x_pos = t
        create("ball_t$i",
            T[x_pos, 1//2, t],
            T[1//20, 1//10, 1//100],
            T[0, 1, 2],
            _ -> 1.0
        )
    end
    
    # Render animation
    screen = Peripheral{T}(
        "animation",
        Dict{T,T}(),
        T[0, 1],
        [64, 32],
        T[1//2, 1//2],
        T[1//2, 1//4]
    )
    
    time_values = T[2//10, 3//10, 4//10, 5//10, 6//10, 7//10, 8//10]
    frames = render_animation(screen, T(2), time_values)
    
    to_gif(frames, "moving_ball.gif", scale=4, delay=15)
    println("✓ Saved moving_ball.gif")
    
    empty!(Ω.children)
end

# Demo: Parallel worlds as PNGs
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # World 1: House
    create("house_floor",
        T[1//2, 3//10, 1//5],
        T[1//5, 1//20, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    create("house_roof",
        T[1//2, 13//20, 3//10],
        T[1//6, 1//10, 1//10],
        T[0, 1, 3],
        _ -> 0.85
    )
    
    # World 2: Ocean with waves
    create("ocean",
        T[1//2, 3//10, 4//5],
        T[2//5, 1//10, 1//10],
        T[0, 1, 3],
        ω -> begin
            x = Float64(get_dim(ω, T(0)))
            0.6 + 0.3 * sin(x * 30)
        end
    )
    
    # House world
    screen_house = Peripheral{T}("house", Dict{T,T}(T(3) => T(1//5)), T[0, 1], 
                                  [64, 48], T[1//2, 1//2], T[1//3, 1//3])
    img_house = render(screen_house)
    to_png(img_house, "world_house.png", scale=4)
    println("✓ Saved world_house.png (dim3=0.2)")
    
    # Ocean world
    empty!(CACHE)
    screen_ocean = Peripheral{T}("ocean", Dict{T,T}(T(3) => T(4//5)), T[0, 1],
                                  [64, 48], T[1//2, 1//2], T[1//3, 1//3])
    img_ocean = render(screen_ocean)
    to_png(img_ocean, "world_ocean.png", scale=4)
    println("✓ Saved world_ocean.png (dim3=0.8)")
    
    empty!(Ω.children)
end

# Demo: Pulsing object (animated)
let T = Rational{BigInt}
    empty!(Ω.children)
    empty!(CACHE)
    
    # Create pulsing circles at different times
    for (i, t) in enumerate(0:1//20:19//20)
        # Radius varies with time: oscillates between 0.05 and 0.15
        phase = Float64(t) * 2 * π
        r = 0.1 + 0.05 * sin(phase * 2)
        
        create("pulse_t$i",
            T[1//2, 1//2, t],
            T[Rational{BigInt}(r), Rational{BigInt}(r), 1//100],
            T[0, 1, 2],
            _ -> 0.9
        )
    end
    
    screen = Peripheral{T}(
        "pulse",
        Dict{T,T}(),
        T[0, 1],
        [64, 64],
        T[1//2, 1//2],
        T[1//4, 1//4]
    )
    
    time_values = collect(T(0):T(1//20):T(19//20))
    frames = render_animation(screen, T(2), time_values)
    
    to_gif(frames, "pulsing.gif", scale=4, delay=5)
    println("✓ Saved pulsing.gif")
    
    empty!(Ω.children)
end

println("\n" * "="^60)
println("ALL FILES GENERATED")
println("="^60)
println("""

Generated files:
  - circle.png         : Static circle
  - ball_normal.png    : Bowling ball (normal view)
  - ball_secret.png    : Hidden jacuzzi inside ball
  - moving_ball.gif    : Ball moving through time
  - world_house.png    : House in dimension 3 = 0.2
  - world_ocean.png    : Ocean in dimension 3 = 0.8
  - pulsing.gif        : Pulsing circle animation

""")
