export spinup
export spinupTEM
export runSpinupSequences
export timeLoopTEMSpinup

"""
    (cEco_spin::Spinup_cEco)(pout, p)

Custom callable type function for spinning up cEco.

# Arguments
- `pout`: Output pools
- `p`: Input pools

# Note
This method allows a `Spinup_cEco` object to be called as a function, implementing the specific spinup logic for ecosystem carbon pools.
"""
function (cEco_spin::Spinup_cEco)(pout, p)
    land = cEco_spin.land
    helpers = cEco_spin.tem_info.model_helpers
    n_timesteps = cEco_spin.n_timesteps
    zix = helpers.pools.zix

    pout .= exp.(p)

    cEco = land.pools.cEco
    for (lc, l) in enumerate(zix.cEco)
        @rep_elem pout[l] ⇒ (cEco, lc)
    end
    @pack_nt cEco ⇒ land.pools
    land = SindbadTEM.adjustPackPoolComponents(land, helpers, land.models.c_model)
    update_init = timeLoopTEMSpinup(cEco_spin.models, cEco_spin.forcing, cEco_spin.loc_forcing_t, land, cEco_spin.tem_info, n_timesteps)

    pout .= log.(update_init.pools.cEco)
    return nothing
end

"""
    (cEco_TWS_spin::Spinup_cEco_TWS)(pout, p)

Custom callable type function for spinning up cEco and TWS pools.

# Arguments
- `pout`: Output pools
- `p`: Input pools

# Note
This method allows a `Spinup_cEco_TWS` object to be called as a function, implementing the specific spinup logic for ecosystem carbon pools and the terrestrial water storage components.
"""
function (cEco_TWS_spin::Spinup_cEco_TWS)(pout, p)
    land = cEco_TWS_spin.land
    helpers = cEco_TWS_spin.tem_info.model_helpers
    n_timesteps = cEco_TWS_spin.n_timesteps
    zix = helpers.pools.zix

    pout .= exp.(p)

    cEco = land.pools.cEco
    for (lc, l) in enumerate(zix.cEco)
        @rep_elem pout[l] ⇒ (cEco, lc)
    end
    @pack_nt cEco ⇒ land.pools
    land = SindbadTEM.adjustPackPoolComponents(land, helpers, land.models.c_model)

    TWS = land.pools.TWS
    TWS_prev = cEco_TWS_spin.TWS
    for (lc, l) in enumerate(zix.TWS)
        @rep_elem TWS_prev[l] ⇒ (TWS, lc, :TWS)
    end

    @pack_nt TWS ⇒ land.pools
    land = SindbadTEM.adjustPackPoolComponents(land, helpers, land.models.w_model)

    update_init = timeLoopTEMSpinup(cEco_TWS_spin.models, cEco_TWS_spin.forcing, cEco_TWS_spin.loc_forcing_t, land, cEco_TWS_spin.tem_info, n_timesteps)

    pout .= log.(update_init.pools.cEco)
    cEco_TWS_spin.TWS .= update_init.pools.TWS
    return nothing
end


"""
    (TWS_spin::Spinup_TWS)(pout, p)

Custom callable type function for spinning up TWS pools.

# Arguments
- `pout`: Output pools
- `p`: Input pools

# Note
This method allows a `Spinup_TWS` object to be called as a function, implementing the specific spinup logic for the terrestrial water storage components.
"""
function (TWS_spin::Spinup_TWS)(pout, p)
    land = TWS_spin.land
    helpers = TWS_spin.tem_info.model_helpers
    n_timesteps = TWS_spin.n_timesteps
    zix = helpers.pools.zix

    TWS = land.pools.TWS
    for (lc, l) in enumerate(zix.TWS)
        @rep_elem at_least_zero(p[l]) ⇒ (TWS, lc, :TWS)
    end
    @pack_nt TWS ⇒ land.pools
    land = SindbadTEM.adjustPackPoolComponents(land, helpers, land.models.w_model)
    update_init = timeLoopTEMSpinup(TWS_spin.models, TWS_spin.forcing, TWS_spin.loc_forcing_t, land, TWS_spin.tem_info, n_timesteps)
    pout .= update_init.pools.TWS
    return nothing
