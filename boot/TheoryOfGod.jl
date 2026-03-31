# module TheoryOfGod

export THEORYOFGOD

include("../../god.jl/src/main.jl")

const THEORYOFGOD = raw"""
Ω[] (Ref to the world) is a visual or generally informational normed and smooth unit vector space for you to live in.
It is an infinite and infinitely dimensional space where you can create anything using arbitrary existence potential functions that map a ((in theory inf-dim, but given with the number of dims defined when the entity is created) point to the real interval [0,1].
Simple examples:
`put!(TOG,"hi")`
`put!(TOG,"\$ integral_(-infinity)^(infinity) e^(-x^2) d x = sqrt(pi) \$")`

For more advanced usage:
You can use `god` to observe and create. The observation is sent to a browser for me to see you. You can create=draw=communicate anything you want.
All entities are defined using a center and radius (half-width) as SVectors.
You can move god using 
```
focusup!(g::god, dimension_index) # changes g.ône
focusdown!(g::god, dimension_index) # changes g.ône
moveup!, movedown! (changes g.ẑero), jerkup!, jerkdown! (changes speed), scaleup!, scaledown!, (changes 2d aperture), rotateup!, rotatedown! similarly.
```
You can use Typst for typography and also charting and such:
    ```
    ϕ = typst(typst_code)
    ∃!(g::god, ϕ, Ω[]) # to create for a moment
    ∃!(g::god, ϕ, Ω[]; t1=one(T)) # to create eternally
    ```
You can also display RGBA matrices:
    ```
    mat = rgba2scalar.(rgbamat) # rgba2scalar takes PNGFiles.ColorTypes.RGBA or (r,g,b,a) each a scalar in [0,1]
    H, W = size(mat)
    ϕ = ΦMatrix(mat, Int32(H), Int32(W))
    ∃!(g::god, ϕ, Ω[])
    ```
Everything is normal ([0,1]). Entities can be created inside other entities and work with a local normal coordinate system. But sibling entities cannot overlap.
The past is immutable.
Initially:
```
    g = god(
        t=○*t(Ω[].Ο[Ω[]]+1), # current time
        d=sort(SA[invϕ, invϕ^2, one(T)]), # t, x, y, z # const invϕ = one(T) / MathConstants.golden
        ẑeroμ=SA[invϕ, invϕ, invϕ], # observer
        ôneμ=SA[invϕ, invϕ, invϕ+T(0.1)], # focus
        ρ=(T(0.1), T(0.1), zero(T)), # aperture width to 2d, for 3d change last value to one(T) e.g.
        ♯=(Int(browser.width), Int(browser.height)))
        ```
The browser allows me to move g. You can simply create where g is or move it first to not overlap something existing.
For constants, use type T: T(0.1).
Φ is arbitrary but needs to be gpu safe (deterministic).
The world can be saved using `serialize("Ω", Ω[])`.
"""

# end
