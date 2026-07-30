using Sindbad;
using CMAEvolutionStrategy; # required: the CMAES optimizer used by both setups' optimization.json
                            # is implemented in a package extension that only activates once
                            # CMAEvolutionStrategy is also loaded in this session.

# --------------------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------------------
# `setup`      : "LUE" or "WROASTED" -- which examples/setups/<setup> to run.
# `mode`       : :pixel   -- optimize a single site; `forcing.subset.site` is a 1-element vector.
#                :spatial -- optimize all sites jointly; `forcing.subset.site` is a vector of every index.
# `site_index` : which site to use when `mode == :pixel` (1..205).
setup = "LUE";
mode = :pixel;
site_index = 1;

n_sites = 205;
subset_site = mode == :pixel ? [site_index] : collect(1:n_sites);

experiment_json = joinpath(@__DIR__, "..", "setups", setup, "experiment.json");
output_path = joinpath(@__DIR__, "..", "output_$(setup)_optimization_$(mode)");

# The setups' forcing.json/optimization.json already point `data_path` at the shared
# S3-hosted synthetic_data_examples.zarr, so no override is needed here.
replace_info = Dict{String,Any}(
    "forcing.subset.site" => subset_site,
    "experiment.model_output.path" => output_path,
    # optimization mode: run the optimizer, skip the plain forward/cost-only paths
    # (this is what `runExperimentOpti` sets for you via the internal `setExperimentMode!`)
    "experiment.flags.run_optimization" => true,
    "experiment.flags.calc_cost" => false,
    "experiment.flags.run_forward" => false,
);

# --------------------------------------------------------------------------------------
# Run, one building block at a time
#
# This mirrors what `runExperimentOpti` (src/Experiment/runExperiment.jl) does internally,
# minus the final forward-with-optimized-parameters pass and loss table. Writing it out like
# this -- rather than hiding it behind a helper -- means every intermediate object (`info`,
# `forcing`, `observations`, ...) stays around afterwards, so you can run this file one line
# at a time in the REPL and inspect any of them.
# --------------------------------------------------------------------------------------
info, forcing = prepExperiment(experiment_json; replace_info=replace_info); # == getExperimentInfo(...) + getForcing(info)
observations = getObservation(info, forcing.helpers); # loads the observational_constraints listed in optimization.json

# SINDBAD's forcing cube always keeps a `site` dimension here (even a 1-element one, since
# `subset_site` is a vector, not a scalar index), so both `mode`s optimize as one joint domain
# via `optimizeTEM`. (SINDBAD can also dispatch to a lazy per-pixel `optimizeTEMYax` path when a
# forcing source has no spatial dimension at all -- left out here, handled in a separate PR.)
obs_array = [Array(_o) for _o in observations.data];
optim_result = optimizeTEM(forcing, obs_array, info);

# Equivalent one-liner -- also runs a forward pass with the optimized parameters afterward and
# prints a default-vs-optimized loss table:
# out_opti = runExperimentOpti(experiment_json; replace_info=replace_info, log_level=:info);
