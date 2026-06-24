using Test
using Sindbad
using GLMakie

land_model = WUE_expVPDDayCo2()

fig, sliders_params = dash_plot(land_model)
fig

getInOutModel(land_model, :compute)