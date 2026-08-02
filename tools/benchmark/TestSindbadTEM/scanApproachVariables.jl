using SindbadTEM
using SindbadTEM.Utils: getInOutModel

# Statically discovers every `forcing`/`land` variable that every SINDBAD approach reads
# (:input) or writes (:output), by reusing SindbadTEM.Utils.getInOutModel -- the same
# I/O-parsing helper that already powers the auto-generated approach docstrings -- instead
# of re-implementing source scanning from scratch.
#
# Known limitations of getInOutModel (not fixed here, see SindbadTEM/src/Utils.jl):
#   - It excludes `helpers.*` reads entirely. Helpers coverage is therefore *derived*: every
#     pool name seen under the `:pools` category implies helpers.pools.{zix,zeros,ones,n_layers}
#     for that pool must exist.
#   - It only recognizes the @unpack_nt/@pack_nt convention; code bypassing it triggers a
#     @warn from getInOutModel itself, and would still be caught at runtime by testApproaches.jl.
#
# Run with: julia --project=SindbadTEM tools/benchmark/TestSindbadTEM/scanApproachVariables.jl

# `@add_to_elem`/`@rep_elem` calls on a delta pool (e.g. `ΔsnowW`) pass the *base* pool's
# name (`:snowW`) as the helpers lookup key, since helpers.pools.zeros/ones are shared
# between a pool and its delta -- they're the same shape. Strip the "Δ" prefix accordingly.
basePoolName(var) = startswith(String(var), "Δ") ? Symbol(String(var)[3:end]) : var

function leafSubtypes(T)
    subs = subtypes(T)
    isempty(subs) && return [T]
    return reduce(vcat, (isabstracttype(S) ? leafSubtypes(S) : [S] for S in subs))
end

"""
    collectUsedVariables(approach_types=leafSubtypes(LandEcosystem))

Returns `(; forcing, land)` where:
  - `forcing[var] => [approach names reading f_var]`
  - `land[category][var] => [approach names reading/writing land.category.var]`
"""
function collectUsedVariables(approach_types=leafSubtypes(LandEcosystem))
    forcing_vars = Dict{Symbol,Vector{Symbol}}()
    land_vars = Dict{Symbol,Dict{Symbol,Vector{Symbol}}}()

    for T in approach_types
        approach_name = nameof(T)
        io = getInOutModel(T(), (:define, :precompute, :compute, :update))
        for func in (:define, :precompute, :compute, :update)
            for (category, var) in (io[func][:input]..., io[func][:output]...)
                if category == :forcing
                    push!(get!(forcing_vars, var, Symbol[]), approach_name)
                else
                    cat_dict = get!(land_vars, category, Dict{Symbol,Vector{Symbol}}())
                    push!(get!(cat_dict, var, Symbol[]), approach_name)
                end
            end
        end
    end
    return (; forcing=forcing_vars, land=land_vars)
end

"""
    missingTestDataVariables(used, tmp_forcing, land, tmp_helpers)

Diffs the statically-discovered variable usage against the actual test-data NamedTuples and
returns `(; forcing, land, helpers)`, each a `Dict` of `variable/pool => [approach names]`
for anything missing. Only `:input` usage is checked for `forcing`/`land` (that's what would
actually make an approach's runtime call error); `:output`-only variables don't need to
pre-exist since `@pack_nt` creates them. Helpers coverage is derived from pool names seen in
`land.pools` (input or output -- `@add_to_elem`/`@rep_elem` on a pool implies that pool's
`helpers.pools.{zix,zeros,ones,n_layers}` entry is required).

Note: `land` here is the *minimal*, pre-processing land (empty namespaces for most
processes), not a fully-populated snapshot -- so this will report many `:input` land
variables as "missing" even though they'd legitimately be populated further along the
real define/precompute/compute sequence. Treat the `land` half of the result as a rough
signal, not a hard failure list; `forcing`/`helpers` are unaffected since those don't
change shape as the sequence progresses.
"""
function missingTestDataVariables(approach_types, tmp_forcing, land, tmp_helpers)
    missing_forcing = Dict{Symbol,Vector{Symbol}}()
    missing_land = Dict{Symbol,Dict{Symbol,Vector{Symbol}}}()
    pool_names = Dict{Symbol,Vector{Symbol}}()

    for T in approach_types
        approach_name = nameof(T)
        io = getInOutModel(T(), (:define, :precompute, :compute, :update))
        for func in (:define, :precompute, :compute, :update)
            for (category, var) in io[func][:input]
                if category == :forcing
                    hasproperty(tmp_forcing, var) ||
                        push!(get!(missing_forcing, var, Symbol[]), approach_name)
                else
                    cat_ok = hasproperty(land, category) && hasproperty(getproperty(land, category), var)
                    if !cat_ok
                        cat_dict = get!(missing_land, category, Dict{Symbol,Vector{Symbol}}())
                        push!(get!(cat_dict, var, Symbol[]), approach_name)
                    end
                end
                category == :pools && push!(get!(pool_names, basePoolName(var), Symbol[]), approach_name)
            end
            for (category, var) in io[func][:output]
                category == :pools && push!(get!(pool_names, basePoolName(var), Symbol[]), approach_name)
            end
        end
    end

    missing_helpers = Dict{Symbol,Vector{Symbol}}()
    helpers_pools = tmp_helpers.pools
    for (pool, approaches) in pool_names
        covered = all(hasproperty(getproperty(helpers_pools, sub), pool) for sub in (:zix, :zeros, :ones, :n_layers))
        covered || (missing_helpers[pool] = approaches)
    end

    return (; forcing=missing_forcing, land=missing_land, helpers=missing_helpers)
end

if abspath(PROGRAM_FILE) == @__FILE__
    test_data_dir = joinpath(@__DIR__, "..", "..", "..", "SindbadTEM", "test", "test_data")
    include(joinpath(test_data_dir, "forcing.jl"))
    include(joinpath(test_data_dir, "land.jl"))
    include(joinpath(test_data_dir, "helpers.jl"))

    approach_types = leafSubtypes(LandEcosystem)
    missing = missingTestDataVariables(approach_types, tmp_forcing, land, tmp_helpers)

    println("\n=== Missing forcing variables ===")
    isempty(missing.forcing) && println("  none")
    for (var, approaches) in missing.forcing
        println("  forcing.$var -- needed by: ", join(sort(approaches), ", "))
    end

    println("\n=== Missing land variables ===")
    isempty(missing.land) && println("  none")
    for (category, vars) in missing.land, (var, approaches) in vars
        println("  land.$category.$var -- needed by: ", join(sort(approaches), ", "))
    end

    println("\n=== Missing helpers.pools entries (derived from land.pools usage) ===")
    isempty(missing.helpers) && println("  none")
    for (pool, approaches) in missing.helpers
        println("  helpers.pools.{zix,zeros,ones,n_layers}.$pool -- needed by: ", join(sort(approaches), ", "))
    end
    println()
end
