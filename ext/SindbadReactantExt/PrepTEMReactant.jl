# Bring the target function into scope for adding methods. This should be done using `import` and not `using`.
import Sindbad.Simulation: helpPrepTEM

# get all the types needed to dispatch the function. These types should defined in a corresponding file in Sindbad so that they can be used for dispatching and setup, if that were needed.
using Sindbad: PreAllocArrayFD, PreAllocArrayReactant

# ------------------------------------------------------------------
# Reactant needs the array that the timestep loop writes model output into to itself be a
# Reactant-traced array (a plain Array{Float32} can never hold a traced value once a
# differentiated parameter influences the written value). Everything else about output
# preallocation is identical to `PreAllocArrayFD`, so these methods delegate to it and then
# convert each per-location, per-variable output array to a standalone `TracedRArray`.
#
# Wrapping the shared `output.data` in `to_rarray` up front (before per-location slicing)
# was tried first, but `PreAllocArrayFD`'s per-location slicing (`getLocData`) then produces
# `SubArray`s wrapping that traced array. A `SubArray`'s index tuple encodes full-dimension
# slices as `Base.Slice{Base.OneTo{Int64}}` in its *type*, and Reactant's type-tracing walks
# every `Int` it finds -- including this structural type parameter, not just actual data --
# trying to convert it to `TracedRNumber{Int64}`, which `Base.OneTo` rejects (confirmed via
# the exact error: "Failed to find a valid type for typevar 1 (TracedRNumber{Int64} <:
# Integer == false) in wrapper Base.OneTo"). Materializing each location's slice into its own
# array (`Array(ar)`) before wrapping avoids ever constructing that `SubArray`-of-traced-array
# type in the first place.
function helpPrepTEM(selected_models, info, forcing::NamedTuple, output::NamedTuple, ::PreAllocArrayReactant)
    run_helpers = helpPrepTEM(selected_models, info, forcing, output, PreAllocArrayFD())
    space_output = map(run_helpers.space_output) do loc_output
        map(ar -> Reactant.to_rarray(Array(ar)), loc_output)
    end
    return (; run_helpers..., space_output)
end

function helpPrepTEM(selected_models, info, forcing::NamedTuple, observations::NamedTuple, output::NamedTuple, ::PreAllocArrayReactant)
    run_helpers = helpPrepTEM(selected_models, info, forcing, observations, output, PreAllocArrayFD())
    space_output = map(run_helpers.space_output) do loc_output
        map(ar -> Reactant.to_rarray(Array(ar)), loc_output)
    end
    return (; run_helpers..., space_output)
end
