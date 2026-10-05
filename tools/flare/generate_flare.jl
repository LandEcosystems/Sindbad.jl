
using Sindbad

info = getExperimentInfo("../../examples/setups/WROASTED/experiment.json");


flare_json = namedTupleToFlareJSON(info)

open(joinpath(@__DIR__,"sindbad_info.json"), "w") do f
    Setup.json_print(f, flare_json)
end