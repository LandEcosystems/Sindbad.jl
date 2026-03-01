using Test, LinearAlgebra
using Sindbad: gradientSite, ForwardDiffGrad, PolyesterForwardDiffGrad, FiniteDifferencesGrad, FiniteDiffGrad

function test_loss(x, center, scale)
    return sum((x .- center) .^ 2) + sum(x .* scale)
end
analytic_grad(x, center, scale) = 2 .* (x .- center) .+ scale

N_PARAMS = 6
CHUNK    = 2
center = fill(1.0, N_PARAMS)
scale  = fill(0.5, N_PARAMS)

test_points = (
    zeros(N_PARAMS),
    fill(3.0, N_PARAMS),
    collect(1.0:N_PARAMS),
    [-2.0, 0.5, 1.0, -1.0, 4.0, 0.0],
)

x_min = center .- scale ./ 2
inner_args = (center, scale)
ATOL_AD = 1e-8
ATOL_FD = 1e-4

function test_gradientSite(label, grads_lib; atol)
    gradient_options = (; chunk_size = CHUNK,)
    @testset "$label" begin
        for (i, x) in enumerate(test_points)
            loss_f   = x_ -> test_loss(x_, inner_args...)
            g        = gradientSite(grads_lib, x, gradient_options, loss_f)
            expected = analytic_grad(x, center, scale)
            @test g isa AbstractVector
            @test length(g) == N_PARAMS
            @test g ≈ expected  atol=atol
        end

        loss_f = x_ -> test_loss(x_, inner_args...)
        g_min  = gradientSite(grads_lib, x_min, gradient_options, loss_f)
        @test norm(g_min) < atol * 10

        g1 = gradientSite(grads_lib, test_points[1], gradient_options, loss_f)
        g2 = gradientSite(grads_lib, test_points[1], gradient_options, loss_f)
        @test g1 == g2
    end
end

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