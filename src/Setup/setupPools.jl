export createInitPools
export createInitStates
export resolvePoolStructure
export setPoolsInfo

"""
    POOL_ELEMENT_PROCESS

Which process owns each pool element, for resolving a JSON block's aliases from the
approach that is actually selected. Only `carbon` has configurations today;
`wCycleBase_simple` declares none, so `water` keeps whatever its block says.
"""
const POOL_ELEMENT_PROCESS = (; carbon = :cCycleBase, water = :wCycleBase)

"""
    generatedPoolNames(structure)

Return `(leaf_names, group_names)` for a pool structure: the names
`getPoolInformation` flattens it into, and the intermediate nesting levels that
become groups. Every nesting level is a real pool with its own `zix` entry, so a
two-level layout yields `cVegRoot` alongside `cVegRootFine`.
"""
function generatedPoolNames(structure)
    components = getfield(structure, :components)
    _, _, _, _, sub_pool_name, main_pool_name =
        getPoolInformation(Symbol.(keys(components)), components, Float64[], Int64[], Int64[], [], Symbol[], Symbol[])
    return unique(sub_pool_name), unique(main_pool_name)
end

"""
    carbonPoolNames()

Every carbon pool name any configuration can produce: the leaves and groups of each
`CarbonPoolConfiguration`'s structure, plus the alias names its nesting cannot
generate.

`setPoolsInfo` emits a `zix` entry for each, so a name a configuration lacks resolves
to `()` rather than a missing field. A loop over an empty entry runs zero times,
statically, which is why models iterate `helpers.pools.zix.X` without an `isempty`
branch.

# Notes:
- Derived rather than listed. This replaced a hand-written tuple of all 27 names, which
  a new configuration had to be added to by hand: miss that edit and the name was
  simply absent from `zix`, and the first model to reach for it failed on a missing
  field far from the cause. Declaring the structure is now the only step.
- Lives here rather than beside the configurations because it needs
  `getPoolInformation`, and `Sindbad.Setup` depends on `SindbadTEM` and not the other
  way round. It also sits next to its only caller.
- Enumeration is `subtypes`, so a configuration file that is written but never included
  contributes nothing.
"""
function carbonPoolNames()
    names = Symbol[]
    for configuration ∈ SindbadTEM.subtypes(SindbadTEM.Processes.CarbonPoolConfiguration)
        structure = poolStructure(configuration)
        isnothing(structure) && continue
        leaves, groups = generatedPoolNames(structure)
        append!(names, groups)
        append!(names, leaves)
        append!(names, propertynames(poolAliases(configuration)))
    end
    return Tuple(unique(names))
end

"""
    poolConfigurationFor(info, element, spec)

Resolve a string in a `pools` block to a pool configuration.

A string naming a process (`"cCycleBase"`) resolves through that process's selected
approach in `models`; any other string is taken as an approach type name directly.
Errors name what was tried rather than surfacing an `UndefVarError`.
"""
function poolConfigurationFor(info::NamedTuple, element, spec::AbstractString)
    models = info.settings.model_structure.models
    sym = Symbol(spec)
    approach_name = if hasproperty(models, sym)
        Symbol(spec * "_" * string(getproperty(getproperty(models, sym), :approach)))
    else
        sym
    end
    if !hasproperty(SindbadTEM.Processes, approach_name)
        error("pools.$(element) is set to `$(spec)`, which resolves to the approach " *
              "`$(approach_name)`, but no such approach exists in SindbadTEM.Processes. Set " *
              "pools.$(element) to a process name whose approach is selected in `models`, to an " *
              "approach name, or write the pool block out in full.")
    end
    approach_type = getproperty(SindbadTEM.Processes, approach_name)
    configuration = poolConfiguration(approach_type)
    if isnothing(configuration)
        error("pools.$(element) is set to `$(spec)`, which resolves to the approach " *
              "`$(approach_name)`, but that approach declares no poolConfiguration. Add " *
              "`poolConfiguration(::Type{$(approach_name)}) = <a configuration>` beside its " *
              "purpose, or write the pool block out in full.")
    end
    return approach_name, configuration
