"""
Reactant-specific timestep loop for `Sindbad.Simulation.coreTEM!`/`timeLoopTEM!`.

This file is included from the extension module and can use `Reactant`.
"""

import Sindbad.Simulation: timeLoopTEM!, fillLocOutput!, getLocArrayView, getForcingV

using Sindbad: DoNotDebugModel, ForcingWithTime
using Sindbad: computeTEM, getForcingForTimeStep, setOutputForTimeStep!

# ------------------------------------------------------------------
# SINDBAD's default `timeLoopTEM!` is a plain Julia `for` loop. Reactant traces plain loops
# by fully unrolling them into the compiled program, so for a realistic number of timesteps
# the generated program becomes too large for Reactant/Enzyme/LLVM to compile (confirmed via
# a synthetic, SINDBAD-free repro that fails identically at the same scale with plain `map`,
# and succeeds at any scale once rewritten with `Reactant.@trace for`). `Reactant.@trace for`
# instead captures a genuine loop op in the traced program, keeping compile cost independent
# of `n_timesteps`.
#
# Both the forcing read (`getForcingV`) and the output write (`fillLocOutput!`) index with
# the loop variable `ts`, which is dynamic under `@trace for`. Any array reachable from the
# traced closure -- including plain `Vector`s captured from outside, like `loc_forcing`'s
# time series -- becomes Reactant-traced during tracing, so both the read and the write need
# `@allowscalar` at the exact call site (confirmed via a synthetic repro: a plain Julia
# `Vector` indexed with the `@trace for` loop variable trips the same scalar-indexing guard
# as a traced array).
#
# `n_timesteps` itself arrives already traced too: it is a scalar `Int` field buried inside
# the large `tem_info` NamedTuple, which Reactant's closure tracing wraps wholesale, even
# though it never depends on the differentiated parameters. `@trace for` needs a concrete
# `Integer` range bound (`Base.OneTo` rejects `TracedRNumber{Int64}`), so the bound is instead
# derived from `loc_output`'s array shape -- array sizes stay concrete even when elements are
# traced (the same reason `@trace for i in eachindex(x)` works in Reactant's own examples).
function timeLoopTEM!(selected_models, loc_forcing, loc_forcing_t, loc_output::AbstractVector{<:Reactant.AnyTracedRArray}, land, forcing_types, model_helpers, output_vars, n_timesteps, ::DoNotDebugModel)
    n_timesteps_concrete = size(loc_output[1], 1)
    Reactant.@trace checkpointing = Reactant.Periodic(4) for ts in 1:n_timesteps_concrete
        f_ts = getForcingForTimeStep(loc_forcing, loc_forcing_t, ts, forcing_types)
        land = computeTEM(selected_models, f_ts, land, model_helpers)
        setOutputForTimeStep!(loc_output, land, ts, output_vars)
    end
end

function getForcingV(v::Reactant.AnyTracedRArray, ts, ::ForcingWithTime)
    return Reactant.@allowscalar v[ts]
end

function fillLocOutput!(ar::Reactant.AnyTracedRArray, val::T1, ts::T2) where {T1, T2<:Int}
    data_ts = getLocArrayView(ar, val, ts)
    Reactant.@allowscalar data_ts .= val
    return nothing
end