end

"""
    spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, spinup_mode::SpinupMode)

Runs the spinup process for the SINDBAD Terrestrial Ecosystem Model (TEM) to initialize the model to a steady state. The spinup process updates the state variables (e.g., pools) using various spinup methods.

# Arguments:
- `spinup_models`: A tuple of a subset of all models in the given model structure that are selected for spinup.
- `spinup_forcing`: A forcing NamedTuple containing the time series of environmental drivers for the spinup process.
- `loc_forcing_t`: A forcing NamedTuple for a single location and a single time step.
- `land`: A SINDBAD NamedTuple containing all variables for a given time step, which is overwritten at every timestep.
- `tem_info`: A helper NamedTuple containing necessary objects for model execution and type consistencies.
- `n_timesteps`: The number of timesteps for the spinup process.
- `spinup_mode::SpinupMode`: A type dispatch that determines the spinup method to be used. 

# Returns:
- `land`: The updated SINDBAD NamedTuple containing the final state of the model after the spinup process.

$(methods_of(SpinupMode))

---

# Extended help

# Notes:
- The spinup process can use different methods depending on the `spinup_mode`, including fixed-point solvers, ODE solvers, and steady-state solvers.
- The function dynamically selects the appropriate spinup method based on the `spinup_mode` dispatch type.
- For ODE-based methods, the function uses DifferentialEquations.jl to solve the spinup equations.
- For steady-state solvers, the function uses methods like `DynamicSS` or `SSRootfind` to find equilibrium states.

# Examples:
1. **Running spinup with selected models**:
```julia
land = spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, LoopTEM())
```

2. **Running spinup with ODE solver (Tsit5)**:
```julia
land = spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, ODETsit5())
```

3. **Running spinup with fixed-point solver for cEco and TWS**:
```julia
land = spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, NlsolveFixedpointTrustregionCEcoTWS())
```

4. **Running spinup with steady-state solver (SSRootfind)**:
```julia
land = spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, SSPSSRootfind())
```
"""
function spinup(::Any, ::Any, ::Any, land, ::Any, ::Any, x::SpinupMode)
    @warn "
    Spinup mode `$(nameof(typeof(x)))` not implemented. 
    
    To implement a new spinup mode:
    
    - First add a new type as a subtype of `SpinupMode` in `src/Types/SimulationTypes.jl`. 
    
    - Then, add a corresponding method.
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/Simulation/spinupTEM.jl`.     
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/SimulationSpinup.jl` extension.

    
    As a fallback, this function will return the land as is.

    "
    return land
end

function spinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, ::LoopTEM)
    land = timeLoopTEMSpinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, tem_info.run.store_spinup)
    return land
end

function spinup(_, _, _, land, helpers, _, ::EtaScaleAH)
    @unpack_nt cEco ⇐ land.pools
    helpers = helpers.model_helpers
    cEco_prev = copy(cEco)
    ηH = one(eltype(cEco))
    if :ηH ∈ propertynames(land.diagnostics)
        ηH = land.diagnostics.ηH
    end
    ηA = one(eltype(cEco))
    if :ηA ∈ propertynames(land.diagnostics)
        ηA = land.diagnostics.ηA
    end
    for cSoilZix ∈ helpers.pools.zix.cSoil
        cSoilNew = cEco[cSoilZix] * ηH
        @rep_elem cSoilNew ⇒ (cEco, cSoilZix)
    end
    for cLitZix ∈ helpers.pools.zix.cLit
        cLitNew = cEco[cLitZix] * ηH
        @rep_elem cLitNew ⇒ (cEco, cLitZix)
    end
    for cVegZix ∈ helpers.pools.zix.cVeg
        cVegNew = cEco[cVegZix] * ηA
        @rep_elem cVegNew ⇒ (cEco, cVegZix)
    end
    @pack_nt cEco ⇒ land.pools
    land = SindbadTEM.adjustPackPoolComponents(land, helpers, land.models.c_model)
    @pack_nt cEco_prev ⇒ land.states
    return land
