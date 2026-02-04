# module TheoryOfGod

# import Main: @install
# @install ConcurrentCollections
using ConcurrentCollections
using Base.Threads

include("00101_TheoryOfGod∃.jl")
include("00102_TheoryOfGodGrid.jl")

# const T = Rational{BigInt}
const T = Float64
const Ω = ∀{T}([])
# const Ξ = ConcurrentDict{∃,T}()
const L = ReentrantLock()

# in LoopOS
include("00103_TheoryOfGodgod.jl")
# include("00103_TheoryOfGodTypst.jl")

include("00090_BroadcastBrowser2Module.jl")
import Main.BroadcastBrowserModule: BroadcastBrowser, start
include("00105_TheoryOfGodgodBrowser.jl")
# const BROWSERTASK = Threads.@spawn start(b->godBrowser(b))

# g=collect(values(godBROWSER[]))[1].g
dimx, dimy, dimc = T(0.1),T(0.2),T(0.3)
x, y = T(0.1),T(0.1)
g = god{T}(dimx, dimy, dimc, x, y, T(5), T(3))
# dt = 0.01
# step(g, dt)
g.ẑero.μ
pixel = fill((one(T),one(T),one(T),one(T)), g.♯.n[2],g.♯.n[3])
@time p̂ixel = observe(g)
δ = Δ(pixel, p̂ixel)
isempty(δ)
name="circle"
create(g, name, (t, x, y) -> begin
    # @show name, t, x, y, x^2 + y^2
    # x^2 + y^2 == 0.01 ? (T(rand()), T(rand()), T(rand()), one(T)) : (○(T), ○(T), ○(T), ○(T))
    @show name, t, x, y
    T(rand()), T(rand()), T(rand()), one(T)
end)
Ω.ϵ[1].μ
Ω.ϵ[1].ρ

# end
