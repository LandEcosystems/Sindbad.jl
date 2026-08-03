# Turns benchmarkApproaches.jl's pipe-delimited output into:
#   1. a self-contained, sortable/filterable HTML report (benchmarkReportTemplate.html + embedded JSON), and
#   2. a condensed Markdown summary (status counts + every error/invalid-number row), suitable for
#      a GitHub Actions job summary ($GITHUB_STEP_SUMMARY).
#
# Run with: julia tools/benchmark/TestSindbadTEM/renderBenchmarkReport.jl [input.psv] [output.html] [output.md]

in_path = length(ARGS) >= 1 ? ARGS[1] : joinpath(@__DIR__, "benchmark_output", "benchmark_results.psv")
out_html = length(ARGS) >= 2 ? ARGS[2] : joinpath(@__DIR__, "benchmark_output", "benchmark_report.html")
out_md = length(ARGS) >= 3 ? ARGS[3] : joinpath(@__DIR__, "benchmark_output", "benchmark_summary.md")

const METHODS = ("define", "precompute", "compute", "update")
const RANK = Dict("error" => 3, "invalid_number" => 2, "ok" => 1, "not_defined" => 0)
worstStatus(statuses) = statuses[argmax(get.(Ref(RANK), statuses, 0))]

struct Row
    process::String
    approach::String
    method::String
    defined::Bool
    status::String
    severity::String
    time_ms::Union{Float64,Nothing}
    bytes::Union{Int,Nothing}
    n_allocs::Union{Int,Nothing}
    invalid_paths::Vector{String}
    location::String
    errmsg::String
end

function parseRows(path)
    rows = Row[]
    open(path) do io
        readline(io)  # header
        for line in eachline(io)
            parts = split(line, "|"; limit=12)
            process, approach, method, defined_s, status, severity, time_s, bytes_s, allocs_s, paths_s, location, errmsg = parts
            time_ms = time_s == "NaN" ? nothing : parse(Float64, time_s)
            bytes = bytes_s == "-1" ? nothing : parse(Int, bytes_s)
            n_allocs = allocs_s == "-1" ? nothing : parse(Int, allocs_s)
            invalid_paths = isempty(paths_s) ? String[] : split(paths_s, ";") .|> String
            push!(rows, Row(process, approach, method, defined_s == "true", status, severity,
                time_ms, bytes, n_allocs, invalid_paths, location, errmsg))
        end
    end
    return rows
end

# --- minimal JSON writer (String/Bool/Nothing/Real/Vector/Dict-of-String-keys only) ---
function jsonEscape(s::AbstractString)
    io = IOBuffer()
    for c in s
        if c == '"'
            write(io, "\\\"")
        elseif c == '\\'
            write(io, "\\\\")
        elseif c == '\n'
            write(io, "\\n")
        elseif c == '\r'
            write(io, "\\r")
        elseif c == '\t'
            write(io, "\\t")
        elseif Int(c) < 0x20
            write(io, "\\u", lpad(string(Int(c); base=16), 4, '0'))
        else
            write(io, c)
        end
    end
    return String(take!(io))
end
toJSON(x::AbstractString) = "\"" * jsonEscape(x) * "\""
toJSON(x::Bool) = x ? "true" : "false"
toJSON(::Nothing) = "null"
toJSON(x::Real) = isfinite(x) ? string(x) : "null"
toJSON(x::AbstractVector) = "[" * join(toJSON.(x), ",") * "]"
toJSON(x::AbstractDict) = "{" * join(("\"$(jsonEscape(string(k)))\":$(toJSON(v))" for (k, v) in x), ",") * "}"

