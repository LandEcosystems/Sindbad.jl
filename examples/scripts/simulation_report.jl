using Sindbad
using CMAEvolutionStrategy
using Dates
using Statistics
using Printf

# Runs every {LUE,WROASTED} x {pixel,spatial} x {forward,optimization} combination against
# examples/setups/ on the current OS/Julia version, and writes a CSV of wall time, memory
# allocated, and mean simulated GPP for each. `.github/workflows/TestSimulations.yml` ("Execution
# Report") runs one job per {OS} x {setup} x {mode} (each job runs both {forward,optimization}
# kinds), restricted via the SIMULATION_SETUPS/SIMULATION_MODES environment variables below; a
# separate "combine" job merges every job's CSV into one Markdown report (see
# combine_simulation_reports.jl) -- but this script also works standalone locally, defaulting to
# every setup/mode:
#
#   julia --project=examples/scripts examples/scripts/simulation_report.jl
#
# which writes examples/output_simulation_report_<os>.csv (git-ignored) and prints the same
# Markdown table it would otherwise contribute to the combined report.

site_index = 1
n_sites = 16 # spatial mode uses sites 1:n_sites, not all 205, to keep test runs fast

setups = split(get(ENV, "SIMULATION_SETUPS", "LUE,WROASTED"), ",")
modes = Symbol.(split(get(ENV, "SIMULATION_MODES", "pixel,spatial"), ","))
kinds = (:forward, :optimization)

os_name = get(ENV, "RUNNER_OS", Sys.iswindows() ? "Windows" : Sys.isapple() ? "macOS" : "Linux")
@info "julia threads" Threads.nthreads()

function buildReplaceInfo(mode, kind, output_path)
    subset_site = mode == :pixel ? [site_index] : collect(1:n_sites)
    replace_info = Dict{String,Any}(
        "forcing.subset.site" => subset_site,
        "experiment.model_output.path" => output_path, # root; SINDBAD creates its own output_<domain>_<name> subfolder inside
        # override the setup's own domain so the auto-generated output subfolder name reflects
        # what kind of run this is instead of a fixed domain name.
        "experiment.basics.domain" => "$(kind)_$(mode)",
    )
    if kind == :optimization
        replace_info["experiment.flags.run_optimization"] = true
        replace_info["experiment.flags.calc_cost"] = false
        replace_info["experiment.flags.run_forward"] = false
    end
    return replace_info
end

rows = NamedTuple[]
for setup in setups, mode in modes, kind in kinds
    experiment_json = joinpath(@__DIR__, "..", "setups", setup, "experiment.json")
    # shared root; SINDBAD's auto-generated output_<domain>_<name> subfolder (domain =
    # "<kind>_<mode>", name = setup) already keeps every combination's output separate.
    output_path = joinpath(@__DIR__, "..", "output")
    replace_info = buildReplaceInfo(mode, kind, output_path)

    @info "running" os_name setup mode kind
    row = try
        stats = @timed begin
            kind == :forward ? runExperimentForward(experiment_json; replace_info=replace_info, log_level=:warn) :
            runExperimentOpti(experiment_json; replace_info=replace_info, log_level=:warn)
        end
        gpp = kind == :forward ? stats.value.output.gpp : stats.value.output.optimized.gpp
        # total optimized cost (sum of loss_opt across all observational_constraints, matching
        # multi_constraint_method="metric_sum" in optimization.json); not applicable to forward runs.
        cost = kind == :forward ? NaN : sum(stats.value.loss.loss_opt)
        (; os=os_name, julia=string(VERSION), setup, mode=string(mode), kind=string(kind), ok=true, time_s=stats.time, memory_mb=stats.bytes / 1e6, mean_gpp=mean(gpp), cost, error="")
    catch e
        (; os=os_name, julia=string(VERSION), setup, mode=string(mode), kind=string(kind), ok=false, time_s=NaN, memory_mb=NaN, mean_gpp=NaN, cost=NaN, error=sprint(showerror, e))
    end
    push!(rows, row)
end

# --- CSV (one row per combination; consumed by combine_simulation_reports.jl) ---
csv_escape(s) = "\"" * replace(string(s), "\"" => "\"\"", "\n" => " ") * "\""
csv_header = "os,julia,setup,mode,kind,ok,time_s,memory_mb,mean_gpp,cost,error"
csv_lines = [csv_header]
for row in rows
    push!(csv_lines, join((csv_escape(row.os), csv_escape(row.julia), csv_escape(row.setup), csv_escape(row.mode),
        csv_escape(row.kind), row.ok, row.time_s, row.memory_mb, row.mean_gpp, row.cost, csv_escape(row.error)), ","))
end
csv_path = get(ENV, "SIMULATION_REPORT_CSV", joinpath(@__DIR__, "..", "output_simulation_report_$(os_name).csv"))
write(csv_path, join(csv_lines, "\n") * "\n")
@info "wrote csv" csv_path

# --- Markdown (this OS's rows only; useful when running standalone, not in the OS matrix) ---
function formatCost(row)
    !row.ok && return "--"
    row.kind == "forward" && return "n/a"
    return @sprintf("%.4f", row.cost)
end

function formatMarkdownTable(io, rows)
    println(io, "| OS | Julia | Setup | Mode | Kind | Status | Time (s) | Memory (MB) | Mean GPP (gC m⁻² day⁻¹) | Cost |")
    println(io, "|---|---|---|---|---|---|---|---|---|---|")
    for row in rows
        status = row.ok ? "OK" : "FAILED: $(row.error)"
        time_str = row.ok ? @sprintf("%.1f", row.time_s) : "--"
        mem_str = row.ok ? @sprintf("%.1f", row.memory_mb) : "--"
        gpp_str = row.ok ? @sprintf("%.3f", row.mean_gpp) : "--"
        cost_str = formatCost(row)
        println(io, "| $(row.os) | $(row.julia) | $(row.setup) | $(row.mode) | $(row.kind) | $status | $time_str | $mem_str | $gpp_str | $cost_str |")
    end
end

io = IOBuffer()
println(io, "## Simulation report ($(os_name))")
println(io, "")
println(io, "$(Dates.format(now(), "yyyy-mm-dd HH:MM")) UTC")
println(io, "")
formatMarkdownTable(io, rows)
report = String(take!(io))
println(report)

if haskey(ENV, "GITHUB_ACTIONS")
    # In CI this script only reports its own OS's CSV; the combine job writes the real summary.
else
    local_report_path = joinpath(@__DIR__, "..", "output_simulation_report_$(os_name).md")
    write(local_report_path, report)
    @info "wrote report" local_report_path
end

any(!row.ok for row in rows) && error("one or more example runs failed; see report above")