end

"""
    validatePoolStructure(element, structure, aliases)

Check an element's aliases against the structure they are declared over: every target
must be a pool the structure actually has, and an alias may not shadow a name the
nesting already generates, which would otherwise silently replace real indices.
"""
function validatePoolStructure(element, structure, aliases)
    leaves, groups = generatedPoolNames(structure)
    known = vcat(leaves, groups)
    for alias in propertynames(aliases)
        if alias in known
            error("pools.$(element) declares the alias `$(alias)`, but the pool structure already " *
                  "generates a pool of that name. Remove the alias; the nesting covers it.")
        end
        targets = getproperty(aliases, alias)
        for target in targets
            if target ∉ known
                error("pools.$(element) declares the alias `$(alias) = $(targets)`, but " *
                      "`$(target)` is not a pool of this structure. Known pools: " *
                      "$(join(sort(String.(known)), ", ")).")
            end
        end
    end
    return nothing
end

"""
    resolvePoolStructure(info::NamedTuple)

Normalize every element of `model_structure.pools` into one shape, so that nothing
downstream knows or cares whether a structure was written out in the JSON or named as
a configuration.

Each element resolves to its own block plus an `aliases` field; anything else the
block carried, `state_variables` included, is passed through untouched.

An element's value may be:

- a **String**: structure and aliases both come from the configuration it names.
- a **NamedTuple**: the block supplies the structure verbatim. Aliases come from its
  own `aliases` key if it has one, otherwise from the configuration of the approach
  selected for that element's process. In that second case the block's pool names
  must match the configuration's, because aliases resolved elsewhere would otherwise
  point at pools the block does not have.

`poolConfiguration` is consulted here and nowhere else. After this, `helpers.pools`
is the sole interface between setup and the models.
"""
function resolvePoolStructure(info::NamedTuple)
    pools = info.settings.model_structure.pools
    resolved = (;)
    for element ∈ propertynames(pools)
        block = getproperty(pools, element)
        if isa(block, AbstractString)
            _, configuration = poolConfigurationFor(info, element, block)
            structure = poolStructure(configuration)
            if isnothing(structure)
                error("pools.$(element) resolves to the configuration `$(nameof(configuration))`, " *
                      "which declares no poolStructure.")
            end
            aliases = poolAliases(configuration)
        else
            structure = block
            aliases = hasproperty(block, :aliases) ? block.aliases : (;)
            if !hasproperty(block, :aliases) && hasproperty(POOL_ELEMENT_PROCESS, element)
                process = getproperty(POOL_ELEMENT_PROCESS, element)
                models = info.settings.model_structure.models
                if hasproperty(models, process)
                    approach_name = Symbol(String(process) * "_" * string(getproperty(getproperty(models, process), :approach)))
                    if hasproperty(SindbadTEM.Processes, approach_name)
                        configuration = poolConfiguration(getproperty(SindbadTEM.Processes, approach_name))
                        if !isnothing(configuration) && !isnothing(poolStructure(configuration))
                            aliases = poolAliases(configuration)
                            if !isempty(aliases)
                                block_leaves, _ = generatedPoolNames(block)
                                config_leaves, _ = generatedPoolNames(poolStructure(configuration))
                                if Set(block_leaves) != Set(config_leaves)
                                    error("pools.$(element) is written out in full, and its aliases are " *
                                          "taken from `$(nameof(configuration))`, but the two disagree on " *
                                          "which pools exist. Only in the block: " *
                                          "$(join(sort(String.(setdiff(block_leaves, config_leaves))), ", ")). " *
                                          "Only in the configuration: " *
                                          "$(join(sort(String.(setdiff(config_leaves, block_leaves))), ", ")). " *
                                          "Declare an `aliases` key in the block, or match the configuration.")
                                end
                            end
                        end
                    end
                end
            end
        end
        validatePoolStructure(element, structure, aliases)
        resolved = set_namedtuple_field(resolved, (Symbol(element), (; structure..., aliases=aliases)))
    end
    return resolved
