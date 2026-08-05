using Revise
using Sindbad
using Statistics: mean

experiment_json = joinpath(@__DIR__, "experiment.json")

info = getExperimentInfo(experiment_json); # note that this will modify information from json with the replace_info

forcing = getForcing(info);


test_land = info.helpers.land_init;
test_helpers = Sindbad.Simulation.getRunTEMInfo(info, forcing);

test_forcing_pairs = map(enumerate(forcing.f_types)) do (f_index, f)
    f_name = first(f)
    f_type = last(f)
    f_type_name = nameof(typeof(f_type))
    f_value = forcing.data[f_index]
    if f_type_name == :ForcingWithTime
        f_value = mean(f_value)
    end
    Pair(f_name, f_value)
end
test_forcing = (; test_forcing_pairs...)
