# module TheoryOfGod

# import Main: @install
# @install ConcurrentCollections
using ConcurrentCollections
using Base.Threads

include("00101_TheoryOfGod∃.jl")
include("00102_TheoryOfGodPeripheral.jl")
# include("00102_TheoryOfGodTravelPeripheral.jl")
# include("00103_TheoryOfGodUtils.jl")

const T = Rational{BigInt}
const Ω = ∀{T}([])
const Ξ = ConcurrentDict{∃,T}()
const L = ReentrantLock()

# end
