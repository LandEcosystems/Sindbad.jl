using Test
using Sindbad
using GLMakie

land_model = WUE_expVPDDayCo2()

with_theme(theme_minimal()) do 
   fig, param_sliders, input_sliders, output_labels = dash_plot(land_model, :compute)
    fig 
end
