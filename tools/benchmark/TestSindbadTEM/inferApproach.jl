# Isolated MWE: give it one approach name and get @code_warntype on its define/precompute/
# compute, run against the same realistic, correctly-built-up `land` state the benchmark and
# checkApproaches.jl use (upstream processes advanced via reference_approaches; see
# SindbadTEM/test/checkApproaches.jl for the full explanation of why a single static `land`
# input isn't representative).
#
# Run with: julia --project=SindbadTEM tools/benchmark/TestSindbadTEM/inferApproach.jl <ApproachName>
# or include it interactively and call inferApproach("ApproachName") directly, as many times as
# you like in one session (each call is independent, does not mutate shared state).

using SindbadTEM
import SindbadTEM.Processes as SM
using InteractiveUtils: code_warntype

test_data_dir = joinpath(@__DIR__, "..", "..", "..", "SindbadTEM", "test", "test_data")
include(joinpath(test_data_dir, "forcing.jl"))
include(joinpath(test_data_dir, "land.jl"))
include(joinpath(test_data_dir, "referenceApproaches.jl"))
include(joinpath(test_data_dir, "helpers.jl"))

test_num_type = eltype(land.pools.cEco)
test_model_timestep = "day"
typedApproach(::Type{T}) where {T <: LandEcosystem} = getTypedModel(nameof(T), test_model_timestep, test_num_type)

_selected_by_process = let selected = Dict{Symbol,Any}()
    for name in reference_approaches
        T = getfield(SM, name)
        selected[nameof(supertype(T))] = T
    end
    selected
end

# advance `land` through every process's reference approach's define+precompute+compute, in
# order, stopping just before `stop_process` (exclusive) -- this is exactly what the tested
# approach would see as its own input in a real run.
function landBeforeProcess(stop_process::Symbol)
    l = deepcopy(land)
    for p in SM.standard_sindbad_model
        p === stop_process && break
        ref_type = get(_selected_by_process, p, nothing)
        ref_type === nothing && continue
        params = typedApproach(ref_type)
        l = SM.define(params, tmp_forcing, l, tmp_helpers)
        l = SM.precompute(params, tmp_forcing, l, tmp_helpers)
        l = SM.compute(params, tmp_forcing, l, tmp_helpers)
    end
    return l
end

"""
    inferApproach(name; functions=(:define, :precompute, :compute))

Run `@code_warntype` for the named approach's `define`/`precompute`/`compute` (in that order,
each fed by the previous one's own output, exactly like a real run), against a `land` state
built by advancing every *other* process's reference approach first. `name` is the approach's
struct name, e.g. `"cCycle_GSI"` or `:cCycle_GSI`.
"""
function inferApproach(name; functions=(:define, :precompute, :compute))
    T = getfield(SM, Symbol(name))
    process = nameof(supertype(T))
    params = typedApproach(T)
    l = landBeforeProcess(process)
    println("="^100)
    println("Approach: ", nameof(T), "  (process: ", process, ")")
    println("="^100)
    if :define in functions
        println("\n--- define ---")
        code_warntype(SM.define, (typeof(params), typeof(tmp_forcing), typeof(l), typeof(tmp_helpers)))
    end
    l = SM.define(params, tmp_forcing, l, tmp_helpers)
    if :precompute in functions
        println("\n--- precompute ---")
        code_warntype(SM.precompute, (typeof(params), typeof(tmp_forcing), typeof(l), typeof(tmp_helpers)))
    end
    l = SM.precompute(params, tmp_forcing, l, tmp_helpers)
    if :compute in functions
        println("\n--- compute ---")
        code_warntype(SM.compute, (typeof(params), typeof(tmp_forcing), typeof(l), typeof(tmp_helpers)))
    end
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    isempty(ARGS) && error("usage: julia --project=SindbadTEM tools/benchmark/TestSindbadTEM/inferApproach.jl <ApproachName>")
    inferApproach(ARGS[1])
end
