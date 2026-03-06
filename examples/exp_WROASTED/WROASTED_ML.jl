using Revise
using Sindbad
using CMAEvolutionStrategy
using NetCDF, Statistics, Flux, DataFrames
using YAXArrays
using JLD2
using Plots
# Simulation
# using CairoMakie


toggle_type_abbrev_in_stacktrace()
experiment_json = "/Net/Groups/BGI/scratch/relghawi/Sinbad_test/Sindbad-Dev/settings_WROASTED/experiment.json"
begin_year = "2000"
end_year = "2017"

domain = "DE-Hai"
# domain = "MY-PSO"
path_input = "/Net/Groups/BGI/scratch/relghawi/Sinbad_test/Sindbad-Dev/DE-Hai.1979.2017.daily.nc"
# path_input  = "/Net/Groups/BGI/scratch/skoirala/RnD/SINDBAD-RnD-SK/examples/data/fn/US-SRM.1979.2017.daily.nc"
forcing_config = "/Net/Groups/BGI/scratch/relghawi/Sinbad_test/Sindbad-Dev/settings_WROASTED/forcing_erai.json"

path_observation = path_input
optimize_it = true
# optimize_it = false
path_output = nothing

parallelization_lib = "threads"
model_array_type = "static_array"
replace_info = Dict("experiment.basics.time.date_begin" => begin_year * "-01-01",
    "experiment.basics.config_files.forcing" => forcing_config,
    "experiment.basics.domain" => domain,
    "forcing.default_forcing.data_path" => path_input,
    "experiment.basics.time.date_end" => end_year * "-12-31",
    "experiment.flags.run_optimization" => optimize_it,
    "experiment.flags.calc_cost" => false,
    "experiment.flags.catch_model_errors" => false,
    "experiment.flags.spinup_TEM" => true,
    "experiment.flags.debug_model" => false,
    "experiment.exe_rules.model_array_type" => model_array_type,
    "experiment.model_output.path" => path_output,
    "experiment.model_output.format" => "nc",
    "experiment.model_output.save_single_file" => true,
    "experiment.exe_rules.parallelization" => parallelization_lib,
    "optimization.algorithm_optimization" => "opti_algorithms/CMAEvolutionStrategy_CMAES.json",
    "optimization.observations.default_observation.data_path" => path_observation);

info = getExperimentInfo(experiment_json; replace_info=replace_info); # note that this will modify information from json with the replace_info
forcing = getForcing(info);


# 2. Slice to match your begin_year and end_year
# Sindbad uses 1-based indexing from 1979. 
# It's safer to filter by the length of the 'forcing' object you already created.
ds = open_dataset(path_input)
gpp_yaxa = ds["GPP_NT"]
axes_dict = Dict(forcing.helpers.axes)
target_dates = axes_dict[:time]
gpp_subset = gpp_yaxa[time = At(target_dates)]
gpp_vec = dropdims(gpp_subset.data, dims=(1, 2))

find_idx(name) = findfirst(==(name), forcing.variables)
# 1. Collect your features into a matrix (Features x Time)
X_raw = hcat(
    vec(forcing.data[find_idx(:f_rg)]), 
    vec(forcing.data[find_idx(:f_PAR)]),
    vec(forcing.data[find_idx(:f_airT)]), 
    vec(forcing.data[find_idx(:f_VPD)]), 
    vec(forcing.data[find_idx(:f_ambient_CO2)])
)'
# 2. Remove NaNs (Flux cannot train with them)
# We create a mask for days where GPP is available
# 1. Clean the data using our GPP mask
X_raw_dense = Array(X_raw) 
gpp_vec_dense = Array(gpp_vec)

# 2. Re-run the mask on the dense arrays
mask = .!isnan.(gpp_vec_dense)

# 3. This should now be nearly instantaneous
X_clean = Float32.(X_raw_dense[:, mask])
y_clean = Float32.(reshape(gpp_vec_dense[mask], 1, :))

# Calculate the split point
n_total = size(X_clean, 2)
n_train = Int(floor(0.8 * n_total))

# 1. Split Features (X)
X_train_raw = X_clean[:, 1:n_train]
X_test_raw  = X_clean[:, n_train+1:end]

# 2. Split Targets (y)
y_train = y_clean[:, 1:n_train]
y_test  = y_clean[:, n_train+1:end]

# Calculate stats ONLY on training data
μ_train = mean(X_train_raw, dims=2)
σ_train = std(X_train_raw, dims=2)

# Apply to Training Set
X_train_norm = (X_train_raw .- μ_train) ./ σ_train

# Apply same μ and σ to Test Set (Important!)
X_test_norm = (X_test_raw .- μ_train) ./ σ_train

println("Training on $n_train days. Testing on $(n_total - n_train) days.")

# Model: 5 Inputs -> 64 Neurons -> 32 Neurons -> 1 Output (GPP)
# Define model as before
model = Chain(
    Dense(5, 64, relu),
    Dense(64, 32, relu),
    Dense(32, 1, softplus)
)
opt_state = Flux.setup(Adam(0.001), model)

# Use ONLY training data in the loader
data_loader = Flux.DataLoader((X_train_norm, y_train), batchsize=64, shuffle=true)

# Train...
for epoch in 1:100 # Increased to 100 for better convergence
    Flux.train!(model, data_loader, opt_state) do m, x, y
        loss(m, x, y)
    end
end

# Predict on test set
y_pred_test = model(X_test_norm)

# Calculate Test Correlation
r_test = cor(vec(y_pred_test), vec(y_test))
println("Test Set Correlation (R): ", round(r_test, digits=3))

#Plot the test period
plot(vec(y_test), label="Observed (FLUXNET)", color=:black, alpha=0.6)
plot!(vec(y_pred_test), label="Predicted (NN)", color=:red, linestyle=:dash)
ylabel!("GPP")
title!("Test Set Predictions")

# Save everything to one file
jldsave("/Net/Groups/BGI/scratch/relghawi/Sinbad_test/Sindbad-Dev/dev/Sindbad.jl/examples/exp_WROASTED/gpp_model_v1.jld2"; 
    model_state = Flux.state(model), 
    mu = μ_train, 
    sigma = σ_train
)

println("Model and normalization stats saved to gpp_model_v1.jld2")


### To use model for inference later:
# 1. Re-define the architecture (must be identical)
loaded_model = Chain(
    Dense(5, 64, relu),
    Dense(64, 32, relu),
    Dense(32, 1, softplus)
)

# 2. Load the state and the normalization stats
data = jldopen("/Net/Groups/BGI/scratch/relghawi/Sinbad_test/Sindbad-Dev/dev/Sindbad.jl/examples/exp_WROASTED/gpp_model_v1.jld2", "r")
Flux.loadmodel!(loaded_model, data["model_state"])
μ_saved = data["mu"]
σ_saved = data["sigma"]
close(data)

# 1. Define your current forcing values (Rg, PAR, Tair, VPD, CO2)
# Replace these with your actual daily values from Sindbad
current_forcing = [450.0, 225.0, 18.5, 0.8, 415.0]

# 2. Reshape to a 5x1 Matrix (Flux requirement)
x_raw = Float32.(reshape(current_forcing, 5, 1))

# 3. Normalize using the μ and σ you just loaded
# Math: (Value - Mean) / StdDev
x_norm = (x_raw .- μ_saved) ./ σ_saved

# 4. Get the prediction
# The result is a 1x1 Matrix, so we use [1] to get the number
gpp_pred = loaded_model(x_norm)[1]

println("Predicted GPP: ", gpp_pred, " gC m⁻² d⁻¹")