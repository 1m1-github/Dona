# module ωModule

mutable struct ω{T<:Real} <: AbstractPeripheral{T}
    # p::Peripheral{T} # t,x,y,h,s,l,a
    # focus::∃{T}
    ♯::Grid
    ẑero::∃{T}
    ône::∃{T}
    v::Tuple{T,T,T} # dt_inner(ẑero)/dt_origin, dx/dt_inner(ẑero), dy/dt_inner(ẑero)
end

# function ω{T}(dimx, dimy, x, y, rx, ry, nx, ny)
function ω{T}(dimx, dimy, x, y, nx, ny)
    maxdim = max(dimx, dimy)
    dimδ = (one(T) - maxdim) / T(5) # hsla+1
    dimh = dimx + dimδ
    dims = dimh + dimδ
    diml = dims + dimδ
    dima = diml + dima
    d = [zero(T), dimx, dimy, dimh, dims, diml, dima]
    μ = [t(Ω), x, y, ○(T), ○(T), ○(T), ○(T)]
    ρ = [zero(T), one(T) - x, one(T) - y, zero(T), zero(T), zero(T)]
    ∂ = fill(true, 2*length(d))
    ẑero = ∃{T}("", d, μ, ρ, ∂, _ -> ○(T), Ω, [])
    ône = ∃{T}("", [zero(T), one(T)], [one(T), one(T)], [zero(T), zero(T)], [true, true, true, true], _ -> ○(T), Ω, [])
    # focus = ∃{T}("", d, μ, ρ, ∂, _ -> ○(T), Ω, [])
    # resolution = [1, nx, ny, 1, 1, 1, 1]
    # p = Peripheral{T}(focus, resolution)
    # ω(p, ône)
    ♯ = Grid([1, nx, ny, 1, 1, 1, 1])
    v = (one(T), zero(T), zero(T))
    ω(♯, ẑero, ône, v)
end
function observe(g::ω)
    ϵ = g.ône - g.ẑero
    pixels = fill((1.0,1.0,1.0,1.0), g.♯[2], g.♯[3])
    for (i, x) = enumerate(∃(g.♯, ϵ))
        h, s, l, a = x[4], x[5], x[6], x[7]
        r, g, b = hsl_to_rgb(h, s, l)
        pixels[i[2], i[3]] = (r, g, b, a)
    end
    pixels
    # ∃ = observe(g.p)
    # h, s, l = ∃[1,:,:,1,1,1]
    # r, g, b = hsl_to_rgb(h, s, l)
end
function create(g::ω, name, ∃̇)
    # x = t,x,y,h,s,l,a
    # h, s, l, a = x[4], x[5], x[6], x[7]
    t, x, y, h, s, l, a = x
    rgb_to_hsl(r, g, b)
    h,s,l = rgb_to_hsl(r,g,b)
    r,g,b,a = ∃̇(x)
    ∃̂(x) = 
    ϵ = g.ône - g.ẑero
    # ϵ = ∃{T}(name, g.p.focus.d, g.p.focus.μ, g.p.focus.ρ, g.p.focus.∂, ∃̇, g.p.focus, [])
    ϵ̂ = ∃{T}(name, ϵ.d, ϵ.μ, ϵ.ρ, ϵ.∂, ∃̂, Ω, [])
    ∃!(ϵ̂)
    # create(g.p, ϵ)
end
accelerate(g::ω, v) = g.v = v
stop(g::ω) = accelerate(g, ntuple(_->zero(g.T),3))
turn(g::ω, ône) = g.ône = ône
scale(g::ω, ♯) = g.♯ = ♯

function Base.(-)(ẑero::∃, ône::∃)
    d̂ = sort(ϵ.d ∪ ϵ̂.d)
    μ = fill(○(T), length(d̂))
    ρ = fill(○(T), length(d̂))
    for (i, d) = enumerate(d̂)
        ẑeroμ, _ = μρ(ẑero, d)
        ôneμ, _ = μρ(ône, d)
        μ[i] = ôneμ - ẑeroμ
        ρ[i] = μ[i] / 2
    end
    ∂ = fill(true, length(d̂))
    ∃("", d, μ, ρ, ∂, _ -> ○(T), Ω, [])
end

# ∇(t_inner) = t_inner*g.ône-(1-t_inner)*g.ẑero
# ∇(0) = g.ẑero
# ∇(1) = g.ône
# t_inner(ẑero), t_origin
# speed = dt_inner(ẑero)/dt_origin, dx/dt_inner(ẑero), dy/dt_inner(ẑero)
# t_inner = 1 - 1/(1+log(C)) = log(C)/(1+log(C))
# dt_inner(ẑero) = speed[1]*dt_origin
function step(g::w, dt̂)
    # t̂ = time()
    # @async while true
        # yield()

        # _t̂ = time()
        # dt̂ = _t̂ - t̂
        # t̂ = _t̂

        dt = g.v[1]*dt̂
        dx = g.v[2]*dt
        dy = g.v[3]*dt

        μ = [g.ẑero.μ[1] + dt, g.ẑero.μ[2] + dx, g.ẑero.μ[3] + dy, ○(T), ○(T), ○(T), ○(T)]
        ρ = [zero(T), one(T) - μ[2], one(T) - μ[3], zero(T), zero(T), zero(T)]
        g.ẑero = ∃{T}("", g.ẑero.d, μ, ρ, g.ẑero.∂, _ -> ○(T), Ω, [])
    # end
end
function hsl_to_rgb(h, s, l)
    c = (1 - abs(2l - 1)) * s
    h′ = h * 6
    x = c * (1 - abs(h′ % 2 - 1))
    r′, g′, b′ = if h′ < 1
        (c, x, 0)
    elseif h′ < 2
        (x, c, 0)
    elseif h′ < 3
        (0, c, x)
    elseif h′ < 4
        (0, x, c)
    elseif h′ < 5
        (x, 0, c)
    else
        (c, 0, x)
    end
    m = l - c/2
    r′ + m, g′ + m, b′ + m
end
function rgb_to_hsl(r, g, b)
    cmax = max(r, g, b)
    cmin = min(r, g, b)
    Δ = cmax - cmin
    
    l = (cmax + cmin) / 2
    
    if Δ == 0
        return (0.5, 0.0, l)  # h undefined, use 0.5 as neutral
    end
    
    s = Δ / (1 - abs(2l - 1))
    
    h′ = if cmax == r
        ((g - b) / Δ) % 6
    elseif cmax == g
        (b - r) / Δ + 2
    else
        (r - g) / Δ + 4
    end
    
    h = h′ / 6
    h = h < 0 ? h + 1 : h  # normalize to [0,1]
    
    h, s, l
end

# end