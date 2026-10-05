include(joinpath(@__DIR__, "..", "..", "tools", "benchmark", "TestSindbadTEM", "scanApproachVariables.jl"))

@testset "Test data coverage: every approach's inputs are present" verbose = true begin
    missing = missingTestDataVariables(leafSubtypes(LandEcosystem), tmp_forcing, land, tmp_helpers)

    # `land` and `helpers` are known-noisy: `land` is the minimal, pre-processing land (most
    # namespaces start empty, so many `:input` land reads are "missing" simply because they
    # haven't been populated yet at this point in the sequence -- see missingTestDataVariables's
    # own docstring), and the `helpers.pools` heuristic only strips a leading `Δ`, so ordinary
    # `_prev`/`zero...`-style land.pools fields (not real pools) show up as false positives.
    # `forcing` doesn't have either problem -- its shape is fixed for the whole sequence -- so
    # it's the one category worth hard-failing on.
    if !isempty(missing.land) || !isempty(missing.helpers)
        @warn "Test data coverage scan flagged land/helpers variables -- treat as a rough signal, not a hard failure (see missingTestDataVariables docstring); run tools/benchmark/TestSindbadTEM/scanApproachVariables.jl for the full report" missing.land missing.helpers
    end

    if !isempty(missing.forcing)
        @error "Test data is missing forcing variables that some approach reads -- regenerate via tools/benchmark/TestSindbadTEM/derive_sindbadTEM_test_data.jl or edit tools/benchmark/TestSindbadTEM/forcing.json, then run tools/benchmark/TestSindbadTEM/scanApproachVariables.jl for the full report" missing.forcing
    end

    @test isempty(missing.forcing)
end
