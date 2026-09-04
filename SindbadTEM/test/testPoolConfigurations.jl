# Pool configurations and flow edges.  The load-bearing check here is that the traits
# are asked with the type of a *constructed* approach, not with the bare name.
# `poolConfiguration(::Type{cCycleBase_GSI})` matches only the UnionAll, so an
# instance's parameterized type falls through to the default and every approach
# silently reports "no configuration" and "no edges" -- which is how the generated
# transfer matrix first came out empty. Testing through `typeof(Approach())` is what
# catches that.

@testset "pool configurations" begin
    P = SindbadTEM.Processes
    edge_counts = Dict(
        P.cCycleBase_GSI => 11,
        P.cCycleBase_GSI_PlantForm => 11,
        P.cCycleBase_GSI_PlantForm_MGMT => 11,
        P.cCycleBase_CASA => 22,
    )

    @testset "traits resolve through a constructed instance" begin
        for (approach, n_edges) in edge_counts
            instance_type = typeof(approach())
            @test poolConfiguration(instance_type) !== nothing
            @test poolConfiguration(instance_type) === poolConfiguration(approach)
            @test length(P.cFlowEdges(instance_type)) == n_edges
            @test P.cFlowEdges(instance_type) === P.cFlowEdges(approach)
        end
    end

    # the same depth-first, prefix-accumulating flattening setPoolsInfo applies,
    # inlined because it lives in Sindbad.Setup and SindbadTEM does not depend on
    # Sindbad
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

    @testset "every edge names a leaf pool of its own configuration" begin
        for approach in keys(edge_counts)
            configuration = poolConfiguration(approach)
            structure = poolStructure(configuration)
            leaves = Set(leafNames(structure.components))
            for edge in P.cFlowEdges(approach)
                @test first(edge) ∈ leaves
                @test last(edge) ∈ leaves
            end
        end
    end

    @testset "aliases are declared only where nesting cannot express them" begin
        @test isempty(poolAliases(P.CarbonPoolsGSI))
        @test isempty(poolAliases(P.CarbonPoolsMGMT))
        @test propertynames(poolAliases(P.CarbonPoolsCASA)) == (:cLitFast, :cLitSlow)
    end

    # Enumerated rather than listed, so a configuration added as a new file in
    # poolConfigurations/ is covered from the moment it is included. The three known
    # ones are asserted to be among them, so an enumeration that silently returns
    # nothing cannot pass these vacuously.
    configurations = SindbadTEM.subtypes(P.CarbonPoolConfiguration)

    @testset "every configuration is discoverable and declares a structure" begin
        for known in (P.CarbonPoolsCASA, P.CarbonPoolsGSI, P.CarbonPoolsMGMT)
            @test known ∈ configurations
        end
        for configuration in configurations
            @test poolStructure(configuration) !== nothing
            @test hasproperty(poolStructure(configuration), :components)
        end
    end

    @testset "configurations are not approaches" begin
        # approach enumeration is driven by these two, in five separate places
        for configuration in configurations
            @test !(configuration <: LandEcosystem)
            @test configuration ∉ SindbadTEM.subtypes(P.cCycleBase)
        end
    end

    # An alias is an extra name for pools that already exist, so it must not shadow a
    # pool the structure generates -- that would put two meanings on one zix entry.
    # The pool name skeleton setPoolsInfo derives unions the two, which is where such a
    # collision would silently disappear. Tested here rather than there because
    # carbonPoolNames lives in Sindbad.Setup and SindbadTEM does not depend on Sindbad.
    @testset "no alias shadows a generated pool name" begin
        for configuration in configurations
            leaves = Set(leafNames(poolStructure(configuration).components))
            for alias in propertynames(poolAliases(configuration))
                @test alias ∉ leaves
            end
        end
    end
end

# The flow matrix, and the [taker, giver] convention it and every dense flow array in
# the models share. Before the edge list there was no way to assert that a dense array
# agreed with the topology, which is how the c_flow_ME_array that cMicrobialEfficiency
# used to carry came to have its coarse-root and wood columns transposed.
@testset "carbon flow matrix" begin
    P = SindbadTEM.Processes
    edge_counts = Dict(
        P.cCycleBase_GSI => 11,
        P.cCycleBase_GSI_PlantForm => 11,
        P.cCycleBase_GSI_PlantForm_MGMT => 11,
        P.cCycleBase_CASA => 22,
    )

    # the same depth-first, prefix-accumulating flattening setPoolsInfo applies, and the
    # same one the testset above inlines. Every carbon pool is a single layer, so a leaf's
    # position in this list is its cEco index.
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

    poolNamesOf(approach) = Tuple(leafNames(poolStructure(poolConfiguration(approach)).components))

    @testset "shape, and every flow index exactly once" begin
        for (approach, n_edges) in edge_counts
            pool_names = poolNamesOf(approach)
            flow_matrix = cFlowMatrix(approach, pool_names)
            @test size(flow_matrix) == (length(pool_names), length(pool_names))
            @test count(!iszero, flow_matrix) == n_edges
            @test sort(filter(!iszero, vec(flow_matrix))) == collect(1:n_edges)
        end
    end

    # Flow k is the kth pair in (giver, taker) order, which is what cFlowStructure sorts
    # by and what c_flow_A_vec, c_flow_QP_vec, c_flow_ME_vec and the d_cFlow output
    # dimension are all indexed by. Declaration order is deliberately not it.
    @testset "flows are numbered in (giver, taker) order" begin
        pool_names = poolNamesOf(P.cCycleBase_GSI)
        ix(name) = findfirst(==(name), pool_names)
        flow_matrix = cFlowMatrix(P.cCycleBase_GSI, pool_names)
        @test flow_matrix[ix(:cVegReserve), ix(:cVegRoot)] == 1
        @test flow_matrix[ix(:cLitFast), ix(:cVegRoot)] == 2
        @test flow_matrix[ix(:cSoilOld), ix(:cSoilSlow)] == 11
    end

    # Row is the taker, column is the giver. An edge naming a group or a pool the
    # structure lacks is rejected rather than silently expanded.
    @testset "orientation and rejected edges" begin
        pool_names = poolNamesOf(P.cCycleBase_CASA)
        ix(name) = findfirst(==(name), pool_names)
        flow_matrix = cFlowMatrix(P.cCycleBase_CASA, pool_names)
        edges = P.cFlowEdges(P.cCycleBase_CASA)
        for edge in edges
            @test flow_matrix[ix(last(edge)), ix(first(edge))] != 0
        end
        # the transpose is a different matrix, so the orientation is not a free choice.
        # Asserted on the one-way edges only: CASA also has reciprocal pairs, such as
        # cMicSoil <-> cSoilSlow, whose reverse cell is filled by its own flow.
        for edge in edges
            (last(edge) => first(edge)) ∈ edges && continue
            @test flow_matrix[ix(first(edge)), ix(last(edge))] == 0
        end
        @test flow_matrix[ix(:cLitLeafFast), ix(:cVegLeaf)] != 0
        @test flow_matrix[ix(:cVegLeaf), ix(:cLitLeafFast)] == 0
        # the two methods agree
        givers = [ix(first(e)) for e in edges]
        takers = [ix(last(e)) for e in edges]
        order = sortperm(collect(zip(givers, takers)))
        @test cFlowMatrix(givers[order], takers[order], length(pool_names)) == flow_matrix
        # a name the structure does not have
        @test_throws ErrorException cFlowMatrix(P.cCycleBase_GSI, poolNamesOf(P.cCycleBase_CASA))
    end
end
