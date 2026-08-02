import SindbadTEM.Processes as SM

include("../mock_input/forcing.jl")
include("../mock_input/land.jl")
include("../mock_input/helpers.jl")
# called them as tmp_forcing, tmp_land, tmp_helpers

include("ambientCO2.jl")
include("autoRespiration.jl")