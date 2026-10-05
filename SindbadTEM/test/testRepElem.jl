# repElem has two independent implementations -- in-place mutation for
# AbstractVector, and a per-element tuple rebuild for SVector, needed because
# StaticArrays are immutable. This test isolates the call and checks the two methods
# agree exactly, element for element, not just approximately.

@testset "repElem: Vector and SVector agree exactly" begin
    callRepElem(v, elem, i) = repElem(v, elem, i)

    @testset "replacing each position of a plain vector" begin
        base = [1.0, 2.0, 3.0, 4.0, 5.0]
        for i in eachindex(base)
            v_vec = copy(base)
            v_svec = SVector{5,Float64}(base)
            elem = 100.0 + i

            result_vec = callRepElem(v_vec, elem, i)
            result_svec = callRepElem(v_svec, elem, i)

            @test result_vec isa Vector{Float64}
            @test result_svec isa SVector{5,Float64}
            @test collect(result_svec) == result_vec
        end
    end

    @testset "values that stress floating point arithmetic" begin
        base = (-3.5, 0.0, 1e10, -1e-10, 42.0)
        for i in eachindex(base)
            v_vec = collect(Float64, base)
            v_svec = SVector{5,Float64}(base)
            for elem in (0.0, -0.0, 1e300, -7.25, base[i])
                result_vec = callRepElem(v_vec, elem, i)
                result_svec = callRepElem(SVector{5,Float64}(base), elem, i)
                @test collect(result_svec) == result_vec
            end
        end
    end

    @testset "NaN and Inf pass through unchanged at untouched positions" begin
        base = (NaN, Inf, -Inf, 2.0)
        for i in eachindex(base)
            v_vec = collect(Float64, base)
            v_svec = SVector{4,Float64}(base)
            elem = 9.0
            result_vec = callRepElem(v_vec, elem, i)
            result_svec = callRepElem(v_svec, elem, i)
            # NaN != NaN, so compare bit patterns instead of `==`
            @test length(result_vec) == length(result_svec)
            for k in eachindex(result_vec)
                @test isequal(result_vec[k], result_svec[k])
            end
        end
    end

    @testset "single-element and boundary indices" begin
        v_vec = [7.0]
        v_svec = SVector{1,Float64}((7.0,))
        @test collect(callRepElem(v_svec, 3.0, 1)) == callRepElem(v_vec, 3.0, 1)

        base = ntuple(Float64, 6)
        v_vec = collect(Float64, base)
        v_svec = SVector{6,Float64}(base)
        for i in (1, 6)
            @test collect(callRepElem(v_svec, -1.0, i)) == callRepElem(copy(v_vec), -1.0, i)
        end
    end

    @testset "matches the actual call site: reusing lignin fraction across a real-sized vector" begin
        # mirrors cQualityPartitioncLit_vegQualityTraits.jl: replace several positions
        # in sequence with the same scalar, as the structural/wood loops do
        n = 8
        base = ntuple(_ -> 1.0, n)
        elem = 0.35
        positions = (2, 5, 7)

        v_vec = collect(Float64, base)
        v_svec = SVector{n,Float64}(base)
        for i in positions
            v_vec = callRepElem(v_vec, elem, i)
            v_svec = callRepElem(v_svec, elem, i)
        end
        @test collect(v_svec) == v_vec
    end
end
