export sindbadDefaultOptions

"""
    sindbadDefaultOptions(::MethodType)

Retrieves the default configuration options for a given optimization or sensitivity analysis method in SINDBAD.

# Arguments:
- `::MethodType`: The method type for which the default options are requested. Supported types include:
    - `ParameterOptimizationMethod`: General optimization methods.
    - `GSAMethod`: General global sensitivity analysis methods.
    - `GSAMorris`: Morris method for global sensitivity analysis.
    - `GSASobol`: Sobol method for global sensitivity analysis.
    - `GSASobolDM`: Sobol method with derivative-based measures.
    - `SpinupSequence`: Methods that build the spinup sequence of a location.

# Returns:
- A `NamedTuple` containing the default options for the specified method.

# Notes:
- Each method type has its own set of default options, such as the number of trajectories, samples, or design matrix length.
- For `GSASobolDM`, the defaults are inherited from `GSASobol`.
- Defaults can be given on an abstract type, so that every method below it shares them and only
  the methods that need more define their own. `SpinupSequence` is set up this way.
"""
function sindbadDefaultOptions end
# A basic empty options for all SindbadTypes
sindbadDefaultOptions(::SindbadTypes) = (;)

sindbadDefaultOptions(::CMAEvolutionStrategyCMAES) = (; maxfevals = 50)

sindbadDefaultOptions(::SpinupSequence) = (; n_repeat_base = 200, forcing_msc = "day_MSC")

# invoke reaches the SpinupSequence method above, so this stays the shared defaults plus the
# one option this method adds, rather than a second copy of them
sindbadDefaultOptions(m::SequenceWithAge) = (; invoke(sindbadDefaultOptions, Tuple{SpinupSequence}, m)..., disturbance_variable = "f_dist_year")

sindbadDefaultOptions(::GSAMorris) = (; total_num_trajectory = 200, num_trajectory = 15, len_design_mat=10)

sindbadDefaultOptions(::GSASobol) = (; samples = 5, method_options=(; order=[0, 1]), sampler="Sobol", sampler_options=(;))

sindbadDefaultOptions(::GSASobolDM) = sindbadDefaultOptions(GSASobol())
