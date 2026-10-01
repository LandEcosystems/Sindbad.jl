using Test
using Sindbad

@testset "Site soil geometry and validation" begin
    boundaries = [0.05, 0.20, 0.50, 1.00, 2.00, 5.00, 10.00]
    layers, depth = Sindbad.Setup.siteSoilLayerThicknesses(0.7, boundaries)
    @test layers ≈ [50, 150, 300, 200]
    @test depth == 0.7
    @test Sindbad.Setup.siteSoilLayerThicknesses(0.02, boundaries)[1] ≈ [50]
    @test Sindbad.Setup.siteSoilLayerThicknesses(0.5, boundaries)[1] ≈ [50, 150, 300]
    @test sum(Sindbad.Setup.siteSoilLayerThicknesses(12.0, boundaries)[1]) ≈ 12000
    for value in (missing, nothing, NaN, Inf, -1, 0, 9999)
        @test !Sindbad.Setup.validSiteSoilDepth(value)
        @test_throws ArgumentError Sindbad.Setup.siteSoilLayerThicknesses(value, boundaries)
    end
    for invalid in ([], [0.0], [0.2, 0.1], [0.1, 0.1], [NaN])
        @test_throws ArgumentError Sindbad.Setup.siteSoilLayerThicknesses(1.0, invalid)
    end
    @test_throws ArgumentError setSiteSoilLayers((;), (;))
    info = (; setup_input=(;))
    @test_throws ArgumentError setSiteSoilLayers(info, (;); initial_water_mm=-1)
    @test_throws ArgumentError setSiteSoilLayers(info,
        (; helpers=(; axes=[:site => ["DE-Hai", "CA-Obs"]])))
end