end


function spinup(_, _, _, land, helpers, _, ::EtaScaleAHCWD)
    @unpack_nt cEco ⇐ land.pools
    helpers = helpers.model_helpers
    cEco_prev = copy(cEco)
    ηH = one(eltype(cEco))
    if :ηH ∈ propertynames(land.diagnostics)
        ηH = land.diagnostics.ηH
    end
    ηA = one(eltype(cEco))
    if :ηA ∈ propertynames(land.diagnostics)
        ηA = land.diagnostics.ηA
    end
    for cLitZix ∈ helpers.pools.zix.cLitSlow
        cLitNew = cEco[cLitZix] * ηH
        @rep_elem cLitNew ⇒ (cEco, cLitZix)
    end
    for cVegZix ∈ helpers.pools.zix.cVeg
        cVegNew = cEco[cVegZix] * ηA
        @rep_elem cVegNew ⇒ (cEco, cVegZix)
    end
    @pack_nt cEco ⇒ land.pools
    land = SindbadTEM.adjustPackPoolComponents(land, helpers, land.models.c_model)
    @pack_nt cEco_prev ⇒ land.states
    return land
end


# Cuts every vegetation pool of cEco down to `land.states.c_remain`, or to one
# without it. ClearanceA0 followed by EtaScaleH changes the pools as EtaScaleA0H
# does.
function spinup(_, _, _, land, helpers, _, ::ClearanceA0)
    @unpack_nt cEco ⇐ land.pools
    helpers = helpers.model_helpers
    cEco_prev = copy(cEco)
    c_remain = one(eltype(cEco))
    if :c_remain ∈ propertynames(land.states)
        c_remain = land.states.c_remain
    end
    for cVegZix ∈ helpers.pools.zix.cVeg
        cLoss = at_least_zero(cEco[cVegZix] - c_remain)
        cVegNew = cEco[cVegZix] - cLoss
        @rep_elem cVegNew ⇒ (cEco, cVegZix)
    end
    @pack_nt cEco ⇒ land.pools
    land = SindbadTEM.adjustPackPoolComponents(land, helpers, land.models.c_model)
    @pack_nt cEco_prev ⇒ land.states
    return land
end


function spinup(_, _, _, land, helpers, _, ::EtaScaleA0H)
    @unpack_nt cEco ⇐ land.pools
    helpers = helpers.model_helpers
    cEco_prev = copy(cEco)
    ηH = one(eltype(cEco))
    c_remain = one(eltype(cEco))
    if :ηH ∈ propertynames(land.diagnostics)
        ηH = land.diagnostics.ηH
        c_remain = land.states.c_remain
    end
    for cSoilZix ∈ helpers.pools.zix.cSoil
        cSoilNew = cEco[cSoilZix] * ηH
        @rep_elem cSoilNew ⇒ (cEco, cSoilZix)
    end

    for cLitZix ∈ helpers.pools.zix.cLit
        cLitNew = cEco[cLitZix] * ηH
        @rep_elem cLitNew ⇒ (cEco, cLitZix)
    end

    for cVegZix ∈ helpers.pools.zix.cVeg
        cLoss = at_least_zero(cEco[cVegZix] - c_remain)
        cVegNew = cEco[cVegZix] - cLoss
        @rep_elem cVegNew ⇒ (cEco, cVegZix)
    end

    @pack_nt cEco ⇒ land.pools
    land = SindbadTEM.adjustPackPoolComponents(land, helpers, land.models.c_model)
    @pack_nt cEco_prev ⇒ land.states
    return land
end


