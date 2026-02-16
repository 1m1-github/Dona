const DH_G = UInt(5)  # generator
const DH_N = UInt(2147483647)  # large prime
privateA = UInt(1)
privateB = UInt(2)
publicA = dh(privateA, DH_G, DH_N)
publicB = dh(privateB, DH_G, DH_N)
sharedAB = ⚷⚷(privateA, publicB)
sharedBA = ⚷⚷(privateB, publicA)
sharedAB == sharedBA

grid = UInt.([1 2 3;
        4 5 6;
        7 8 9])
♯ = size(grid)
for i = CartesianIndices(grid)
    i = Tuple(i)
    @assert i == i⚷(⚷i(i, sharedAB, ♯), sharedAB, ♯)
end
