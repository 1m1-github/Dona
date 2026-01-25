module TestModule

using Test
begin
tests = []
for test in tests
    @test f(test[1]...) == test[2]
end
end

end
