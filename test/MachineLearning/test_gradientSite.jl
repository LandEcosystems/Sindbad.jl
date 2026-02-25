"""
Simple tests for gradientSite across ForwardDiff, PolyesterForwardDiff, FiniteDifferences, and FiniteDiff backends.
"""
using Test, LinearAlgebra
using Sindbad: gradientSite, ForwardDiffGrad, PolyesterForwardDiffGrad, FiniteDifferencesGrad, FiniteDiffGrad

# ! Setup for gradientBatch tests
# Quadratic loss: sum((x .- center).^2) + dot(x, scale)
# Analytic gradient at x: 2*(x .- center) + scale
function test_loss(x, grads_lib, center, scale)
    return sum((x .- center) .^ 2) + sum(x .* scale)
end

analytic_grad(x, center, scale) = 2 .* (x .- center) .+ scale

N_PARAMS = 6
CHUNK    = 2

center = fill(1.0, N_PARAMS)
scale  = fill(0.5, N_PARAMS)

# Several distinct test points — makes it obvious gradients are actually computed
test_points = (
    zeros(N_PARAMS),                       # all zeros
    fill(3.0, N_PARAMS),                   # far from centre
    collect(1.0:N_PARAMS),                 # linearly spaced, asymmetric
    [-2.0, 0.5, 1.0, -1.0, 4.0, 0.0],      # mixed signs
)
x_min = center .- scale ./ 2               # analytic minimiser: grad == 0

inner_args = (center, scale)

ATOL_AD = 1e-8
ATOL_FD = 1e-4

# helper function to operate on different backends, with the same inner_args.
function test_gradientSite(label, grads_lib; atol)
    @testset "$label" begin

        # correct gradient at each test point
        for (i, x) in enumerate(test_points)
            g        = gradientSite(grads_lib, x, CHUNK, test_loss, inner_args...)
            expected = analytic_grad(x, center, scale)
            # @show g
            # @show expected
            @test g isa AbstractVector
            @test length(g) == N_PARAMS
            @test g ≈ expected  atol=atol
        end

        # near-zero gradient at the analytic minimiser
        g_min = gradientSite(grads_lib, x_min, CHUNK, test_loss, inner_args...)
        @test norm(g_min) < atol * 10

        # two calls return equal but distinct arrays (no aliasing)
        g1 = gradientSite(grads_lib, test_points[1], CHUNK, test_loss, inner_args...)
        g2 = gradientSite(grads_lib, test_points[1], CHUNK, test_loss, inner_args...)
        @test g1 == g2
    end
end

# Run all backends
@testset "gradientSite" begin

    test_gradientSite("ForwardDiff", ForwardDiffGrad(); atol=ATOL_AD)
    
    @testset "PolyesterForwardDiff" begin
        if Sys.islinux()
            using PreallocationTools, PolyesterForwardDiff
            test_gradientSite("PolyesterForwardDiff", PolyesterForwardDiffGrad(); atol=ATOL_AD)
        else
            @info "PolyesterForwardDiff tests skipped on non-Linux platform"
        end
    end

    @testset "FiniteDifferences" begin
        using FiniteDifferences
        test_gradientSite("FiniteDifferences", FiniteDifferencesGrad(); atol=ATOL_FD)
    end

    @testset "FiniteDiff" begin
        using FiniteDiff
        test_gradientSite("FiniteDiff", FiniteDiffGrad(); atol=ATOL_FD)
    end

end