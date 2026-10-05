# cQualityPartition's giver/taker split groups are derived from the resolved flow
# topology by pool-naming convention (`deriveQPGroups`, in
# cCycleBase/poolConfigurations/poolConfigurations.jl) rather than declared per pool
# configuration. This checks that derivation directly against both CASA's and GSI's
# real topology, the way testPoolConfigurations.jl's "microbial efficiency group
# coverage" testset checks cMicrobialEfficiency's groups against the same topologies.
#
# The GSI case is the regression test for a real bug the derivation fixes: the old,
# name-matched `QP_CSOIL_GROUPS = ((:cSoilSlow_to_cSoilOld, :cSoilSlow_to_cMicSoil),)`
# was written for CASA, but `cSoilSlow_to_cSoilOld` also exists under GSI (GSI's only,
# single outflow of `cSoilSlow`, since GSI has no `cMicSoil` pool). Matching that name
# alone overwrote a single-outflow edge with a fraction meant for a real two-way split,
# breaking mass conservation. Deriving from the whole pattern -- both sides of a split
# must exist -- resolves GSI's `cSoil` group to empty instead.
@testset "cQualityPartition group derivation" begin
    P = SindbadTEM.Processes

    function leafNames(components, prefix="")
        names = Symbol[]
        for name in propertynames(components)
            value = getproperty(components, name)
            if isa(value, NamedTuple)
                append!(names, leafNames(value, prefix * String(name)))
            else
                push!(names, Symbol(prefix * String(name)))
            end
        end
        return names
    end

    # (c_giver, c_taker, pool_names) for one cCycleBase approach's real topology
    function flowArrays(approach)
        pool_names = Tuple(leafNames(poolStructure(poolConfiguration(approach)).components))
        n_pools = length(pool_names)
        flow_matrix = cFlowMatrix(approach, pool_names)
        n_flows = maximum(flow_matrix)
        givers = zeros(Int, n_flows)
        takers = zeros(Int, n_flows)
        for taker in 1:n_pools, giver in 1:n_pools
            flow_matrix[taker, giver] == 0 && continue
            givers[flow_matrix[taker, giver]] = giver
            takers[flow_matrix[taker, giver]] = taker
        end
        return Tuple(givers), Tuple(takers), pool_names
    end

    namesAt(pool_names, positions) = Set(pool_names[p] for p in positions)

    @testset "CASA: reproduces the five original hardcoded groups exactly" begin
        givers, takers, pool_names = flowArrays(P.cCycleBase_CASA)
        groups = P.deriveQPGroups(givers, takers, pool_names)

        # position => giver_to_taker name, for assertions only -- deriveQPGroups
        # itself never builds a structure like this, and neither does anything else
        # in production any more (see setFlowValue/edgesBetween, landUtils.jl).
        edge_name(flow) = Symbol(String(pool_names[givers[flow]]) * "_to_" * String(pool_names[takers[flow]]))
        edgePositions(edge) = Set(flow for flow in eachindex(givers, takers) if edge_name(flow) == edge)

        # cVeg: (fast, slow) pairs for cVegLeaf and cVegRootFine
        @test length(groups.cVeg) == 2
        for (fast_positions, slow_positions) in groups.cVeg
            fast_set, slow_set = Set(fast_positions), Set(slow_positions)
            if fast_set == edgePositions(:cVegLeaf_to_cLitLeafFast)
                @test slow_set == edgePositions(:cVegLeaf_to_cLitLeafSlow)
            elseif fast_set == edgePositions(:cVegRootFine_to_cLitRootFineFast)
                @test slow_set == edgePositions(:cVegRootFine_to_cLitRootFineSlow)
            else
                @test false # unexpected cVeg group
            end
        end

        # cLit: structural (LeafSlow, RootFineSlow) vs wood (Wood, RootCoarse)
        @test length(groups.cLit.structural) == 2
        @test length(groups.cLit.wood) == 2
        for (soil_positions, mic_positions) in groups.cLit.structural
            soil_set, mic_set = Set(soil_positions), Set(mic_positions)
            if soil_set == edgePositions(:cLitLeafSlow_to_cSoilSlow)
                @test mic_set == edgePositions(:cLitLeafSlow_to_cMicSurf)
            elseif soil_set == edgePositions(:cLitRootFineSlow_to_cSoilSlow)
                @test mic_set == edgePositions(:cLitRootFineSlow_to_cMicSoil)
            else
                @test false # unexpected cLit.structural group
            end
        end
        for (soil_positions, mic_positions) in groups.cLit.wood
            soil_set, mic_set = Set(soil_positions), Set(mic_positions)
            if soil_set == edgePositions(:cLitWood_to_cSoilSlow)
                @test mic_set == edgePositions(:cLitWood_to_cMicSurf)
            elseif soil_set == edgePositions(:cLitRootCoarse_to_cSoilSlow)
                @test mic_set == edgePositions(:cLitRootCoarse_to_cMicSoil)
            else
                @test false # unexpected cLit.wood group
            end
        end

        # cMic: cMicSoil's (stabilized, other) pair
        @test length(groups.cMic) == 1
        (stabilized_positions, other_positions) = only(groups.cMic)
        @test Set(stabilized_positions) == edgePositions(:cMicSoil_to_cSoilOld)
        @test Set(other_positions) == edgePositions(:cMicSoil_to_cSoilSlow)

        # cSoil: cSoilSlow's (stabilized, other) pair
        @test length(groups.cSoil) == 1
        (stabilized_positions, other_positions) = only(groups.cSoil)
        @test Set(stabilized_positions) == edgePositions(:cSoilSlow_to_cSoilOld)
        @test Set(other_positions) == edgePositions(:cSoilSlow_to_cMicSoil)
    end

    @testset "GSI: every field resolves empty, including cSoil" begin
        givers, takers, pool_names = flowArrays(P.cCycleBase_GSI)
        groups = P.deriveQPGroups(givers, takers, pool_names)

        @test isempty(groups.cVeg)
        @test isempty(groups.cLit.structural)
        @test isempty(groups.cLit.wood)
        @test isempty(groups.cMic)
        # Regression test: cSoilSlow's single outflow to cSoilOld must not be treated
        # as one side of a split -- there is no complementary edge to divide against.
        @test isempty(groups.cSoil)
    end
end
