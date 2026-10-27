using Profile

const EXP_MAIN = "/Net/Groups/BGI/scratch/jzhou/SINDBAD/SINDBAD-EEO/experimental_configuration/SINDBAD_PHS_EEO/experimrntal_configuration/exp_main.jl"
const OPTIMIZATION_CALL = "@time out_opti = runExperimentOpti(experiment_json; replace_info=deepcopy(replace_info));"

function benchmark_body()
    set_log_level(:warn)
    info, forcing = prepExperiment(experiment_json; replace_info=deepcopy(replace_info))
    observations = getObservation(info, forcing.helpers)
    observation_arrays = [Array(observation) for observation in observations.data]
    opti = prepOpti(forcing, observation_arrays, info, info.optimization.run_options.cost_method)
    population_size = info.optimization.optimizer.options.popsize
    parameters = repeat(opti.default_values, 1, population_size)

    evaluate_population() = begin
        costs = zeros(eltype(opti.default_values), population_size)
        Threads.@threads for candidate in 1:population_size
            costs[candidate] = opti.cost_function(@view parameters[:, candidate])
        end
        costs
    end

    println("BENCHMARK threads=$(Threads.nthreads()) population=$population_size parameters=$(length(opti.default_values))")
    println("BENCHMARK warmup")
    evaluate_population()

    GC.gc()
    timed = @timed evaluate_population()
    println("BENCHMARK elapsed=$(timed.time) seconds_per_feval=$(timed.time / population_size) bytes=$(timed.bytes) gctime=$(timed.gctime)")

    Profile.clear()
    Profile.@profile evaluate_population()
    Profile.print(format=:flat, sortedby=:count, mincount=20)
    return nothing
end

source = read(EXP_MAIN, String)
occursin(OPTIMIZATION_CALL, source) || error("Could not locate optimization call in $EXP_MAIN")
source = replace(source, OPTIMIZATION_CALL => "benchmark_body()"; count=1)
include_string(Main, source, EXP_MAIN)