end

"""
    setPoolsInfo(info::NamedTuple)

Generates `info.temp.helpers.pools` and `info.pools`. 

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.

# Returns:
- The updated `info` NamedTuple with pool-related fields added.

# Notes:
- `info.temp.helpers.pools` is used in the models.
- `info.pools` is used for instantiating the pools for the initial output tuple.
"""
function setPoolsInfo(info::NamedTuple)
    print_info(setPoolsInfo, @__FILE__, @__LINE__, "setting Pools Info...")
    # after this, the source of the structure stops mattering: everything below reads
    # the resolved blocks, never info.settings.model_structure.pools
    resolved_pools = resolvePoolStructure(info)
    elements = propertynames(resolved_pools)
    tmp_states = (;)
    hlp_states = (;)
    model_array_type = getfield(Types, to_uppercase_first(info.settings.experiment.exe_rules.model_array_type, "ModelArray"))()
    num_type = info.temp.helpers.numbers.num_type
    for element ∈ elements
        vals_tuple = (;)
        vals_tuple = set_namedtuple_field(vals_tuple, (:zix, (;)))
        vals_tuple = set_namedtuple_field(vals_tuple, (:self, (;)))
        vals_tuple = set_namedtuple_field(vals_tuple, (:all_components, (;)))
        elSymbol = Symbol(element)
        tmp_elem = (;)
        hlp_elem = (;)
        tmp_states = set_namedtuple_field(tmp_states, (elSymbol, (;)))
        hlp_states = set_namedtuple_field(hlp_states, (elSymbol, (;)))
        resolved_elem = getproperty(resolved_pools, Symbol(element))
        pool_info = getfield(resolved_elem, :components)
        nlayers = Int64[]
        layer_thicknesses = num_type[]
        layer = Int64[]
        inits = []
        sub_pool_name = Symbol[]
        main_pool_name = Symbol[]
        main_pools = Symbol.(keys(pool_info))
        layer_thicknesses, nlayers, layer, inits, sub_pool_name, main_pool_name = getPoolInformation(main_pools, pool_info, layer_thicknesses, nlayers, layer, inits, sub_pool_name, main_pool_name)

        # set empty tuple fields
        tpl_fields = (:components, :zix, :initial_values, :layer_thickness)
        for _tpl ∈ tpl_fields
            tmp_elem = set_namedtuple_field(tmp_elem, (_tpl, (;)))
        end
        hlp_elem = set_namedtuple_field(hlp_elem, (:layer_thickness, (;)))
        # hlp_elem = set_namedtuple_field(hlp_elem, (:n_layers, (;)))
        hlp_elem = set_namedtuple_field(hlp_elem, (:zix, (;)))
        hlp_elem = set_namedtuple_field(hlp_elem, (:components, (;)))
        hlp_elem = set_namedtuple_field(hlp_elem, (:all_components, (;)))
        hlp_elem = set_namedtuple_field(hlp_elem, (:zeros, (;)))
        hlp_elem = set_namedtuple_field(hlp_elem, (:ones, (;)))

        # main pools
        for main_pool ∈ main_pool_name
            zix = Int[]
            initial_values = []
            # initial_values = num_type[]
            components = Symbol[]
            for (ind, par) ∈ enumerate(sub_pool_name)
                if startswith(String(par), String(main_pool))
                    push!(zix, ind)
                    push!(components, sub_pool_name[ind])
                    push!(initial_values, inits[ind])
                end
            end
            initial_values = createArrayofType(initial_values, Nothing[], num_type, nothing, true, model_array_type)

            zix = Tuple(zix)

            tmp_elem = set_namedtuple_subfield(tmp_elem, :components, (main_pool, Tuple(components)))
            tmp_elem = set_namedtuple_subfield(tmp_elem, :zix, (main_pool, zix))
            tmp_elem = set_namedtuple_subfield(tmp_elem, :initial_values, (main_pool, initial_values))
            # hlp_elem = set_namedtuple_subfield(hlp_elem, :n_layers, (main_pool, length(zix)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :zix, (main_pool, zix))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :components, (main_pool, Tuple(components)))
            onetyped = createArrayofType(ones(size(initial_values)), Nothing[], num_type, nothing, true, model_array_type)
            hlp_elem = set_namedtuple_subfield(hlp_elem, :zeros, (main_pool, zero(onetyped)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :ones, (main_pool, onetyped))
        end

        # subpools
        unique_sub_pools = Symbol[]
        for _sp ∈ sub_pool_name
            if _sp ∉ unique_sub_pools
                push!(unique_sub_pools, _sp)
            end
        end
        for sub_pool ∈ unique_sub_pools
            zix = Int[]
            initial_values = []
            components = Symbol[]
            ltck = num_type[]
            # ltck = []
            for (ind, par) ∈ enumerate(sub_pool_name)
                if par == sub_pool
                    push!(zix, ind)
                    push!(initial_values, inits[ind])
                    push!(components, sub_pool_name[ind])
                    push!(ltck, layer_thicknesses[ind])
                end
            end
            zix = Tuple(zix)
            initial_values = createArrayofType(initial_values, Nothing[], num_type, nothing, true, model_array_type)
            tmp_elem = set_namedtuple_subfield(tmp_elem, :components, (sub_pool, Tuple(components)))
            tmp_elem = set_namedtuple_subfield(tmp_elem, :zix, (sub_pool, zix))
            tmp_elem = set_namedtuple_subfield(tmp_elem, :initial_values, (sub_pool, initial_values))
            tmp_elem = set_namedtuple_subfield(tmp_elem, :layer_thickness, (sub_pool, Tuple(ltck)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :layer_thickness, (sub_pool, Tuple(ltck)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :zix, (sub_pool, zix))
            # hlp_elem = set_namedtuple_subfield(hlp_elem, :n_layers, (sub_pool, length(zix)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :components, (sub_pool, Tuple(components)))
            onetyped = createArrayofType(ones(size(initial_values)), Nothing[], num_type, nothing, true, model_array_type)
            # onetyped = ones(length(initial_values))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :zeros, (sub_pool, zero(onetyped)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :ones, (sub_pool, onetyped))
        end

        ## combined pools
        combine_pools = getfield(resolved_elem, :combine)
        do_combine = true
        tmp_elem = set_namedtuple_field(tmp_elem, (:combine, (; docombine=true, pool=Symbol(combine_pools))))
        if do_combine
            combined_pool_name = Symbol.(combine_pools)
            create = Symbol[combined_pool_name]
            components = Symbol[]
            for _sp ∈ sub_pool_name
                if _sp ∉ components
                    push!(components, _sp)
                end
            end
            initial_values = inits
            initial_values = createArrayofType(initial_values, Nothing[], num_type, nothing, true, model_array_type)
            zix = collect(1:1:length(main_pool_name))
            zix = Tuple(zix)

            tmp_elem = set_namedtuple_subfield(tmp_elem, :components, (combined_pool_name, Tuple(components)))
            tmp_elem = set_namedtuple_subfield(tmp_elem, :zix, (combined_pool_name, zix))
            tmp_elem = set_namedtuple_subfield(tmp_elem, :initial_values, (combined_pool_name, initial_values))
            # hlp_elem = set_namedtuple_subfield(hlp_elem, :n_layers, (combined_pool_name, length(zix)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :zix, (combined_pool_name, zix))
            onetyped = createArrayofType(ones(size(initial_values)), Nothing[], num_type, nothing, true, model_array_type)
            all_components = Tuple([_k for _k in keys(tmp_elem.zix) if _k !== combined_pool_name])
            hlp_elem = set_namedtuple_subfield(hlp_elem, :all_components, (combined_pool_name, all_components))
            vals_tuple = set_namedtuple_subfield(vals_tuple, :zix, (combined_pool_name, Val(hlp_elem.zix)))
            vals_tuple = set_namedtuple_subfield(vals_tuple, :self, (combined_pool_name, Val(combined_pool_name)))
            vals_tuple = set_namedtuple_subfield(vals_tuple, :all_components, (combined_pool_name, Val(all_components)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :components, (combined_pool_name, Tuple(components)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :zeros, (combined_pool_name, zero(onetyped)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :ones, (combined_pool_name, onetyped))
        else
            create = Symbol.(unique_sub_pools)
        end

        # check if additional variables exist
        if hasproperty(resolved_elem, :state_variables)
            state_variables = getfield(resolved_elem, :state_variables)
            tmp_elem = set_namedtuple_field(tmp_elem, (:state_variables, state_variables))
        end
        arraytype = :view
        if hasproperty(info.settings.experiment.exe_rules, :model_array_type)
            arraytype = Symbol(info.settings.experiment.exe_rules.model_array_type)
        end
        tmp_elem = set_namedtuple_field(tmp_elem, (:arraytype, arraytype))
        tmp_elem = set_namedtuple_field(tmp_elem, (:create, create))

        # aliases: groupings that cut across the nesting, so they cannot be a nesting
        # level. hlp_elem only -- an alias has no backing array, so keeping it out of
        # tmp_elem keeps it out of `create`, `initial_values`, `all_components` and
        # `n_layers`.
        for alias ∈ propertynames(getfield(resolved_elem, :aliases))
            targets = getproperty(getfield(resolved_elem, :aliases), alias)
            alias_zix = Tuple(sort(vcat([collect(getproperty(hlp_elem.zix, t)) for t ∈ targets]...)))
            hlp_elem = set_namedtuple_subfield(hlp_elem, :zix, (alias, alias_zix))
        end

        # the Vals built alongside the combined pool are what the generated
        # setComponentFromMainPool dispatches on, so they have to travel with the
        # element
        hlp_elem = set_namedtuple_field(hlp_elem, (:vals, vals_tuple))
        tmp_states = set_namedtuple_field(tmp_states, (elSymbol, tmp_elem))
        hlp_states = set_namedtuple_field(hlp_states, (elSymbol, hlp_elem))
    end
    hlp_new = (;)
    # tc_print(hlp_states)
    eleprops = propertynames(hlp_states)
    if :carbon in eleprops && :water in eleprops
        for prop ∈ propertynames(hlp_states.carbon)
            cfield = getproperty(hlp_states.carbon, prop)
            wfield = getproperty(hlp_states.water, prop)
            cwfield = (; cfield..., wfield...)
            if prop == :vals
                cwfield = (;)
                for subprop in propertynames(cfield)
                    csub = getproperty(cfield, subprop)
                    wsub = getproperty(wfield, subprop)
                    cwfield = set_namedtuple_field(cwfield, (subprop, (; csub..., wsub...)))
                end
            end
            hlp_new = set_namedtuple_field(hlp_new, (prop, cwfield))
        end
    elseif :carbon in eleprops && :water ∉ eleprops
        hlp_new = hlp_states.carbon
    elseif :carbon ∉ eleprops && :water in eleprops
        hlp_new = hlp_states.water
    else
        hlp_new = hlp_states
    end

    # Every carbon pool name resolves, to real indices or to (), whatever the
    # structure. An empty entry iterates zero times, statically, which is why models
    # loop over helpers.pools.zix.X with no isempty branch and why a new pool needs no
    # model edit -- the names come from the configurations themselves, see
    # carbonPoolNames.  Filled here rather than per element on
    # purpose: the carbon+water merge above is `(; carbon..., water...)`, so water
    # wins on any shared key, and a per-element skeleton would have water's empty
    # entries overwrite carbon's real indices. Doing it after the merge also covers a
    # model structure with no carbon element at all, where the merge takes
    # hlp_states.water wholesale.
    for pool_name ∈ carbonPoolNames()
        if !hasproperty(hlp_new.zix, pool_name)
            hlp_new = set_namedtuple_subfield(hlp_new, :zix, (pool_name, ()))
        end
    end

    # get the number of layers per pool 
    n_layers = NamedTuple(map(propertynames(hlp_new.ones)) do one_pool
        n_pool = num_type(length(getproperty(hlp_new.ones, one_pool)))
        Pair(one_pool, n_pool)
    end
    )
    hlp_new = (hlp_new..., n_layers=n_layers)

    # provenance: info.settings.model_structure.pools stays exactly as the user wrote
    # it, so the saved settings still read "carbon": "cCycleBase"; pool_structure
    # records what that resolved to, so an output directory documents the structure
    # actually run.
    info = (; info..., pools=tmp_states, pool_structure=resolved_pools,
        temp=(; info.temp..., helpers=(; info.temp.helpers..., pools=hlp_new)))
    return info
end

"""
    createInitPools(info_pools::NamedTuple, tem_helpers::NamedTuple)

Creates a NamedTuple with initial pool variables as subfields, used in `land.pools`.

# Arguments:
- `info_pools`: A NamedTuple containing pool information from the experiment configuration.
- `tem_helpers`: A NamedTuple containing helper information for numerical operations.

# Returns:
- A NamedTuple with initialized pool variables.
"""
function createInitPools(info_pools::NamedTuple, tem_helpers::NamedTuple)
    init_pools = (;)
    for element ∈ propertynames(info_pools)
        props = getfield(info_pools, element)
        model_array_type = getfield(Types, to_uppercase_first(string(getfield(props, :arraytype)), "ModelArray"))()
        var_to_create = getfield(props, :create)
        initial_values = getfield(props, :initial_values)
        for tocr ∈ var_to_create
            input_values = deepcopy(getfield(initial_values, tocr))
            init_pools = set_namedtuple_field(init_pools, (tocr, createArrayofType(input_values, Nothing[], tem_helpers.numbers.num_type, nothing, true, model_array_type)))
        end
        to_combine = getfield(getfield(info_pools, element), :combine)
        if to_combine.docombine
            combined_pool_name = to_combine.pool
            zix_pool = getfield(props, :zix)
            components = keys(zix_pool)
            pool_array = getfield(init_pools, combined_pool_name)
            for component ∈ components
                if component != combined_pool_name
                    indx = getfield(zix_pool, component)
                    input_values = deepcopy(getfield(initial_values, component))
                    compdat = createArrayofType(input_values, pool_array, tem_helpers.numbers.num_type, indx, false, model_array_type)
                    init_pools = set_namedtuple_field(init_pools, (component, compdat))
                end
            end
        end
    end
    return init_pools
end

"""
    createInitStates(info_pools::NamedTuple, tem_helpers::NamedTuple)

Creates a NamedTuple with initial state variables as subfields, used in `land.states`.

# Arguments:
- `info_pools`: A NamedTuple containing pool information from the experiment configuration.
- `tem_helpers`: A NamedTuple containing helper information for numerical operations.

# Returns:
- A NamedTuple with initialized state variables.

# Notes:
- Extended from `createInitPools``
- State variables are derived from the `state_variables` field in `model_structure.json`.
"""
function createInitStates(info_pools::NamedTuple, tem_helpers::NamedTuple)
    initial_states = (;)
    for element ∈ propertynames(info_pools)
        props = getfield(info_pools, element)
        var_to_create = getfield(props, :create)
        additional_state_vars = (;)
        if hasproperty(props, :state_variables)
            additional_state_vars = getfield(props, :state_variables)
        end
        initial_values = getfield(props, :initial_values)
        model_array_type = getfield(Types, to_uppercase_first(string(getfield(props, :arraytype)), "ModelArray"))()
        for tocr ∈ var_to_create
            for avk ∈ keys(additional_state_vars)
                avv = getproperty(additional_state_vars, avk)
                Δtocr = Symbol(string(avk) * string(tocr))
                vals = one.(getfield(initial_values, tocr)) *                                 tem_helpers.numbers.num_type(avv)
                newvals = createArrayofType(vals, Nothing[], tem_helpers.numbers.num_type, nothing, true, model_array_type)
                initial_states = set_namedtuple_field(initial_states, (Δtocr, newvals))
            end
        end
        to_combine = getfield(getfield(info_pools, element), :combine)
        if to_combine.docombine
            combined_pool_name = Symbol(to_combine.pool)
            for avk ∈ keys(additional_state_vars)
                avv = getproperty(additional_state_vars, avk)
                Δ_combined_pool_name = Symbol(string(avk) * string(combined_pool_name))
                zix_pool = getfield(props, :zix)
                components = keys(zix_pool)
                Δ_pool_array = getfield(initial_states, Δ_combined_pool_name)
                for component ∈ components
                    if component != combined_pool_name
                        Δ_component = Symbol(string(avk) * string(component))
                        indx = getfield(zix_pool, component)
                        Δ_compdat = createArrayofType((one.(getfield(initial_values, component))) .* tem_helpers.numbers.num_type(avv), Δ_pool_array, tem_helpers.numbers.num_type, indx, false, model_array_type)
                        initial_states = set_namedtuple_field(initial_states, (Δ_component, Δ_compdat))
                    end
                end
            end
        end
    end
    return initial_states
end


"""
    getPoolInformation(main_pools, pool_info, layer_thicknesses, nlayers, layer, inits, sub_pool_name, main_pool_name; prename="")

A helper function to get the information of each pools from info.settings.model_structure.pools and puts them into arrays of information needed to instantiate pool variables.

# Arguments:
- `main_pools`: A list of main pool configurations.
- `pool_info`: A NamedTuple containing pool information details.
- `layer_thicknesses`: An array of layer thicknesses in the pools.
- `nlayers`: An array representing the number of layers per pool in the model.
- `layer`: An array representing the current layer number being processed.
- `inits`: An array of initial values to be set in the pool.
- `sub_pool_name`: An array of sub-pool component names for a given pool.
- `main_pool_name`: An array of main pool names containing the sub-pool components.
- `prename`: (Optional) A prefix for naming conventions (default: `""`).

# Returns:
- Updated list of information specific to the requested pool configuration.

# Notes:
- Processes hierarchical pool structures and extracts relevant details for initialization.
"""
function getPoolInformation(main_pools, pool_info, layer_thicknesses, nlayers, layer, inits, sub_pool_name, main_pool_name; prename="")
    for main_pool ∈ main_pools
        prefix = prename
        main_pool_info = getproperty(pool_info, main_pool)
        if !isa(main_pool_info, NamedTuple)
            if isa(main_pool_info[1], Number)
                lenpool = main_pool_info[1]
                # layer_thickness = repeat([nothing], lenpool)
                layer_thickness = (main_pool_info[1])
            else
                lenpool = length(main_pool_info[1])
                layer_thickness = (main_pool_info[1])
            end

            append!(layer_thicknesses, layer_thickness)
            append!(nlayers, fill(1, lenpool))
            append!(layer, collect(1:lenpool))
            append!(inits, fill((main_pool_info[2]), lenpool))

            if prename == ""
                append!(sub_pool_name, fill(main_pool, lenpool))
                append!(main_pool_name, fill(main_pool, lenpool))
            else
                append!(sub_pool_name, fill(Symbol(String(prename) * string(main_pool)), lenpool))
                append!(main_pool_name, fill(Symbol(String(prename)), lenpool))
            end
        else
            prefix = prename * String(main_pool)
            sub_pools = propertynames(main_pool_info)
            layer_thicknesses, nlayers, layer, inits, sub_pool_name, main_pool_name =
                getPoolInformation(sub_pools, main_pool_info, layer_thicknesses, nlayers, layer, inits, sub_pool_name, main_pool_name; prename=prefix)
        end
    end
    return layer_thicknesses, nlayers, layer, inits, sub_pool_name, main_pool_name
end
