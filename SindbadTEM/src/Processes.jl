"""
    Processes

The core module for defining and implementing models and approaches of ecosystem processes in the SINDBAD framework.

# Purpose:
The `Processes` module provides the infrastructure for defining and implementing terrestrial ecosystem models within the SINDBAD framework. It includes tools for process definition, parameter management, and method implementation. All SINDBAD models inherit from `LandEcosystem` and implement standardized methods for model execution.

# Dependencies:
- `SindbadTEM`: Provides the core SINDBAD models and types, including `LandEcosystem` and `purpose` function.
- `FieldMetadata`: Enables metadata annotations for model parameters (bounds, units, timescale, descriptions).
- `Parameters`: Provides the `@with_kw` macro for keyword argument construction.

# Included Files:
The module dynamically includes all process implementations from subdirectories under `src/Processes/`.

Each process directory follows the convention:
- A main process file: `Processes/<process>/<process>.jl` defining the abstract process type
- One or more approach files: `Processes/<process>/<process>_*.jl` implementing specific approaches

Key processes include:
- Carbon cycle processes (GPP, respiration, allocation, turnover)
- Water cycle processes (evapotranspiration, runoff, soil water)
- Vegetation processes (LAI, fAPAR, phenology)
- And many more ecosystem processes

# Notes:
- All models must implement at least one of the following methods: `define`, `precompute`, `compute`, or `update`.
- Parameters should use metadata macros (`@bounds`, `@describe`, `@units`, `@timescale`) for proper documentation and validation.
- Processes should follow SINDBAD modeling conventions for consistency and maintainability.
- The module provides `getModelDocString` and `getApproachDocString` helpers for automatic documentation generation of models and approaches.

# Examples:
```jldoctest
julia> using SindbadTEM.Processes

julia> # Define a new process
julia> abstract type MyProcess <: LandEcosystem end

julia> purpose(::Type{MyProcess}) = "Description of my process."

julia> # Define an approach with parameters (example structure)
julia> # @bounds @describe @units @timescale @with_kw struct MyProcess_v1{T} <: MyProcess
julia> #     param1::T = 1.0 | (0.0, 2.0) | "Description" | "units" | "timescale"
julia> # end

julia> # Implement required methods (example)
julia> # function define(params::MyProcess_v1, forcing, land, helpers)
julia> #     # Initialize arrays and variables
julia> #     return land
julia> # end
```

"""
module Processes

    # Import & export necessary modules/functions
    import SindbadTEM.TEMTypes: LandEcosystem, SindbadTypes, purpose
    import SindbadTEM.TEMTypes: poolAliases, poolConfiguration, poolStructure
    using FieldMetadata: @metadata
    using Parameters: @with_kw
    @metadata timescale "" String
    @metadata describe "" String
    @metadata bounds (-Inf, Inf) Tuple
    @metadata units "" String
    export describe, bounds, units

    """
    Day-equivalent multiplier for each temporal-resolution unit SINDBAD supports. This is
    the single source of truth for legal `timescale`/`temporal_resolution` unit strings --
    add a new unit by adding one entry here.
    """
    const TIMESCALE_DAY_MULTIPLIER = Dict(
        "second" => 1 / (60 * 60 * 24),
        "minute" => 1 / (60 * 24),
        "hour"   => 1 / 24,
        "day"    => 1.0,
        "month"  => 30.0,
        "year"   => 365.0,
    )
    export TIMESCALE_DAY_MULTIPLIER
    export getApproachDocString
    # define dispatch structs for catching process errors


    missingApproachPurpose(x) = "$(x) is missing the definition of purpose. Add `purpose(::Type{$(nameof(x))})` = \"the_purpose\"` in `$(nameof(x)).jl` file to define the specific purpose"

    """
        getModelDocString()

    Generate a base docstring for a SINDBAD process or approach.

    # Description
    This function dynamically generates a base docstring for a SINDBAD process or approach by inspecting its purpose, parameters, methods, and input/output variables. It uses the stack trace to determine the calling context and retrieves the appropriate information for the process or approach.

    # Arguments
    - None (uses the stack trace to determine the calling context).

    # Returns
    - A string containing the generated docstring for the process or approach.

    # Behavior
    - If the caller is a process, it generates a docstring with the process's purpose and its subtypes (approaches).
    - If the caller is an approach, it generates a docstring with the approach's purpose, parameters, and methods (`define`, `precompute`, `compute`, `update`), including their inputs and outputs.

    # Methods
    - `getModelDocString()`: Determines the calling context using the stack trace and generates the appropriate docstring.
    - `getModelDocString(modl_appr)`: Generates a docstring for a specific process or approach.
    - `getModelDocStringForModel(modl)`: Generates a docstring for a SINDBAD process, including its purpose and subtypes.
    - `getApproachDocString(appr)`: Generates a docstring for a SINDBAD approach, including its purpose, parameters, and methods.
    - `getModelDocStringForIO(doc_string, io_list)`: Appends input/output details to the docstring for a given list of variables.
    """
    function getModelDocString end


    function getModelDocString()
        stack = stacktrace()
        
        # Extract the file and line number of the caller
        if length(stack) > 1
            caller_info = string(stack[2]) # The second entry is the caller
            c_name = split(caller_info, "at ")[2]
            c_name = split(c_name, ".jl")[1]
            c_type = getproperty(SindbadTEM.Processes, Symbol(c_name))
            return getModelDocString(c_type)
        else
            return ("Information of the caller file is not available.")
        end
    end

    function getModelDocString(modl_appr)
        doc_string = ""
        if supertype(modl_appr) == LandEcosystem
            doc_string = getModelDocStringForModel(modl_appr)
        else
            doc_string = getApproachDocString(modl_appr)
        end
        return doc_string
    end


    function getApproachDocString(appr)
        doc_string = "\n"

        doc_string *= "$(purpose(appr))\n\n"
        in_out_model = getInOutModel(appr, verbose=false)
        doc_string *= "# Parameters\n"
        params = in_out_model[:parameters]
        if length(params) == 0
            doc_string *= " -  None\n"
        else
            doc_string *= " - **Fields**\n"
            for (_, param) in enumerate(params)
                ds="     - `$(first(param))`: $(last(param))\n"
                doc_string *= ds
            end
        end

        # Methods
        d_methods = (:define, :precompute, :compute, :update)
        doc_string *= "\n# Methods:\n"
        undefined_str = ""
        for d_method in d_methods
            inputs = in_out_model[d_method][:input]
            outputs = in_out_model[d_method][:output]
            if length(inputs) == 0 && length(outputs) == 0
                undefined_str *= "$(d_method), "
                continue
            else
                doc_string *= "\n`$(d_method)`:\n"
            end
            doc_string *= "- **Inputs**\n"
            doc_string = getModelDocStringForIO(doc_string, inputs)
            doc_string *= "- **Outputs**\n"
            doc_string = getModelDocStringForIO(doc_string, outputs)
        end
        if length(undefined_str) > 0
            doc_string *= "\n`$(undefined_str[1:end-2])` methods are not defined\n"        
        end
        appr_name = string(nameof(appr))
        doc_string *= "\n*End of `getModelDocString`-generated docstring for `$(appr_name).jl`.\nCheck the Extended help for user-defined information.*"
        return doc_string
    end


    function getModelDocStringForIO(doc_string, io_list)
        if length(io_list) == 0
            doc_string *= "     - None\n"
            return doc_string
        end
        foreach(io_list) do io_item
            v_key = Symbol(String(first(io_item))*"__"*String(last(io_item)))
            var_info = getVariableInfo(v_key, "time")
            miss_doc = isempty(var_info["long_name"])
            v_d = miss_doc ? "No description available in ```src/sindbadVariableCatalog.jl``` catalog. Run ```whatIs(:$(first(io_item)), :$(last(io_item)))``` for information on how to add the variable to the catalog." : var_info["description"]
            v_units = var_info["units"]
            v_units = miss_doc ? "" : isempty(v_units) ? "{unitless}" : "{$(v_units)}"
            if !miss_doc
                v_d = replace(v_d, "_" => "\\_")
            end

            doc_string *= "     - `$(first(io_item)).$(last(io_item))`: $(v_d)\n"
        end
        return doc_string
    end

    function getModelDocStringForModel(modl)
        doc_string = "\n"

        doc_string *= "\t$(purpose(modl))\n\n"

        doc_string *= "\n---\n"

        doc_string *= "# Approaches\n"
        foreach(subtypes(modl)) do subtype
            mod_name = string(nameof(subtype))
            # mod_name = replace(mod_name, "_" => "\\_")
            p_s = purpose(subtype)
            p_s_w = p_s
            p_s_w = isnothing(p_s) ? missingApproachPurpose(subtype) : p_s
            doc_string *= " - ```$(mod_name)```: " * "$(p_s_w)\n"
        end
        return doc_string
    end


    """
        includeApproaches(modl, dir)

    Include all approach files for a given SINDBAD process.

    # Description
    This function dynamically includes all approach files associated with a specific SINDBAD process. It searches the specified directory for files matching the naming convention `<model_name>_*.jl` and includes them into the current module.

    # Arguments
    - `modl`: The SINDBAD process for which approaches are to be included.
    - `dir`: The directory where the approach files are located.

    # Behavior
    - The function filters files in the specified directory to find those that match the naming convention `<model_name>_*.jl`.
    - Each matching file is included using Julia's `include` function.

    # Example
    ```julia
    # Include approaches for the `ambientCO2` process
    includeApproaches(ambientCO2, "/path/to/approaches")
    ```
    """
    function includeApproaches(modl, dir)
        include.(filter(contains("$(nameof(modl))_"), readdir(dir; join=true)))
        return
    end

    """
        compute(params<:LandEcosystem, forcing, land, helpers)

    Update the model state and variables in time using defined and precomputed objects.

    # Description
    The `compute` function is responsible for advancing the state of a SINDBAD model or approach in time. It uses previously defined and precomputed variables, along with updated forcing data, to calculate the time-dependent changes in the land model state. This function ensures that the model evolves dynamically based on the latest inputs and precomputed states.

    # Arguments
    - `params`: The parameter structure for the specific SINDBAD process or approach.
    - `forcing`: External forcing data required for the process or approach.
    - `land`: The land model state, which includes pools, diagnostics, and properties.
    - `helpers`: Additional helper functions or data required for computations.

    # Returns
    - The updated `land` model state with time-dependent changes applied.

    # Behavior
    - For each SINDBAD process or approach, the `compute` function updates the land model state based on the specific requirements of the process or approach.
    - It may include operations like updating pools, recalculating fluxes, or modifying diagnostics based on time-dependent forcing and precomputed variables.
    - This function is typically called iteratively to simulate the temporal evolution of the process.

    # Example
    ```julia
    # Example usage for a specific model
    land = compute(params::ambientCO2_constant, forcing, land, helpers)
    ```

    # Notes:
    The compute function is essential for SINDBAD models and approaches that require dynamic updates to the land model state over time. It ensures that the model evolves consistently with the defined and precomputed variables, as well as the latest forcing data. This function is a core component of the SINDBAD framework's time-stepping process
    """
    function compute(params::LandEcosystem, forcing, land, helpers)
        return land
    end

    """
        define(params<:LandEcosystem, forcing, land, helpers)

    Define and initialize arrays and variables for a SINDBAD model or approach.

    # Description
    The `define` function is responsible for defining and initializing arrays for variables of pools or states that are required for a SINDBAD model or approach. It is typically called once to set up ```memory-allocating``` variables whose values can be overwritten during model computations.

    # Arguments
    - `params`: The parameter structure for the specific SINDBAD model or approach.
    - `forcing`: External forcing data required for the model or approach.
    - `land`: The land model state, which includes pools, diagnostics, and properties.
    - `helpers`: Additional helper functions or data required for initialization.

    # Returns
    - The updated `land` model state with defined arrays and variables.

    # Behavior
    - For each SINDBAD model or approach, the `define` function initializes arrays and variables based on the specific requirements of the model or approach.
    - It may include operations like unpacking parameters, defining arrays, or setting default values for variables.
    - This function is typically used to prepare the land model state for subsequent computations.
    - It is called once at the beginning of the simulation to set up the necessary variables. So, any variable whole values are changing based on model parameters so actually be overwritten in the precompute or compute function.
    """
    function define(params::LandEcosystem, forcing, land, helpers)
        return land
    end

    """
        precompute(params<:LandEcosystem, forcing, land, helpers)

    Update defined variables and arrays with new realizations of a SINDBAD model or approach.

    # Description
    The `precompute` function is responsible for updating previously defined arrays, variables, or states with new realizations of a SINDBAD model or approach. It uses updated parameters, forcing data, and helper functions to modify the land model state. This function ensures that the model is prepared for subsequent computations with the latest parameter values and external inputs.

    # Arguments
    - `params`: The parameter structure for the specific SINDBAD model or approach.
    - `forcing`: External forcing data required for the model or approach.
    - `land`: The land model state, which includes pools, diagnostics, and properties.
    - `helpers`: Additional helper functions or data required for updating variables.

    # Returns
    - The updated `land` model state with modified arrays and variables.

    # Behavior
    - For each SINDBAD model or approach, the `precompute` function updates variables and arrays based on the specific requirements of the model or approach.
    - It may include operations like recalculating variables, applying parameter changes, or modifying arrays to reflect new realizations of the model.
    - This function is typically used to prepare the land model state for time-dependent computations.

    # Example
    ```julia
    # Example usage for a specific model
    land = precompute(params::ambientCO2_constant, forcing, land, helpers)
    ```
    ---
    # Extended help
    The precompute function is essential for SINDBAD models and approaches that require dynamic updates to variables and arrays based on new parameter values or forcing data. It ensures that the land model state is properly updated and ready for further computations, such as compute or update.
    """
    function precompute(params::LandEcosystem, forcing, land, helpers)
        return land
    end

    """
        update(params<:LandEcosystem, forcing, land, helpers)

    Update the model pools and variables within a single time step when activated via ```inline_update``` in experiment_json.

    # Description
    The `update` function is responsible for modifying the pools of a SINDBAD model or approach within a single time step. It uses the latest forcing data, precomputed variables, and defined parameters to update the pools. This means that the model pools, typically of the water cycle, are updated before the next processes are called.

    # Arguments
    - `params`: The parameter structure for the specific SINDBAD model or approach.
    - `forcing`: External forcing data required for the model or approach.
    - `land`: The land model state, which includes pools, diagnostics, and properties.
    - `helpers`: Additional helper functions or data required for computations.

    # Returns
    - The updated `land` model pool with changes applied for the current time step.

    # Behavior
    - For each SINDBAD model or approach, the `update` function modifies the pools and state variables based on the specific requirements of the model or approach. 
    - It may include operations like adjusting carbon or water pools, recalculating fluxes, or updating diagnostics based on the current time step's inputs and conditions.
    - This function is typically called iteratively during the simulation to reflect time-dependent changes.

    # Example
    ```julia
    # Example usage for a specific model
    land = update(params::ambientCO2_constant, forcing, land, helpers)
    ```
    # Notes:
    The update function is essential for SINDBAD models and approaches that require dynamic updates to the land model state within a single time step. It ensures that the model accurately reflects the changes occurring during the current time step, based on the latest forcing data and precomputed variables. This function is a core component of the SINDBAD framework's time-stepping process.
    """
    function update(params::LandEcosystem, forcing, land, helpers)
        return land
    end

    # include the utility functions for the model processes
    include(joinpath(@__DIR__, "Processes/landUtils.jl"))

    # Import all models: developed by @lalonso
    all_folders = readdir(joinpath(@__DIR__, "Processes/"))
    all_dir_models = filter(entry -> isdir(joinpath(@__DIR__, "Processes", entry)), all_folders)
    for model_name ∈ all_dir_models
        model_path = joinpath(@__DIR__, "Processes", model_name, model_name * ".jl")
        include(model_path)
    end

    # now having this ordered list is independent from the step including the models into this `module`.
    include(joinpath(@__DIR__, "Processes/standardSindbadTEM.jl"))
    
    # include the run functions for the methods of the TEM processes
    include(joinpath(@__DIR__, "Methods.jl"))

end
