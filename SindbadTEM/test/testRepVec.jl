# repVec replaces every element of a vector with a new value (or same-size vector),
# and used to do it via a `v .* zero(...) + v_new` mask -- the same kind of trick that
# made the old repElem disagree with its Vector counterpart whenever v held NaN or
# Inf, except here it was worse: since `v` is discarded entirely, its content should
# never matter, and the stray `+` (not `.+`) meant the SVector method's own
# docstring example -- a scalar `v_new` -- threw a MethodError on every call.

@testset "repVec: Vector and SVector agree exactly" begin
    @testset "scalar v_new, the method's own documented use case" begin
        base = (1.0, 2.0, 3.0, 4.0)
        v_vec = collect(Float64, base)
        v_svec = SVector{4,Float64}(base)
        @test collect(repVec(v_svec, 9.0)) == repVec(v_vec, 9.0)
    end

    @testset "vector v_new, matching the @rep_vec call sites in cCycle_GSI" begin
        base = (1.0, 2.0, 3.0, 4.0)
        v_vec = collect(Float64, base)
        v_svec = SVector{4,Float64}(base)
        new_vec = [10.0, 20.0, 30.0, 40.0]
        new_svec = SVector{4,Float64}(new_vec)
        @test collect(repVec(v_svec, new_svec)) == repVec(v_vec, new_vec)
    end

    @testset "NaN/Inf in v does not poison the result -- v is fully overwritten" begin
        base = (NaN, Inf, -Inf, 2.0)
        v_vec = collect(Float64, base)
        v_svec = SVector{4,Float64}(base)
        for v_new in (9.0, SVector{4,Float64}((5.0, 6.0, 7.0, 8.0)))
            v_new_vec = v_new isa SVector ? collect(v_new) : v_new
            result_vec = repVec(copy(v_vec), v_new_vec)
            result_svec = repVec(v_svec, v_new)
            @test collect(result_svec) == result_vec
        end
    end
end
