# module TheoryOfGod

# import Main: @install
# @install ConcurrentCollections
using ConcurrentCollections
using Base.Threads
using StaticArrays

include("00101_TheoryOfGod∃.jl")
include("00102_TheoryOfGodGrid.jl")

# const T = Rational{BigInt}
const T = Float64
const GOD = 𝕋{T}()
# ∃!(zero(Ω)), ∃!(one(Ω))
# const Ξ = ConcurrentDict{∃,T}()

# in LoopOS
include("00103_TheoryOfGodgod.jl")
# include("00103_TheoryOfGodTypst.jl")

include("00090_BroadcastBrowser2Module.jl")
import Main.BroadcastBrowserModule: BroadcastBrowser, start
include("00105_TheoryOfGodgodBrowser.jl")
# const BROWSERTASK = Threads.@spawn start(b->godBrowser(b))

# g=collect(values(godBROWSER[]))[1].g
# dimx, dimy, dimc = T(0.1),T(0.2),T(0.3)
# x, y = T(0.1),T(0.1)
# g = god{T}(dimx, dimy, dimc, x, y, T(2^3), T(2^3))
# # dt = 0.01
# # step(g, dt)
# g.ẑero.μ
# pixel = fill((one(T),one(T),one(T),one(T)), g.♯.n[2],g.♯.n[3])
# @time p̂ixel = observe(g)
# δ = Δ(pixel, p̂ixel)
# isempty(δ)
dimx, dimy, dimc = T(0.1),T(0.2),T(0.3)
x, y = T(0.1),T(0.1)
g = god{T}(dimx, dimy, dimc, x, y, T(3), T(3))
N=5
name="circle"
d = g.ẑero.d
μ = SA[zero(T), T(0.1), T(0.1), ○(T), zero(T)]
ρ = SA[zero(T), T(0.1), T(0.1), ○(T), zero(T)]
ϵ=∃{N,T}(GOD,name, d, μ, ρ, ntuple(_->(false,false), 5), (_,_,_)->○(T))
create(g, name, (t, x, y) -> begin
# @show "hi"
    # @show name, t, x, y, x^2 + y^2
    # x^2 + y^2 == 0.01 ? (T(rand()), T(rand()), T(rand()), one(T)) : (○(T), ○(T), ○(T), ○(T))
    # @show name, t, x, y
    T(rand()), T(rand()), T(rand()), one(T)
end,ϵ)
collect(keys(GOD.ϵ̃))
GOD.Ο[GOD]

observe(g)

# end