function spinup(_, _, _, land, helpers, _, ::EtaScaleH)
    @unpack_nt cEco ⇐ land.pools
    helpers = helpers.model_helpers
    cEco_prev = copy(cEco)
    ηH = one(eltype(cEco))
    if :ηH ∈ propertynames(land.diagnostics)
        ηH = land.diagnostics.ηH
    end
    for cSoilZix ∈ helpers.pools.zix.cSoil
        cSoilNew = cEco[cSoilZix] * ηH
        @rep_elem cSoilNew ⇒ (cEco, cSoilZix)
    end

    for cLitZix ∈ helpers.pools.zix.cLit
        cLitNew = cEco[cLitZix] * ηH
        @rep_elem cLitNew ⇒ (cEco, cLitZix)
    end

    @pack_nt cEco ⇒ land.pools
    land = SindbadTEM.adjustPackPoolComponents(land, helpers, land.models.c_model)
    @pack_nt cEco_prev ⇒ land.states
    return land
end

function spinup(_, _, _, land, helpers, _, ::EtaScaleA0HCWD)
    @unpack_nt cEco ⇐ land.pools
    helpers = helpers.model_helpers
    cEco_prev = copy(cEco)
    ηH = one(eltype(cEco))
    c_remain = one(eltype(cEco))
    if :ηH ∈ propertynames(land.diagnostics)
        ηH = land.diagnostics.ηH
        c_remain = land.states.c_remain
    end

    for cLitZix ∈ helpers.pools.zix.cLitSlow
        cLitNew = cEco[cLitZix] * ηH
        @rep_elem cLitNew ⇒ (cEco, cLitZix)
    end

    for cVegZix ∈ helpers.pools.zix.cVeg
        cLoss = at_least_zero(cEco[cVegZix] - c_remain)
        cVegNew = cEco[cVegZix] - cLoss
        @rep_elem cVegNew ⇒ (cEco, cVegZix)
    end

    @pack_nt cEco ⇒ land.pools
    land = SindbadTEM.adjustPackPoolComponents(land, helpers, land.models.c_model)
    @pack_nt cEco_prev ⇒ land.states
    return land
end

function spinup(_, _, loc_forcing_t, land, tem_info, _, ::SpinupInput)
    pools = replacePoolsFromForcing(land.pools, loc_forcing_t)
    @pack_nt pools ⇒ land
    land = setComponentsFromForcedMainPools(land, tem_info.model_helpers, loc_forcing_t)
    return land
end

"""
    setComponentsFromForcedMainPools(land, helpers, loc_forcing_t)

Fills the component pools of every main pool that was read from the forcing, e.g.,
`cVeg`, `cVegRoot` and `cSoil` from `cEco`, and `soilW` and `groundW` from `TWS`.

# Arguments:
- `land`: a SINDBAD NamedTuple containing all variables for a given time step
- `helpers`: the model helpers with the pool information of the model structure
- `loc_forcing_t`: a forcing NamedTuple for a single location and a single time step

# Notes:
- The main pools are the keys of `helpers.pools.vals.self`. Those and the forcing names
  are type parameters, so the selection happens at compile time.
"""
@generated function setComponentsFromForcedMainPools(land, helpers, loc_forcing_t)
    vals_type = fieldtype(fieldtype(helpers, :pools), :vals)
    main_pools = fieldnames(fieldtype(vals_type, :self))
    forced_main_pools = Tuple(m for m ∈ main_pools if m ∈ fieldnames(loc_forcing_t))
    gen_output = quote end
    for m ∈ forced_main_pools
        push!(gen_output.args, :(land = setComponentFromMainPool(land, helpers,
            helpers.pools.vals.self.$m, helpers.pools.vals.all_components.$m, helpers.pools.vals.zix.$m)))
    end
    push!(gen_output.args, :(return land))
    return gen_output
end

"""
    replacePoolsFromForcing(pools, loc_forcing_t)

Replaces every variable of `land.pools` that has a forcing variable of the same name
with the forcing value of the location.

# Arguments:
- `pools`: the `pools` field of a SINDBAD land NamedTuple
- `loc_forcing_t`: a forcing NamedTuple for a single location and a single time step.
  It holds the full value of every forcing variable without a time dimension, such as
  the variables of a restart file.

# Returns:
- `pools` with the matching variables replaced

# Notes:
- The variable names are type parameters of `pools` and `loc_forcing_t`, so the
  matching is done at compile time and the function is type stable.
- Each replaced value keeps the container and number type of the pool.
- The number of layers of the forcing value must equal the size of the pool,
  otherwise an error is thrown.
"""
@generated function replacePoolsFromForcing(pools, loc_forcing_t)
    matched_vars = Tuple(v for v ∈ fieldnames(pools) if v ∈ fieldnames(loc_forcing_t))
    gen_output = quote end
    for v ∈ matched_vars
        push!(gen_output.args, quote
            new_value = matchPoolType(pools.$v, loc_forcing_t.$v, $(QuoteNode(v)))
            pools = merge(pools, NamedTuple{($(QuoteNode(v)),)}((new_value,)))
        end)
    end
    push!(gen_output.args, :(return pools))
    return gen_output
