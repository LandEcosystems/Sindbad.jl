using SindbadTEM
using InteractiveUtils
using SindbadTEM.DataStructures

# Get source directory for SindbadTEM models
sindbadTEM_src_dir = dirname(pathof(SindbadTEM))
sindbadTEM_pkg_root = dirname(sindbadTEM_src_dir)
# GitHub repository URL
github_repo_url = "https://github.com/LandEcosystems/Sindbad.jl"
github_branch = "main"

# Function to get params, inputs, and outputs using getInOutModel
function get_model_io_info(type_name::String)
    # Instantiate the model
    model_instance = getTypedModel(Symbol(type_name))
    
    # Determine which function to use (compute or precompute)
    # Try compute first, then precompute
    io_info = getInOutModel(model_instance, :compute)
    if io_info === nothing || !haskey(io_info, :input)
        io_info = getInOutModel(model_instance, :precompute)
    end
    
    # Get parameters
    params_info = getInOutModel(model_instance, :parameters)
    
    # Extract parameter names from NamedTuple keys
    params = nothing
    if params_info !== nothing && typeof(params_info) <: NamedTuple
        params = collect(keys(params_info))
    end
    
    return (params, io_info[:input], io_info[:output])
end

# Function to extract equation using getInOutModel
function extract_equation_code(file_path::String, type_name::String)
    # Get params, inputs, and outputs using getInOutModel
    params, inputs, outputs = get_model_io_info(type_name)
    if params === nothing && inputs === nothing && outputs === nothing
        return nothing
    end
    
    # Build equation lines from getInOutModel data
    equation_lines = String[]
    
    # Add params
    if params !== nothing && !isempty(params)
        param_names = [string(p) for p in params]
        push!(equation_lines, "Params: $(join(param_names, ", "))")
    end
    
    # Add inputs
    if inputs !== nothing && !isempty(inputs)
        input_names = [string(inp) for inp in inputs]
        push!(equation_lines, "Inputs: $(join(input_names, ", "))")
    end
    
    # Add outputs
    if outputs !== nothing && !isempty(outputs)
        output_names = [string(out) for out in outputs]
        push!(equation_lines, "Outputs: $(join(output_names, ", "))")
    end
    
    if isempty(equation_lines)
        return nothing
    end
    
    equation_code = join(equation_lines, '\n')
    return strip(equation_code) == "" ? nothing : equation_code
end

# Find which source file contains a model type
# If approach is A_B, file is at SindbadTEM/src/Processes/A/A_B.jl
function find_model_file(model_name::String)
    processes_dir = joinpath(sindbadTEM_src_dir, "Processes")
    
    # Extract the base model name (part before underscore)
    # e.g., "cAllocation_Friedlingstein1999" -> "cAllocation"
    parts = split(model_name, "_")
    if length(parts) > 1
        base_name = parts[1]
        file_path = joinpath(processes_dir, base_name, "$(model_name).jl")
        if isfile(file_path)
            return file_path
        end
    end
    
    # Fallback: try direct path in case it's a main model (no underscore)
    file_path = joinpath(processes_dir, model_name, "$(model_name).jl")
    if isfile(file_path)
        return file_path
    end
    
    return nothing
end

# Function to get GitHub link for a file
function get_github_link(file_path::String)
    if file_path === nothing || !isfile(file_path)
        return nothing
    end
    
    # Map installed-package paths back to the monorepo layout on GitHub.
    # `file_path` typically looks like: <...>/SindbadTEM/<hash>/src/...
    # GitHub layout is: SindbadTEM/src/...
    try
        rel_path = relpath(file_path, sindbadTEM_pkg_root)
        # Normalize path separators for GitHub URLs
        rel_path = replace(rel_path, "\\" => "/")
        return "$github_repo_url/blob/$github_branch/SindbadTEM/$rel_path"
    catch
        return nothing
    end
end

mkpath(joinpath(@__DIR__, "src/pages/code/api"))
open(joinpath(@__DIR__, "./src/pages/code/api/SindbadTEM.Processes.md"), "w") do o_file
    # write(o_file, "## Models\n\n")
    write(o_file, "```@docs\nSindbadTEM.Processes\n```\n")

    write(o_file, "## Processes (models + approaches)\n\n")

    sindbad_models_from_types = nameof.(SindbadTEM.subtypes(SindbadTEM.LandEcosystem))
    foreach(sort(collect(sindbad_models_from_types))) do sm
        sms = string(sm)
        write(o_file, "### $(sm)\n\n")
        # write(o_file, "== $(sm)\n")
        write(o_file, "```@docs\n$(sm)\n```\n")
        
        write(o_file, ":::details $(sm) approaches\n\n")
        write(o_file, ":::tabs\n\n")

        foreach(SindbadTEM.subtypes(getfield(SindbadTEM, sm))) do apr
            apr_str = string(apr)
            write(o_file, "== $(apr)\n")
            write(o_file, "```@docs\n$(apr)\n```\n")
            
            # Add equation as continuation of docstring (no heading, won't show in sidebar)
            approach_file = find_model_file(apr_str)
            if approach_file !== nothing
                equation_code = extract_equation_code(approach_file, apr_str)
                if equation_code !== nothing && strip(equation_code) != ""
                    write(o_file, "\n**Calculated using:**\n\n")
                    write(o_file, "```julia\n")
                    write(o_file, equation_code)
                    write(o_file, "\n```\n\n")
                end
                
                # Add GitHub link to the source file (always show if file is found)
                github_link = get_github_link(approach_file)
                if github_link !== nothing
                    write(o_file, "[View Source]($github_link)\n\n")
                end
            end
        end
        write(o_file, "\n:::\n\n")
        write(o_file, "\n----\n\n")
    end

    # Put all functions under a single "Methods" section (no model/type bindings here).
    write(o_file, "## Methods\n\n")
    write(o_file, "```@meta\nDocTestSetup= quote\nusing SindbadTEM.Processes\nend\n```\n")
    write(o_file, "```@autodocs\nModules = [SindbadTEM.Processes]\nFilter = x -> x isa Function\nPrivate = false\n```\n")

    write(o_file, "## Internal\n\n")
    write(o_file, "```@meta\nCollapsedDocStrings = false\nDocTestSetup= quote\nusing SindbadTEM.Processes\nend\n```\n")
    write(o_file, "\n```@autodocs\nModules = [SindbadTEM.Processes]\nPublic = false\n```")
end