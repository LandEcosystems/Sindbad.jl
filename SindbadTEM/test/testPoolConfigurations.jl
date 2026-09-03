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

    @testset "configurations are not approaches" begin
        # approach enumeration is driven by these two, in five separate places
        for configuration in (P.CarbonPoolsCASA, P.CarbonPoolsGSI, P.CarbonPoolsMGMT)
            @test !(configuration <: LandEcosystem)
            @test configuration ∉ SindbadTEM.subtypes(P.cCycleBase)
        end
    end
end
