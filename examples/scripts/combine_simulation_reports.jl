using Dates
using Printf

# Combines the per-OS CSVs written by simulation_report.jl (one per matrix job in
# .github/workflows/TestSimulations.yml) into a single Markdown report covering all OSes/Julia
# versions, written to $GITHUB_STEP_SUMMARY. Reads every *.csv file in the directory named by
# the SIMULATION_REPORT_DIR environment variable (defaults to "reports", matching the workflow's
# artifact download step).

function parseCsvLine(line)
    fields = String[]
    buf = IOBuffer()
    in_quotes = false
    i = 1
    n = length(line)
    while i <= n
        c = line[i]
        if in_quotes
            if c == '"'
                if i < n && line[i + 1] == '"'
                    print(buf, '"')
                    i += 1
                else
                    in_quotes = false
                end
            else
                print(buf, c)
            end
        else
            if c == '"'
                in_quotes = true
            elseif c == ','
                push!(fields, String(take!(buf)))
            else
                print(buf, c)
            end
        end
        i += 1
    end
    push!(fields, String(take!(buf)))
    return fields
end

function readCsv(path)
    lines = filter(!isempty, readlines(path))
    header = parseCsvLine(lines[1])
    return [NamedTuple(Symbol.(header) .=> parseCsvLine(line)) for line in lines[2:end]]
end

report_dir = get(ENV, "SIMULATION_REPORT_DIR", "reports")
csv_paths = filter(f -> endswith(f, ".csv"), readdir(report_dir; join=true))
isempty(csv_paths) && error("no CSV files found in $(report_dir)")

rows = reduce(vcat, readCsv.(csv_paths))

io = IOBuffer()
println(io, "## Simulation report")
println(io, "")
println(io, "$(Dates.format(now(), "yyyy-mm-dd HH:MM")) UTC")
println(io, "")
println(io, "| OS | Julia | Setup | Mode | Kind | Status | Time (s) | Memory (MB) | Mean GPP (gC m⁻² day⁻¹) | Cost |")
println(io, "|---|---|---|---|---|---|---|---|---|---|")
for row in rows
    ok = row.ok == "true"
    status = ok ? "OK" : "FAILED: $(row.error)"
    time_str = ok ? @sprintf("%.1f", parse(Float64, row.time_s)) : "--"
    mem_str = ok ? @sprintf("%.1f", parse(Float64, row.memory_mb)) : "--"
    gpp_str = ok ? @sprintf("%.3f", parse(Float64, row.mean_gpp)) : "--"
    cost_str = !ok ? "--" : row.kind == "forward" ? "n/a" : @sprintf("%.4f", parse(Float64, row.cost))
    println(io, "| $(row.os) | $(row.julia) | $(row.setup) | $(row.mode) | $(row.kind) | $status | $time_str | $mem_str | $gpp_str | $cost_str |")
end
report = String(take!(io))
println(report)

summary_path = get(ENV, "GITHUB_STEP_SUMMARY", nothing)
if !isnothing(summary_path)
    open(summary_path, "a") do f
        println(f, report)
    end
end
# Always written (in addition to GITHUB_STEP_SUMMARY when running in Actions) so a later
# workflow step can pick this file up to post it as a PR comment.
write("output_simulation_report_combined.md", report)

any(row.ok != "true" for row in rows) && error("one or more example runs failed; see report above")
