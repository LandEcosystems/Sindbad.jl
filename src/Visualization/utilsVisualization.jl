export namedTupleToFlareJSON

"""
    getAllVariables(in_out_models, which_field)

Extracts all unique variables from the input-output of the models in selected model structure for the specified field(s).

# Arguments
- `in_out_models`: A dictionary containing input-output of models, where keys are model names and values are dictionaries of fields (e.g., `:input`, `:output`).
- `which_field`: A `Symbol` or an array of `Symbol`s specifying the field(s) to extract variables from (e.g., `:input`, `:output`).

# Returns
- A sorted array of unique variables across all specified fields.

# Examples
```jldoctest
julia> using Sindbad

julia> in_out_models = Dict(
           :model1 => Dict(:input => [:var1, :var2], :output => [:var3]),
           :model2 => Dict(:input => [:var2, :var4], :output => [:var5])
       )
Dict{Symbol, Dict{Symbol, Vector{Symbol}}} with 2 entries:
  :model1 => Dict(:input=>[:var1, :var2], :output=>[:var3])
  :model2 => Dict(:input=>[:var2, :var4], :output=>[:var5])

julia> unique_vars = getAllVariables(in_out_models, [:input, :output])
5-element Vector{Symbol}:
 :var1
 :var2
 :var3
 :var4
 :var5
```
"""
function getAllVariables(in_out_models, which_field)
    if isa(which_field, Symbol)
        which_field = [which_field]
    end
    unique_variables = map(which_field) do wf
        collect(sort(unique(vcat([[(in_out_models[model][wf])...] for model in keys(in_out_models)]...))))
    end
    unique_variables = sort(unique(vcat(unique_variables...)))
    return unique_variables
end

"""
    namedTupleToFlareJSON(info::NamedTuple)

Convert a nested NamedTuple into a flare.json format suitable for d3.js visualization.

# Arguments
- `info::NamedTuple`: The input NamedTuple to convert

# Returns
- A dictionary in flare.json format with the following structure:
  ```json
  {
    "name": "root",
    "children": [
      {
        "name": "field1",
        "children": [...]
      },
      {
        "name": "field2",
        "value": 42
      }
    ]
  }
  ```

# Notes
- The function recursively traverses the NamedTuple structure
- Fields with no children are treated as leaf nodes with a value of 1
- The structure is flattened to show the full path to each field

# Examples
```jldoctest
julia> using Sindbad

julia> # Convert experiment info to flare.json format
julia> # flare_json = namedTupleToFlareJSON(info)
```
"""
function namedTupleToFlareJSON(info::NamedTuple)
    function _convert_to_flare(nt::NamedTuple, name="sindbad_info")
        children = []
        for field in propertynames(nt)
            value = getfield(nt, field)
            if value isa NamedTuple
                push!(children, _convert_to_flare(value, string(field)))
            else
                # println("field: $field, value: $value")
                push!(children, Dict("name" => string(field), "value" => 1))
            end
        end
        return Dict("name" => name, "children" => children)
    end

    return _convert_to_flare(info)
end
