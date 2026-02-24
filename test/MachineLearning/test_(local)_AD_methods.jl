using Sindbad
using JLD2
# Loading these enables the extensions for the ML methods, which are tested in this file.
using PreallocationTools, ForwardDiff, Flux, Zygote

file_folds = load("/User/homes/lalonso/SINDBAD/examples/exp_fluxnet_hybrid/sampling/nfolds_sites_indices_0.jld2")
experiment_json = "/User/homes/lalonso/SINDBAD/examples/exp_fluxnet_hybrid/settings_fluxnet_hybrid/experiment.json"


replace_info = Dict()
if Sys.islinux()
    replace_info = Dict(
        "forcing.default_forcing.data_path" => "/Net/Groups/BGI/work_4/scratch/lalonso/FLUXNET_v2023_12_1D.zarr",
        "optimization.observations.default_observation.data_path" =>"/Net/Groups/BGI/work_4/scratch/lalonso/FLUXNET_v2023_12_1D.zarr"
        );
end

info = getExperimentInfo(experiment_json; replace_info=replace_info);
selected_models = info.models.forward;
parameter_scaling_type = info.optimization.run_options.parameter_scaling

## parameters
tbl_params = info.optimization.parameter_table;
param_to_index = getParameterIndices(selected_models, tbl_params);

## forcing and obs
forcing = getForcing(info);
observations = getObservation(info, forcing.helpers);

## helpers
run_helpers = prepTEM(selected_models, forcing, observations, info);

space_forcing = run_helpers.space_forcing;
space_observations = run_helpers.space_observation;
space_output = run_helpers.space_output;
space_spinup_forcing = run_helpers.space_spinup_forcing;
space_ind = run_helpers.space_ind;
land_init = run_helpers.loc_land;
loc_forcing_t = run_helpers.loc_forcing_t;

space_cost_options = [prepCostOptions(loc_obs, info.optimization.cost_options) for loc_obs in space_observations];
constraint_method = info.optimization.run_options.multi_constraint_method;

tem_info = run_helpers.tem_info;

site_example_1 = space_ind[1][1];
@time coreTEM!(selected_models, space_forcing[site_example_1], space_spinup_forcing[site_example_1], loc_forcing_t, space_output[site_example_1], land_init, tem_info)

sites_forcing = forcing.data[1].site; # sites names

# ! selection and batching
_nfold = 5
xtrain, xval, xtest = file_folds["unfold_training"][_nfold], file_folds["unfold_validation"][_nfold], file_folds["unfold_tests"][_nfold]

# ? training
sites_training = sites_forcing[xtrain];
indices_sites_training = siteNameToID.(sites_training, Ref(sites_forcing));
# # ? validation
sites_validation = sites_forcing[xval];
indices_sites_validation = siteNameToID.(sites_validation, Ref(sites_forcing));
# # ? test
sites_testing = sites_forcing[xtest];
indices_sites_testing = siteNameToID.(sites_testing, Ref(sites_forcing));

indices_sites_batch = indices_sites_training;

xfeatures = loadCovariates(sites_forcing; kind="all"); #  cube_path=path_covariates
@info "xfeatures: [$(minimum(xfeatures)), $(maximum(xfeatures))]"

nor_names_order = xfeatures.features;
n_features = length(nor_names_order)

## Build ML method
n_params = sum(tbl_params.is_ml);
nlayers = 3 # Base.parse(Int, ARGS[2])
n_neurons = 32 # Base.parse(Int, ARGS[3])
batch_size = 32 # Base.parse(Int, ARGS[4])
batch_seed = 123 * batch_size * 2
n_epochs = 2
k_σ = 1.f0
# custom_activation = CustomSigmoid(k_σ)
# custom_activation = sigmoid_3
mlBaseline = denseNN(n_features, n_neurons, n_params; extra_hlayers=nlayers, seed=batch_seed);

# Initialize params and grads
params_sites = mlBaseline(xfeatures);
@info "params_sites: [$(minimum(params_sites)), $(maximum(params_sites))]"

grads_batch = zeros(Float32, n_params, length(sites_training))[:,1:batch_size];
sites_batch = sites_training;#[1:n_sites_train];
params_batch = params_sites(; site=sites_batch);
@info "params_batch: [$(minimum(params_batch)), $(maximum(params_batch))]"
scaled_params_batch = getParamsAct(params_batch, tbl_params);
@info "scaled_params_batch: [$(minimum(scaled_params_batch)), $(maximum(scaled_params_batch))]"

forward_args = (
    selected_models,
    space_forcing,
    space_spinup_forcing,
    loc_forcing_t,
    space_output,
    land_init,
    tem_info,
    param_to_index,
    parameter_scaling_type,
    space_observations,
    space_cost_options,
    constraint_method
    );


input_args = (
        scaled_params_batch, 
        forward_args..., 
        indices_sites_batch,
        sites_batch
);

@info "now testing ForwardDiff"
grads_lib = ForwardDiffGrad();
loc_params, inner_args = getInnerArgs(1, grads_lib, input_args...);
# just for one site
@time gg = gradientSite(grads_lib, loc_params, 2, lossSite, inner_args...)
# for a batch
gradientBatch!(grads_lib, grads_batch, 2, lossSite, getInnerArgs,input_args...; showprog=true)

# ! Now other extensions!
@info "now testing PolyesterForwardDiff"
using PreallocationTools # this one gets the diffCache methods
using PolyesterForwardDiff, Flux, Zygote
grads_lib = PolyesterForwardDiffGrad();

loc_params, inner_args = getInnerArgs(1, grads_lib, input_args...);
# just for one site
@time gg = gradientSite(grads_lib, loc_params, 4, lossSite, inner_args...)
# for a batch
gradientBatch!(grads_lib, grads_batch, 4, lossSite, getInnerArgs,input_args...; showprog=true)

# # ! FiniteDifferences

@info "now testing FiniteDifferences"
using FiniteDifferences
grads_lib = FiniteDifferencesGrad();

loc_params, inner_args = getInnerArgs(1, grads_lib, input_args...);
# just for one site
@time gg = gradientSite(grads_lib, loc_params, 4, lossSite, inner_args...)
# for a batch
gradientBatch!(grads_lib, grads_batch, 4, lossSite, getInnerArgs,input_args...; showprog=true)

# ! FiniteDiff
@info "now testing FiniteDiff"
using FiniteDiff
grads_lib = FiniteDiffGrad();

loc_params, inner_args = getInnerArgs(1, grads_lib, input_args...);
# just for one site
@time gg = gradientSite(grads_lib, loc_params, 4, lossSite, inner_args...)
# for a batch
gradientBatch!(grads_lib, grads_batch, 4, lossSite, getInnerArgs,input_args...; showprog=true)