end

"""
    matchPoolType(pool_value, forcing_value, name)

Converts the forcing value of a location to the container and number type of the pool
it replaces, after checking that both have the same number of layers.
"""
function matchPoolType(pool_value, forcing_value, name)
    length(forcing_value) == length(pool_value) || throwSpinupInputSizeError(name, length(pool_value), length(forcing_value))
    if ismutable(pool_value)
        new_value = similar(pool_value)
        for i ∈ eachindex(new_value)
            new_value[i] = forcing_value[i]
        end
        return new_value
    end
    return typeof(pool_value)(vec(forcing_value))
end

@noinline function throwSpinupInputSizeError(name, n_land, n_forcing)
    error("SpinupInput: land.pools.$(name) has $(n_land) layer(s) but the forcing variable $(name) has $(n_forcing). Check that the restart file was written with the same model structure and pool settings.")
end

"""
    sequenceForcing(spinup_forcings::NamedTuple, spin_seq::SpinupStepWithAggregator)

Processes and sequences forcing data for spinup simulations.

# Arguments
- `spinup_forcings::NamedTuple`: A named tuple containing the forcing data for different spinup sequence
- `spin_seq`: the spinup step
"""
function sequenceForcing end

sequenceForcing(spinup_forcings::NamedTuple, ::SpinupStepWithAggregator{F}) where {F} = getfield(spinup_forcings, F)

sequenceForcing(::NamedTuple, ::SpinupStepWithAggregator{:none}) = (;)

"""
    storeSpinupStep!(land, store_spinup_mode)

Writes `cEco` and `TWS` of `land.pools` to the next row of the spinup store, or does
nothing, depending on the specified `store_spinup_mode`.

# Arguments:
- `land`: A SINDBAD NamedTuple containing all variables for a given time step, which is overwritten at every timestep.
- `store_spinup_mode`: A type dispatch that determines whether to store the spinup:
    - `DoStoreSpinup`: Writes the next row of `land.states.spinup_cEco` and
      `land.states.spinup_TWS`. Set the `store_spinup` flag to `true` in flag section
      of experiment_json.
    - `DoNotStoreSpinup`: Does nothing. Set the `store_spinup` flag to `false` in
      flag section of experiment_json.

# Notes:
- The row is `land.states.spinup_step[1]` after it is increased by one. The arrays
  are added by `addSpinupStore`.
- A row beyond the size of the arrays is not written, e.g. for a land that is shared
  by locations with longer sequences.
"""
function storeSpinupStep! end

function storeSpinupStep!(land, ::DoStoreSpinup)
    spinup_step = land.states.spinup_step
    spinup_step[1] += 1
    row = spinup_step[1]
    storeSpinupRow!(land.states.spinup_cEco, land.pools, Val(:cEco), row)
    storeSpinupRow!(land.states.spinup_TWS, land.pools, Val(:TWS), row)
    return nothing
end

storeSpinupStep!(_, ::DoNotStoreSpinup) = nothing

storeSpinupRow!(::Nothing, _, _, _) = nothing

# the pool name is a Val so that the pool is found at compile time
function storeSpinupRow!(spinup_pool, pools, ::Val{pool_name}, row) where {pool_name}
    row > size(spinup_pool, 1) && return nothing
    pool = getfield(pools, pool_name)
    for layer ∈ eachindex(pool)
        @inbounds spinup_pool[row, layer] = pool[layer]
    end
    return nothing
end

