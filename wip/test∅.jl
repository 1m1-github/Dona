using Test

# ∅ returns true if intervals are disjoint (empty intersection)
# Interval 1: [zero₁, one₁] with czero₁ = closed at zero₁, cone₁ = closed at one₁
# Interval 2: [zero₂, one₂] with czero₂ = closed at zero₂, cone₂ = closed at one₂

@testset "Interval Disjointness ∅" begin

    @testset "Clearly Disjoint - gap between intervals" begin
        # [0,1] and [2,3] - all boundary combinations, always disjoint
        for czero₁ in [false, true], cone₁ in [false, true]
            for czero₂ in [false, true], cone₂ in [false, true]
                @test ∅(0, 1, czero₁, cone₁, 2, 3, czero₂, cone₂) == true
                @test ∅(2, 3, czero₂, cone₂, 0, 1, czero₁, cone₁) == true  # symmetry
            end
        end
    end

    @testset "Clearly Overlapping - strict subset" begin
        # [0,10] contains [3,7] strictly - all boundary combinations, never disjoint
        for czero₁ in [false, true], cone₁ in [false, true]
            for czero₂ in [false, true], cone₂ in [false, true]
                @test ∅(0, 10, czero₁, cone₁, 3, 7, czero₂, cone₂) == false
                @test ∅(3, 7, czero₂, cone₂, 0, 10, czero₁, cone₁) == false  # symmetry
            end
        end
    end

    @testset "Partial Overlap - both intersection and non-intersection parts" begin
        # [0,5] and [3,8] overlap in [3,5] - all boundary combinations, never disjoint
        for czero₁ in [false, true], cone₁ in [false, true]
            for czero₂ in [false, true], cone₂ in [false, true]
                @test ∅(0, 5, czero₁, cone₁, 3, 8, czero₂, cone₂) == false
                @test ∅(3, 8, czero₂, cone₂, 0, 5, czero₁, cone₁) == false  # symmetry
            end
        end
    end

    @testset "Non-strict Subset - coinciding at one border" begin
        # [0,5] and [0,3] share left endpoint
        for czero₁ in [false, true], cone₁ in [false, true]
            for czero₂ in [false, true], cone₂ in [false, true]
                @test ∅(0, 5, czero₁, cone₁, 0, 3, czero₂, cone₂) == false
                @test ∅(0, 3, czero₂, cone₂, 0, 5, czero₁, cone₁) == false
            end
        end
        
        # [0,5] and [3,5] share right endpoint
        for czero₁ in [false, true], cone₁ in [false, true]
            for czero₂ in [false, true], cone₂ in [false, true]
                @test ∅(0, 5, czero₁, cone₁, 3, 5, czero₂, cone₂) == false
                @test ∅(3, 5, czero₂, cone₂, 0, 5, czero₁, cone₁) == false
            end
        end
    end

    @testset "Non-strict Subset - coinciding at both borders (identical intervals)" begin
        # [0,5] and [0,5] - identical extent, all boundary combinations
        for czero₁ in [false, true], cone₁ in [false, true]
            for czero₂ in [false, true], cone₂ in [false, true]
                @test ∅(0, 5, czero₁, cone₁, 0, 5, czero₂, cone₂) == false
            end
        end
    end

    @testset "Meeting at Border - critical open/closed cases" begin
        # [0,1] and [1,2] - intervals meet exactly at point 1
        
        # Both closed at meeting point: [0,1] ∩ [1,2] = {1} - NOT disjoint
        @test ∅(0, 1, true, true, 1, 2, true, true) == false
        @test ∅(1, 2, true, true, 0, 1, true, true) == false  # symmetry
        
        # First closed, second open: [0,1] ∩ (1,2] = ∅ - disjoint
        @test ∅(0, 1, true, true, 1, 2, false, true) == true
        @test ∅(1, 2, false, true, 0, 1, true, true) == true
        
        # First open, second closed: [0,1) ∩ [1,2] = ∅ - disjoint
        @test ∅(0, 1, true, false, 1, 2, true, true) == true
        @test ∅(1, 2, true, true, 0, 1, true, false) == true
        
        # Both open at meeting point: [0,1) ∩ (1,2] = ∅ - disjoint
        @test ∅(0, 1, true, false, 1, 2, false, true) == true
        @test ∅(1, 2, false, true, 0, 1, true, false) == true
        
        # Exhaustive: all 16 combinations at meeting point
        # cone₁ and czero₂ determine if they share the point
        for czero₁ in [false, true], cone₁ in [false, true]
            for czero₂ in [false, true], cone₂ in [false, true]
                # Disjoint iff NOT (cone₁ && czero₂)
                expected_disjoint = !(cone₁ && czero₂)
                @test ∅(0, 1, czero₁, cone₁, 1, 2, czero₂, cone₂) == expected_disjoint
            end
        end
    end

    @testset "Meeting at Border - other direction" begin
        # [1,2] and [0,1] - checking the second condition in ∅
        for czero₁ in [false, true], cone₁ in [false, true]
            for czero₂ in [false, true], cone₂ in [false, true]
                # Disjoint iff NOT (cone₂ && czero₁)
                expected_disjoint = !(cone₂ && czero₁)
                @test ∅(1, 2, czero₁, cone₁, 0, 1, czero₂, cone₂) == expected_disjoint
            end
        end
    end

    @testset "Edge Cases" begin
        # Point intervals [a,a] 
        # [1,1] closed and [1,1] closed - same point, not disjoint
        @test ∅(1, 1, true, true, 1, 1, true, true) == false
        
        # [1,1] closed and [2,2] closed - different points, disjoint
        @test ∅(1, 1, true, true, 2, 2, true, true) == true
        
        # [1,1] closed meets [1,2] closed at left - not disjoint
        @test ∅(1, 1, true, true, 1, 2, true, true) == false
        
        # [1,1] closed meets (1,2] open at left - disjoint
        @test ∅(1, 1, true, true, 1, 2, false, true) == true
        
        # Negative numbers
        @test ∅(-5, -1, true, true, 0, 3, true, true) == true  # disjoint
        @test ∅(-5, 1, true, true, -2, 3, true, true) == false  # overlap
        
        # Floating point
        @test ∅(0.0, 1.0, true, true, 1.0, 2.0, true, true) == false  # meet closed
        @test ∅(0.0, 1.0, true, false, 1.0, 2.0, true, true) == true  # meet open
    end

    @testset "Symmetry Property" begin
        # ∅(I₁, I₂) should equal ∅(I₂, I₁) for all cases
        test_cases = [
            (0, 1, 2, 3),   # disjoint
            (0, 10, 3, 7),  # strict subset
            (0, 5, 3, 8),   # partial overlap
            (0, 5, 0, 3),   # shared left
            (0, 5, 3, 5),   # shared right
            (0, 5, 0, 5),   # identical
            (0, 1, 1, 2),   # meeting at border
        ]
        
        for (z1, o1, z2, o2) in test_cases
            for czero₁ in [false, true], cone₁ in [false, true]
                for czero₂ in [false, true], cone₂ in [false, true]
                    result1 = ∅(z1, o1, czero₁, cone₁, z2, o2, czero₂, cone₂)
                    result2 = ∅(z2, o2, czero₂, cone₂, z1, o1, czero₁, cone₁)
                    @test result1 == result2
                end
            end
        end
    end

end