function buildPayload(rows)
    # process -> approach -> method -> Row
    grouped = Dict{String,Dict{String,Dict{String,Row}}}()
    for r in rows
        pd = get!(grouped, r.process, Dict{String,Dict{String,Row}}())
        ad = get!(pd, r.approach, Dict{String,Row}())
        ad[r.method] = r
    end

    totals = Dict("ok" => 0, "error" => 0, "invalid_number" => 0, "not_defined" => 0)
    for r in rows
        totals[r.status] += 1
    end

    out_processes = []
    for process in sort(collect(keys(grouped)))
        approaches = grouped[process]
        out_approaches = []
        for approach in sort(collect(keys(approaches)))
            methods = approaches[approach]
            statuses = [methods[m].status for m in METHODS if haskey(methods, m)]
            method_dict = Dict{String,Any}()
            for m in METHODS
                if haskey(methods, m)
                    r = methods[m]
                    method_dict[m] = Dict(
                        "defined" => r.defined, "status" => r.status, "sev" => r.severity,
                        "t" => r.time_ms, "b" => r.bytes, "a" => r.n_allocs,
                        "paths" => r.invalid_paths, "loc" => r.location, "err" => r.errmsg,
                    )
                else
                    method_dict[m] = nothing
                end
            end
            push!(out_approaches, Dict("name" => approach, "status" => worstStatus(statuses), "methods" => method_dict))
        end
        process_status = worstStatus([a["status"] for a in out_approaches])
        push!(out_processes, Dict("name" => process, "status" => process_status, "approaches" => out_approaches))
    end

    return Dict("processes" => out_processes, "totals" => totals, "methods" => collect(METHODS))
end

function writeHTML(payload, template_path, out_path)
    template = read(template_path, String)
    html = replace(template, "__DATA_JSON__" => toJSON(payload))
    mkpath(dirname(out_path))
    write(out_path, html)
end

function writeMarkdownSummary(rows, out_path)
    totals = Dict("ok" => 0, "bug" => 0, "incompatible" => 0, "invalid_number" => 0, "not_defined" => 0)
    for r in rows
        # `severity` (bug/incompatible) is only set on status=="error" rows -- see
        # benchmarkApproaches.jl's errorResult/isMissingFieldError. Everything else keys directly
        # off status.
        key = r.status == "error" ? r.severity : r.status
        totals[key] += 1
    end
    mkpath(dirname(out_path))
    open(out_path, "w") do io
        println(io, "## SindbadTEM process benchmark")
        println(io)
        defined_total = totals["ok"] + totals["bug"] + totals["incompatible"] + totals["invalid_number"]
        println(io, "$(length(rows)) method calls across every approach, $(defined_total) defined ",
            "(the rest fall back to the no-op default, not a problem): ",
            "$(totals["ok"]) success &middot; $(totals["bug"]) bug &middot; ",
            "$(totals["incompatible"]) incompatible (expected -- missing/mismatched upstream data ",
            "for this test's reference selection, not a bug) &middot; ",
            "$(totals["invalid_number"]) invalid-number")
        println(io)

        # Bugs sort first -- they're the ones worth looking at; incompatible rows are expected
        # noise (see the classification comment above) and invalid_number rows come last.
        sevRank(r) = r.status == "error" ? (r.severity == "bug" ? 0 : 1) : 2
        problems = filter(r -> r.status in ("error", "invalid_number"), rows)
        if isempty(problems)
            println(io, "No errors or invalid-number results.")
        else
            println(io, "| Process | Approach | Method | Severity | Location | Detail |")
            println(io, "|---|---|---|---|---|---|")
            for r in sort(problems; by=r -> (sevRank(r), r.process, r.approach, r.method))
                detail = r.status == "error" ? first(split(r.errmsg, " / ")) : join(r.invalid_paths, ", ")
                detail = replace(detail, "|" => "\\|")
                length(detail) > 90 && (detail = first(detail, 87) * "...")
                loc = isempty(r.location) ? "" : "`$(r.location)`"
                severity_label = r.status == "error" ? r.severity : "invalid_number"
                println(io, "| $(r.process) | $(r.approach) | $(r.method) | $(severity_label) | $loc | $detail |")
            end
        end
        println(io)
        println(io, "Full interactive report (sortable/filterable, one row per approach) is attached as a workflow artifact.")
    end
end

rows = parseRows(in_path)
payload = buildPayload(rows)
writeHTML(payload, joinpath(@__DIR__, "benchmarkReportTemplate.html"), out_html)
writeMarkdownSummary(rows, out_md)
println("Wrote ", out_html)
println("Wrote ", out_md)