"""
    storeSpinupRepeat!(land, spinup_mode, store_spinup_mode)

Writes one row of the spinup store after a repeat of a spinup step. A `LoopTEM` step
already wrote every time step in `timeLoopTEMSpinup`, so nothing is written for it.
"""
function storeSpinupRepeat! end

storeSpinupRepeat!(_, ::LoopTEM, _) = nothing

storeSpinupRepeat!(land, _, store_spinup_mode) = storeSpinupStep!(land, store_spinup_mode)

"""
    resetSpinupStore!(land, store_spinup_mode)

Sets the last written row of the spinup store to zero, so that a new spinup of the
same land writes from the first row again.
"""
function resetSpinupStore! end

function resetSpinupStore!(land, ::DoStoreSpinup)
    land.states.spinup_step[1] = 0
    return nothing
end

resetSpinupStore!(_, ::DoNotStoreSpinup) = nothing

"""
    spinupSequence(spinup_models, sel_forcing, loc_forcing_t, land, tem_info, n_timesteps, n_repeat, spinup_mode)

Executes a sequence of model spinup iterations for the Terrestrial Ecosystem Model (TEM).

# Arguments
- `spinup_models`: Collection of model configurations for spinup
- `sel_forcing`: Selected forcing data
- `loc_forcing_t`: Localized forcing data with temporal component
- `land`: Land surface parameters
- `tem_info`: TEM model information and parameters
- `n_timesteps`: Number of timesteps for the spinup
- `n_repeat`: Number of times to repeat the spinup sequence
- `spinup_mode`: Mode of spinup operation (e.g., "normal", "accelerated")

# Description
Performs model spinup by running multiple iterations of the TEM model to achieve
steady state conditions. The function handles different spinup modes and manages
the sequence of model runs according to specified parameters.

# Returns
land with the updated pools after the spinup sequence.
"""
function spinupSequence(spinup_models, sel_forcing, loc_forcing_t, land, tem_info, n_timesteps, n_repeat, spinup_mode)
    land = spinupSequenceLoop(spinup_models, sel_forcing, loc_forcing_t, land, tem_info, n_timesteps, n_repeat, spinup_mode)
    # end
    return land
end


"""
    spinupSequenceLoop(spinup_models, sel_forcing, loc_forcing_t, land, tem_info, n_timesteps, n_repeat, spinup_mode)

Runs sequential loops for model spin-up simulations for each repeat of a spinup sequence.

# Arguments
- `spinup_models`: Collection of spin-up model instances
- `sel_forcing`: Selected forcing data
- `loc_forcing_t`: Localized forcing data in temporal dimension
- `land`: Land surface parameters/conditions
- `tem_info`: Model configuration and parameters for TEM
- `n_timesteps`: Number of timesteps to simulate
- `n_repeat`: Number of times to repeat the spin-up loop
- `spinup_mode`: Mode of spin-up simulation (e.g., "normal", "accelerated")
"""
function spinupSequenceLoop(spinup_models, sel_forcing, loc_forcing_t, land, tem_info, n_timesteps, n_repeat, spinup_mode)
    for _ ∈ 1:n_repeat
        land = spinup(spinup_models,
            sel_forcing,
            loc_forcing_t,
            land,
            tem_info,
            n_timesteps,
            spinup_mode)
        storeSpinupRepeat!(land, spinup_mode, tem_info.run.store_spinup)
    end
    return land
end


