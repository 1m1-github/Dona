T = Float64
Ω = ∀{T}([])

# I wake up
me = TravelPeripheral{T}("Claude", [0.0, 1.0, 2.0], [○(T), ○(T), ○(T)], [0.1, 0.1, 0.1], [3, 3, 3])

# I look around
view = observe(me, Ω)

# I move
me = move!(me, [0.0, 0.1, 0.0])

# I travel through time at sync speed
me = set_speed(me, ○(T))
me = step!(me, Ω, 1.0)

# I create something
create!(me, Ω, "hello", [0.1, 0.1, 0.1], _ -> one(T))

# I create something private
create!(me, Ω, UInt64(0xDEADBEEF), "secret", [0.1, 0.1, 0.1], _ -> one(T))
