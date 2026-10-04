using Sindbad
using WGLMakie, Bonito

include(joinpath(@__DIR__, "..", "mock_input", "forcing.jl"))
include(joinpath(@__DIR__, "..", "mock_input", "helpers.jl"))
include(joinpath(@__DIR__, "..", "mock_input", "land.jl"))

land_model = WUE_expVPDDayCo2()

app = app_process(
	land_model,
	:compute;
	forcing=tmp_forcing,
	land=tmp_land,
	helpers=tmp_helpers,
)