#!/usr/bin/env julia
#
# Benchmark Sindbad's optimizer call cascade (cost_function -> cost -> updateModels/
# runTEM!/metricVector -> getData -> getHarmonizedData -> ...) across one or more
# Julia versions, side by side, before switching your default Julia version.
#
# Usage:
#   julia compare_julia_versions.jl \
#       --experiment=path/to/experiment.json \
#       --versions=1.11.9,1.12.6 \
#       [--project=path/to/env] \
#       [--replace-info=path/to/replace_info.json] \
#       [--threads=8] \
#       [--out=path/to/report.md]
#
# Each --versions entry is a juliaup channel/version name (as shown by `juliaup list`),
# e.g. "1.11.9", "1.12.6", "release", "lts".
#
# --project is optional. If given, its Project.toml is used as a template for extra
# dependencies (beyond Sindbad + BenchmarkTools, which are always provided) -- useful
# if your experiment needs something like CMAEvolutionStrategy loaded. If omitted, a
# minimal env (just Sindbad dev-linked to this checkout + BenchmarkTools) is built
# from scratch, which is enough for the benchmark cascade itself.
#
# For each version this script builds its own throwaway env under
# benchmark/.jlbench_envs/ and instantiates it -- your real environment (if any was
# given via --project) is never modified, and a Manifest.toml resolved under one
# Julia version never has to be reused/corrupted by another. Default report path is
# benchmark/tmp_<experiment file name>.md.

function parse_args(args)
    opts = Dict{String,String}()
    for a in args
        if startswith(a, "--")
            kv = split(a[3:end], "="; limit=2)
            if length(kv) == 2
                opts[kv[1]] = kv[2]
            else
                opts[kv[1]] = "true"
            end
        end
    end
    return opts
end

opts = parse_args(ARGS)

haskey(opts, "experiment") || error("missing --experiment=path/to/experiment.json")
haskey(opts, "versions") || error("missing --versions=1.11.9,1.12.6")

experiment_json = abspath(opts["experiment"])
project_path = haskey(opts, "project") ? abspath(opts["project"]) : nothing
versions = split(opts["versions"], ",")
replace_info_path = haskey(opts, "replace-info") ? abspath(opts["replace-info"]) : "NONE"
threads = get(opts, "threads", string(max(1, Sys.CPU_THREADS ÷ 2)))
experiment_trunk = splitext(basename(experiment_json))[1]
out_path = get(opts, "out", joinpath(@__DIR__, "tmp_$(experiment_trunk).md"))

worker = joinpath(@__DIR__, "cascade_bench_worker.jl")
tmpdir = mktempdir()

println("Sindbad Julia-version benchmark")
println("  experiment:   ", experiment_json)
println("  project:      ", project_path === nothing ? "(auto: Sindbad + BenchmarkTools only)" : project_path)
println("  replace-info: ", replace_info_path)
println("  threads:      ", threads)
println("  versions:     ", join(versions, ", "))
println()

# Each Julia version gets its own isolated copy of the environment (Project.toml only,
# fresh Manifest.toml). A single shared Manifest.toml resolved under one Julia version
# can become unusable when re-instantiated under another (stdlib entries, artifact
# resolution, etc. differ across versions) -- isolating per version sidesteps that
# entirely and makes repeated runs reproducible regardless of what was run before.
envs_root = joinpath(@__DIR__, ".jlbench_envs")
mkpath(envs_root)
sindbad_root = normpath(joinpath(@__DIR__, ".."))
env_label = project_path === nothing ? "minimal" : basename(project_path)