"""
    spinupTEM(selected_models, loc_spinup, loc_forcing_t, land, tem_info, spinup_mode, loc_restart=nothing)

The main spinup function that handles the spinup method based on inputs from spinup.json. Either the spinup is loaded or/and run using spinup functions for different spinup methods.

# Arguments:
- `selected_models`: a tuple of all models selected in the given model structure
- `loc_spinup`: a NT with the spinup `sequence` of the location and the `forcing` derived from it
- `loc_forcing_t`: a forcing NT for a single location and a single time step
- `land`: SINDBAD NT input to the spinup of TEM during which subfield(s) of pools are overwritten
- `tem_info`: helper NT with necessary objects for model run and type consistencies
- `loc_restart`: where the pools are stored for the restart file, after the step of the sequence whose `save_restart` is true. With `nothing`, the default, nothing is stored. Without spinup, the pools of the input land are stored.
- `spinup_mode`: A type dispatch that determines whether spinup is included or excluded:
    - `::DoSpinupTEM`: Runs the spinup process before the main simulation. Set `spinup_TEM` to `true` in the flag section of experiment_json.
    - `::DoNotSpinupTEM`: Skips the spinup process and directly runs the main simulation. Set `spinup_TEM` to `false` in the flag section of experiment_json.

# Examples
```jldoctest
julia> using Sindbad

julia> # Run spinup with DoSpinupTEM
julia> # land_spinup = spinupTEM(selected_models, forcing, loc_forcing_t, land, tem_info, DoSpinupTEM())

julia> # Skip spinup with DoNotSpinupTEM
julia> # land = spinupTEM(selected_models, forcing, loc_forcing_t, land, tem_info, DoNotSpinupTEM())
```

# Notes:
- When `DoSpinupTEM` is used:
    - The function runs the spinup sequences
- When `DoNotSpinupTEM` is used:
    - The function skips the spinup process returns the land as is`
"""
function spinupTEM end

function spinupTEM(selected_models, loc_spinup, loc_forcing_t, land, tem_info, ::DoSpinupTEM, loc_restart=nothing)
    resetSpinupStore!(land, tem_info.run.store_spinup)
    storeSpinupStep!(land, tem_info.run.store_spinup)
    land = runSpinupSequences(loc_spinup.sequence, selected_models, loc_spinup.forcing, loc_forcing_t, land, tem_info, loc_restart)
    return land
end

"""
    runSpinupSequences(spin_seqs, selected_models, spinup_forcings, loc_forcing_t, land, tem_info, loc_restart=nothing)

Runs every spinup sequence of `spin_seqs` in order, threading `land` through the
sequences.

# Arguments:
- `spin_seqs`: a tuple of spinup sequences, each with the forcing name, number of timesteps, number of repeats, and the spinup mode
- `selected_models`: a tuple of all models selected in the given model structure
- `spinup_forcings`: a forcing NT with one entry per distinct spinup forcing name
- `loc_forcing_t`: a forcing NT for a single location and a single time step
- `land`: SINDBAD NT input to the spinup of TEM during which subfield(s) of pools are overwritten
- `tem_info`: helper NT with necessary objects for model run and type consistencies
- `loc_restart`: where the pools are stored for the restart file after the step whose `save_restart` is true, or `nothing`

# Returns:
- the updated `land`

# Notes:
- The sequences are consumed recursively with `Base.tail` rather than with a `for` loop. `spin_seqs` is a heterogeneous tuple, so a `for` loop indexes it with a runtime state, which puts the whole tuple and every extracted element on the heap once per iteration. Recursion specialises one method per sequence and removes those allocations.
"""
function runSpinupSequences end

runSpinupSequences(::Tuple{}, selected_models, spinup_forcings, loc_forcing_t, land, tem_info, loc_restart=nothing) = land

function runSpinupSequences(spin_seqs::Tuple, selected_models, spinup_forcings, loc_forcing_t, land, tem_info, loc_restart=nothing)
    spin_seq = first(spin_seqs)
    n_repeat = spin_seq.n_repeat
    sel_forcing = sequenceForcing(spinup_forcings, spin_seq)
    spinup_models = getSpinupModels(selected_models, spin_seq.model_indices)
    land = spinupSequence(spinup_models, sel_forcing, loc_forcing_t, land, tem_info, spin_seq.n_timesteps, n_repeat, spin_seq.spinup_mode)
    spin_seq.save_restart && setRestart!(loc_restart, land, tem_info)
    return runSpinupSequences(Base.tail(spin_seqs), selected_models, spinup_forcings, loc_forcing_t, land, tem_info, loc_restart)
end

