# test utilsCore here
import SindbadTEM.Processes as SM

include("./mock_input/forcing.jl")
include("./mock_input/land.jl")
include("./mock_input/helpers.jl")

@testset "utilsCore: @rep_elem" begin
    helpers = deepcopy(tmp_helpers) # we need a better way, other than enforcing `helpers` as a global variable.
    land_copy = deepcopy(land)  # copy our land test data, we will modify field within.
    @unpack_nt cSoilSlow  ⇐ land_copy.pools # type \Leftarrow <TAB> (REPL) or (Enter to suggestion in editor)
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