results = Dict{String,String}()  # version => csv path
for v in versions
    v = strip(v)
    # namespaced by target project too, so benchmarking different --project dirs
    # against the same Julia version never reuses another project's env by mistake
    env_dir = joinpath(envs_root, env_label * "_" * v)
    mkpath(env_dir)

    println("=== Julia $v: instantiating isolated environment ($env_dir) ===")
    if project_path === nothing
        # no template given: build the minimal env the worker actually needs
        # (Sindbad dev-linked to this checkout, plus BenchmarkTools) from scratch.
        run(`julia +$v --project=$env_dir -e "using Pkg; Pkg.develop(path=raw\"$sindbad_root\"); Pkg.add(\"BenchmarkTools\"); Pkg.instantiate()"`)
    else
        cp(joinpath(project_path, "Project.toml"), joinpath(env_dir, "Project.toml"); force=true)
        run(`julia +$v --project=$env_dir -e "using Pkg; Pkg.develop(path=raw\"$sindbad_root\"); Pkg.instantiate()"`)
    end

    println("=== Julia $v: running benchmark cascade ($threads threads) ===")
    csv_path = joinpath(tmpdir, "bench_$(v).csv")
    run(`julia +$v -t $threads --project=$env_dir $worker $experiment_json $replace_info_path $csv_path`)
    results[v] = csv_path
    println()
end

# --- parse each version's CSV into name/parent -> (time_ns, allocs, memory) ---
struct Row
    name::String
    parent::String
    time_ns::Float64
    allocs::Int
    memory::Int
end

function read_csv(path)
    rows = Row[]
    meta = ""
    open(path) do io
        for (i, line) in enumerate(eachline(io))
            if i == 1
                meta = line
                continue
            end
            i == 2 && continue # header
            isempty(strip(line)) && continue
            parts = split(line, ",")
            push!(rows, Row(parts[1], parts[2], parse(Float64, parts[3]), parse(Int, parts[4]), parse(Int, parts[5])))
        end
    end
    return rows, meta
end

parsed = Dict{String,Tuple{Vector{Row},String}}()
for (v, path) in results
    parsed[v] = read_csv(path)
end

# use the first requested version's row order/names as the canonical row list
ordered_versions = [strip(v) for v in versions]
canonical_rows, _ = parsed[ordered_versions[1]]

# --- build markdown table ---
io = IOBuffer()
println(io, "# Julia version benchmark: ", basename(experiment_json))
println(io)
println(io, "## Experiment configuration")
println(io)
println(io, "- experiment file: `", experiment_json, "`")
println(io, "- replace-info: ", replace_info_path == "NONE" ? "(none)" : "`$(replace_info_path)`")
if replace_info_path != "NONE"
    println(io, "  ```json")
    println(io, read(replace_info_path, String))
    println(io, "  ```")
end
println(io, "- project env: ", project_path === nothing ? "(auto: Sindbad + BenchmarkTools only)" : "`$(project_path)`")
println(io)
println(io, "<details><summary>raw experiment.json</summary>")
println(io)
println(io, "```json")
println(io, read(experiment_json, String))
println(io, "```")
println(io, "</details>")
println(io)
println(io, "## Environment")
println(io)
for v in ordered_versions
    _, meta = parsed[v]
    println(io, "- Julia ", v, ": ", meta)
end
println(io)
println(io, "## Results")
println(io)

header = "| function | parent |" * join([" $v (ms) |" for v in ordered_versions]) * (length(ordered_versions) > 1 ? " ratio (last/first) |" : "")
sep = "|---|---|" * join([":---:|" for _ in ordered_versions]) * (length(ordered_versions) > 1 ? ":---:|" : "")
println(io, header)
println(io, sep)

for r in canonical_rows
    times_ms = Float64[]
    for v in ordered_versions
        rows_v, _ = parsed[v]
        match_row = findfirst(x -> x.name == r.name, rows_v)
        push!(times_ms, match_row === nothing ? NaN : rows_v[match_row].time_ns / 1e6)
    end
    line = "| $(r.name) | $(r.parent) |" * join([" $(round(t, digits=4)) |" for t in times_ms])
    if length(ordered_versions) > 1 && !isnan(times_ms[1]) && times_ms[1] > 0
        ratio = times_ms[end] / times_ms[1]
        line *= " $(round(ratio, digits=3))x |"
    end
    println(io, line)
end

table_str = String(take!(io))
println(table_str)

open(out_path, "w") do f
    write(f, table_str)
end
println("\nSaved to ", out_path)
