using Test
using Sindbad
using WGLMakie, Bonito

land_model = WUE_expVPDDayCo2()

app = app_process(land_model, :compute)