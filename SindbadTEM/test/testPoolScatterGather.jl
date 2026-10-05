# setComponentFromMainPool / setMainFromComponentPool generate the scatter of a
# combined pool into its components and the matching gather back. Both went a long
# time with no caller and no test, and both drifted into calling a `rep_elem` that
# does not exist. These tests exist so that cannot happen silently again: they run
# the generated code rather than just checking it compiles.  Uses `land` and
# `tmp_helpers` from test_data, loaded by runtests.jl.

@testset "pool scatter/gather" begin
    vals = tmp_helpers.pools.vals

    # distinct values, so a misplaced index shows up as a wrong number rather than a
    # coincidence
    cEco_in = SVector{8,Float64}((11.0, 22.0, 33.0, 44.0, 55.0, 66.0, 77.0, 88.0))
    land_in = (; land..., pools=(; land.pools..., cEco=cEco_in))

    scattered = setComponentFromMainPool(land_in, tmp_helpers,
        vals.self.cEco, vals.all_components.cEco, vals.zix.cEco)

    @testset "scatter into components" begin
        @test scattered.pools.cVeg == SVector{4,Float64}((11.0, 22.0, 33.0, 44.0))
        @test scattered.pools.cLit == SVector{2,Float64}((55.0, 66.0))
        @test scattered.pools.cSoil == SVector{2,Float64}((77.0, 88.0))
        @test scattered.pools.cVegRoot == SVector{1,Float64}((11.0,))
        @test scattered.pools.cVegWood == SVector{1,Float64}((22.0,))
        @test scattered.pools.cSoilOld == SVector{1,Float64}((88.0,))
    end

    @testset "gather back into the main pool" begin
        # zero cEco first, so a gather that did nothing at all would fail rather than
        # pass
        zeroed = (; scattered..., pools=(; scattered.pools..., cEco=zero(cEco_in)))
        gathered = setMainFromComponentPool(zeroed, tmp_helpers,
            vals.self.cEco, vals.all_components.cEco, vals.zix.cEco)
        @test gathered.pools.cEco == cEco_in

        # and a changed component has to reach its own slot of cEco
        changed = (; gathered..., pools=(; gathered.pools..., cVegLeaf=SVector{1,Float64}((999.0,))))
        regathered = setMainFromComponentPool(changed, tmp_helpers,
            vals.self.cEco, vals.all_components.cEco, vals.zix.cEco)
        @test regathered.pools.cEco[3] == 999.0
    end
end
