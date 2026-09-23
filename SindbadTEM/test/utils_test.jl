# test utilsCore here
import SindbadTEM.Processes as SM

include("./mock_input/forcing.jl")
include("./mock_input/land.jl")
include("./mock_input/helpers.jl")

@testset "utilsCore: @rep_elem" begin
    helpers = deepcopy(tmp_helpers) # we need a better way, other than enforcing `helpers` as a global variable.
    land = deepcopy(tmp_land)  # copy our tmp_land, we will modify field within.
    @unpack_nt cSoilSlow  ⇐ land.pools # type \Leftarrow <TAB> (REPL) or (Enter to suggestion in editor)
    @rep_elem 100 ⇒ (cSoilSlow, 1, :cSoilSlow) # replace (whole bucket) without mutation and without allocations!
    # type \Leftarrow <TAB> (REPL) or (Enter to suggestion in editor)
    @test cSoilSlow[1] == 100.0

    # this should be simpler! New helpers tuple
    helpers = (; pools =(;
        zeros=(; cOther = 0.0f0,),
        ones = (; cOther = 1.0f0 ))
        )
    cOther = [100.0f0, 1.0f0]
    @rep_elem 1 ⇒ (cOther, 1, :cOther) 
    @rep_elem 100 ⇒ (cOther, 2, :cOther) 
    @test cOther == [1.0f0, 100.0f0]
end

@testset "utilsCore: mutable land packing" begin
    land = (
        diagnostics=(a=1.0f0, b=2.0f0),
        fluxes=(q=3.0f0,),
    )

    a, b = 4.0f0, 5.0f0
    @pack_nt (a, b) ⇒ land.diagnostics
    @test land.diagnostics == (a=4.0f0, b=5.0f0)

    runtime_land = mutable_land(land)
    original_runtime_land = runtime_land
    a, b, q = 6.0f0, 7.0f0, 8.0f0
    @pack_nt begin
        (a, b) ⇒ runtime_land.diagnostics
        q ⇒ runtime_land.fluxes
    end

    @test runtime_land === original_runtime_land
    @test runtime_land.diagnostics.a === 6.0f0
    @test runtime_land.diagnostics.b === 7.0f0
    @test runtime_land.fluxes.q === 8.0f0
    @test propertynames(runtime_land) == (:diagnostics, :fluxes)
end