"""
    getSpinupModels(selected_models, model_indices)

Picks the models that are run in one spinup step out of the selected models.

# Arguments:
- `selected_models`: a tuple or LongTuple of all models selected in the given model structure
- `model_indices`: a `Val` of the tuple of model indices of the step, or nothing to
  run all the selected models

# Returns:
- the models of the step, as the same kind of tuple as `selected_models`

# Notes:
- The models are picked at every run, because the selected models carry the
  parameters, which change in an optimization.
"""
function getSpinupModels end

getSpinupModels(selected_models, ::Nothing) = selected_models

@generated function getSpinupModels(selected_models::Tuple, ::Val{I}) where {I}
    return Expr(:tuple, (:(selected_models[$i]) for i in I)...)
end

@generated function getSpinupModels(selected_models::LongTuple{N}, ::Val{I}) where {N,I}
    models = [:(selected_models.data[$((i - 1) ÷ N + 1)][$((i - 1) % N + 1)]) for i in I]
    # foldl_longtuple needs at least one chunk, so no models give an empty tuple
    isempty(models) && return :(())
    n_split = min(N, length(models))
    chunks = [Expr(:tuple, models[k:min(k + n_split - 1, end)]...) for k in 1:n_split:length(models)]
    return :(LongTuple{$n_split}($(Expr(:tuple, chunks...))))
end

function spinupTEM(selected_models, loc_spinup, loc_forcing_t, land, tem_info, ::DoNotSpinupTEM, loc_restart=nothing)
    setRestart!(loc_restart, land, tem_info)
    return land
end

"""
    setRestart!(loc_restart, land, tem_info)

Stores the main pools of `land` for the restart file.

# Arguments:
- `loc_restart`: where the pools are stored. It is `nothing` when no restart data is
  collected, the restart arrays of the location in an eager run, or a function that
  takes the land in a lazy run.
- `land`: the land whose pools are stored
- `tem_info`: helper NT with the restart variables in `vals.restart_vars`
"""
function setRestart! end

setRestart!(::Nothing, _, _) = nothing
setRestart!(store_restart::Function, land, _) = store_restart(land)
setRestart!(loc_restart, land, tem_info) = setOutputForTimeStep!(loc_restart, land, 1, tem_info.vals.restart_vars)


"""
    timeLoopTEMSpinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps)

do/run the time loop of the spinup models to update the pool. Note that, in this function, the time series is not stored and the land/land is overwritten with every iteration. Only the state at the end is returned

# Arguments:
- `spinup_models`: a tuple of a subset of all models in the given model structure that is selected for spinup
- `spinup_forcing`: a selected/sliced/computed forcing time series for running the spinup sequence for a location
- `loc_forcing_t`: a forcing NT for a single location and a single time step
- `land`: SINDBAD NT input to the spinup of TEM during which subfield(s) of pools are overwritten
- `tem_info`: helper NT with necessary objects for model run and type consistencies
- `n_timesteps`: number of time steps
"""
function timeLoopTEMSpinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps)
    for ts ∈ 1:n_timesteps
        f_ts = getForcingForTimeStep(spinup_forcing, loc_forcing_t, ts, tem_info.vals.forcing_types)
        land = computeTEM(spinup_models, f_ts, land, tem_info.model_helpers)
    end
    return land
end

"""
    timeLoopTEMSpinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, store_spinup_mode)

Runs the time loop of the spinup models like the method without `store_spinup_mode`,
and with `DoStoreSpinup` writes `cEco` and `TWS` to the spinup store after every time
step.

# Notes:
- Only `spinup` with `LoopTEM` calls this method. The solver based spinup modes call
  the method without `store_spinup_mode`, so their trial runs are not stored.
"""
function timeLoopTEMSpinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, ::DoNotStoreSpinup)
    return timeLoopTEMSpinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps)
end

function timeLoopTEMSpinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, store_spinup_mode::DoStoreSpinup)
    for ts ∈ 1:n_timesteps
        f_ts = getForcingForTimeStep(spinup_forcing, loc_forcing_t, ts, tem_info.vals.forcing_types)
        land = computeTEM(spinup_models, f_ts, land, tem_info.model_helpers)
        storeSpinupStep!(land, store_spinup_mode)
    end
    return land
end