```@docs
SindbadTEM.Variables
```
### Functions

#### checkMissingVarInfo
```@docs
checkMissingVarInfo
```

:::details Code

```julia
function checkMissingVarInfo end

function checkMissingVarInfo(appr)
    if supertype(appr) == LandEcosystem
        foreach(subtypes(appr)) do sub_appr
            checkMissingVarInfo(sub_appr)
        end
    else
        in_out_model = getInOutModel(appr, verbose=false)
        d_methods = (:define, :precompute, :compute, :update)
        for d_method in d_methods
            inputs = in_out_model[d_method][:input]
            outputs = in_out_model[d_method][:output]
            io_list = unique([inputs..., outputs...])
            was_displayed = false
            miss_doc = false
            foreach(io_list) do io_item
                var_key = Symbol(String(first(io_item))*"__"*String(last(io_item)))
                var_info = getVariableInfo(var_key, "time")
                miss_doc = isempty(var_info["long_name"])
                if miss_doc
                    checkDisplayVariableDict(var_key, warn_msg=!was_displayed)
                    if !was_displayed
                        was_displayed = true
                        println("Approach: $(appr).jl\nMethod: $(d_method)\nKey: :$(var_key)\nPair: $(io_item)")
                    end
                    checkDisplayVariableDict(var_key, warn_msg=!was_displayed)

                end
            end
            if miss_doc
                println("--------------------------------")
            end
        end    
    end
    return nothing
end

function checkMissingVarInfo(appr)
    if supertype(appr) == LandEcosystem
        foreach(subtypes(appr)) do sub_appr
            checkMissingVarInfo(sub_appr)
        end
    else
        in_out_model = getInOutModel(appr, verbose=false)
        d_methods = (:define, :precompute, :compute, :update)
        for d_method in d_methods
            inputs = in_out_model[d_method][:input]
            outputs = in_out_model[d_method][:output]
            io_list = unique([inputs..., outputs...])
            was_displayed = false
            miss_doc = false
            foreach(io_list) do io_item
                var_key = Symbol(String(first(io_item))*"__"*String(last(io_item)))
                var_info = getVariableInfo(var_key, "time")
                miss_doc = isempty(var_info["long_name"])
                if miss_doc
                    checkDisplayVariableDict(var_key, warn_msg=!was_displayed)
                    if !was_displayed
                        was_displayed = true
                        println("Approach: $(appr).jl\nMethod: $(d_method)\nKey: :$(var_key)\nPair: $(io_item)")
                    end
                    checkDisplayVariableDict(var_key, warn_msg=!was_displayed)

                end
            end
            if miss_doc
                println("--------------------------------")
            end
        end    
    end
    return nothing
end

function checkMissingVarInfo()
    for sm in subtypes(LandEcosystem)
        for appr in subtypes(sm)
            if appr != LandEcosystem
                checkMissingVarInfo(appr)
            end
        end  
    end      
   return nothing
end
```

:::


----

#### defaultVariableInfo
```@docs
defaultVariableInfo
```

:::details Code

```julia
function defaultVariableInfo(string_key=false)
    if string_key
        return DataStructures.OrderedDict(
            "standard_name" => "",
            "long_name" => "",
            "units" => "",
            "land_field" => "",
            "description" => ""
        )
    else
        return DataStructures.OrderedDict(
            :standard_name => "",
            :long_name => "",
            :units => "",
            :land_field => "",
            :description => ""
        )
    end
end
```

:::


----

#### getUniqueVarNames
```@docs
getUniqueVarNames
```

:::details Code

```julia
function getUniqueVarNames(var_pairs)
    pure_vars = getVarName.(var_pairs)
    fields = getVarField.(var_pairs)
    uniq_vars = Symbol[]
    for i in eachindex(pure_vars)
        n_occur = sum(pure_vars .== pure_vars[i])
        var_i = pure_vars[i]
        if n_occur > 1
            var_i = Symbol(String(fields[i]) * "__" * String(pure_vars[i]))
        end
        push!(uniq_vars, var_i)
    end
    return uniq_vars
end
```

:::


----

#### getVarFull
```@docs
getVarFull
```

:::details Code

```julia
function getVarFull(var_pair)
    return Symbol(String(first(var_pair)) * "__" * String(last(var_pair)))
end
```

:::


----

#### getVariableInfo
```@docs
getVariableInfo
```

:::details Code

```julia
function getVariableInfo(vari_b, t_step="day")
    vname = getVarFull(vari_b)
    return getVariableInfo(vname, t_step)
end

function getVariableInfo(vari_b::Symbol, t_step="day")
    # Access Variables module safely - it may not be loaded during Processes.jl initialization
    catalog = try
        getfield(SindbadTEM, :Variables).sindbad_tem_variables
    catch
        # Return default info if Variables module is not yet loaded
        return Dict(
            "standard_name" => split(string(vari_b), "__")[2],
            "long_name" => "",
            "units" => "",
            "land_field" => split(string(vari_b), "__")[1],
            "description" => split(string(vari_b), "__")[2] * "_" * split(string(vari_b), "__")[1]
        )
    end
    default_info = try
        getfield(SindbadTEM, :Variables).defaultVariableInfo(true)
    catch
        # Return default info if Variables module is not yet loaded
        return Dict(
            "standard_name" => split(string(vari_b), "__")[2],
            "long_name" => "",
            "units" => "",
            "land_field" => split(string(vari_b), "__")[1],
            "description" => split(string(vari_b), "__")[2] * "_" * split(string(vari_b), "__")[1]
        )
    end
    default_keys = Symbol.(keys(default_info))
    o_varib = copy(default_info)
    if vari_b ∈ keys(catalog)
        var_info = catalog[vari_b]
        var_fields = keys(var_info)
        all_fields = Tuple(unique([default_keys..., var_fields...]))
        for var_field ∈ all_fields
            field_value = nothing
            if haskey(default_info, var_field)
                field_value = default_info[var_field]
            else
                field_value = var_info[var_field]
            end
            if haskey(var_info, var_field)
                var_prop = var_info[var_field]
                if !isnothing(var_prop) && length(var_prop) > 0
                    field_value = var_info[var_field]
                end
            end
            if var_field == :units
                if !isnothing(field_value)
                    field_value = replace(field_value, "time" => t_step)
                else
                    field_value = ""
                end
            end
            var_field_str = string(var_field)
            o_varib[var_field_str] = field_value
        end
    end
    if isempty(o_varib["standard_name"])
        o_varib["standard_name"] = split(string(vari_b), "__")[2]
    end
    if isempty(o_varib["description"])
        o_varib["description"] = split(string(vari_b), "__")[2] * "_" * split(string(vari_b), "__")[1]
    end
    return Dict(o_varib)
end
```

:::


----

#### whatIs
```@docs
whatIs
```

:::details Code

```julia
function whatIs end

function whatIs(var_name::String)
    if startswith(var_name, "land")
        var_name = var_name[6:end]
    end
    var_field = string(split(var_name, ".")[1])
    var_sfield = string(split(var_name, ".")[2])
    var_full = getFullVariableKey(var_field, var_sfield)
    println("\nchecking $var_name as :$var_full in sindbad_tem_variables catalog...")
    checkDisplayVariableDict(var_full)
    return nothing
end

function whatIs(var_name::String)
    if startswith(var_name, "land")
        var_name = var_name[6:end]
    end
    var_field = string(split(var_name, ".")[1])
    var_sfield = string(split(var_name, ".")[2])
    var_full = getFullVariableKey(var_field, var_sfield)
    println("\nchecking $var_name as :$var_full in sindbad_tem_variables catalog...")
    checkDisplayVariableDict(var_full)
    return nothing
end

function whatIs(var_name::Symbol)
    var_name = string(var_name)
    v_field = split(var_name, "__")[1]
    v_sfield = split(var_name, "__")[2]
    whatIs(string(v_field), string(v_sfield))
    return nothing
end

function whatIs(var_field::String, var_sfield::String)
    var_full = getFullVariableKey(var_field, var_sfield)
    println("\nchecking $var_field field and $var_sfield subfield as :$var_full in sindbad_tem_variables catalog...")
    checkDisplayVariableDict(var_full)
    return nothing
end

function whatIs(var_field::Symbol, var_sfield::Symbol)
    var_full = getFullVariableKey(string(var_field), string(var_sfield))
    println("\nchecking :$var_field field and :$var_sfield subfield as :$var_full in sindbad_tem_variables catalog...")
    checkDisplayVariableDict(var_full)
    return nothing
end
```

:::


----

```@meta
CollapsedDocStrings = false
DocTestSetup= quote
using SindbadTEM.Variables
end
```

### Variable Catalog (`sindbad_tem_variables`)

Variables are grouped by `land_field` into Fluxes / Pools / States / Diagnostics, with everything else under Others.

## Fluxes

:::details Show table (35)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `PET` | `mm/time` | potential evapotranspiration | `potential_evapotranspiration` | `fluxes__PET` |
| `auto_respiration` | `gC/m2/time` | carbon loss due to autotrophic respiration | `autotrophic_respiration` | `fluxes__auto_respiration` |
| `auto_respiration_growth` | `gC/m2/time` | growth respiration per vegetation pool | `growth_respiration` | `fluxes__auto_respiration_growth` |
| `auto_respiration_maintain` | `gC/m2/time` | maintenance respiration per vegetation pool | `maintenance_respiration` | `fluxes__auto_respiration_maintain` |
| `base_runoff` | `mm/time` | base runoff | `base_runoff` | `fluxes__base_runoff` |
| `c_eco_efflux` | `gC/m2/time` | losss of carbon from (live) vegetation pools due to autotrophic respiration | `autotrophic_carbon_loss` | `fluxes__c_eco_efflux` |
| `c_eco_flow` | `gC/m2/time` | flow of carbon to a given carbon pool from other carbon pools | `net_carbon_flow` | `fluxes__c_eco_flow` |
| `c_eco_influx` | `gC/m2/time` | net influx from allocation and efflux (npp) to each (live) carbon pool | `net_carbon_influx` | `fluxes__c_eco_influx` |
| `c_eco_npp` | `gC/m2/time` | npp of each carbon pool | `carbon_net_primary_productivity` | `fluxes__c_eco_npp` |
| `c_eco_out` | `gC/m2/time` | outflux of carbon from each carbol pool | `total_carbon_loss` | `fluxes__c_eco_out` |
| `ecosystem_respiration` | `gC/m2/time` | carbon loss due to ecosystem respiration | `total_ecosystem_respiration` | `fluxes__eco_respiration` |
| `evaporation` | `mm/time` | evaporation from the first soil layer | `soil_evaporation` | `fluxes__evaporation` |
| `evapotranspiration` | `mm/time` | total land evaporation including soil evaporation, vegetation transpiration, snow sublimation, and interception loss | `total_land_evaporation` | `fluxes__evapotranspiration` |
| `gpp` | `gC/m2/time` | gross primary prorDcutivity | `gross_primary_productivity` | `fluxes__gpp` |
| `gw_capillary_flux` | `mm/time` | capillary flux from top groundwater layer to the lowermost soil layer | `groundwater_capillary_flux` | `fluxes__gw_capillary_flux` |
| `gw_recharge` | `mm/time` | net groundwater recharge from the lowermost soil layer, positive => soil to groundwater | `groundwater_recharge` | `fluxes__gw_recharge` |
| `hetero_respiration` | `gC/m2/time` | carbon loss due to heterotrophic respiration | `heterotrophic_respiration` | `fluxes__hetero_respiration` |
| `interception` | `mm/time` | interception evaporation loss | `interception_loss` | `fluxes__interception` |
| `interflow_runoff` | `mm/time` | runoff loss from interflow in soil layers | `interflow_runoff` | `fluxes__interflow_runoff` |
| `nee` | `gC/m2/time` | net ecosystem carbon exchange for the ecosystem. negative value indicates carbon sink. | `net_ecosystem_exchange` | `fluxes__nee` |
| `npp` | `gC/m2/time` | net primary prorDcutivity | `carbon_net_primary_productivity` | `fluxes__npp` |
| `overland_runoff` | `mm/time` | overland runoff as a fraction of incoming water | `overland_runoff` | `fluxes__overland_runoff` |
| `precip` | `mm/time` | total land precipitation including snow and rain | `total_precipiration` | `fluxes__precip` |
| `rain` | `mm/time` | amount of precipitation in liquid form | `rainfall` | `fluxes__rain` |
| `root_water_uptake` | `mm/time` | amount of water uptaken for transpiration per soil layer | `root_water_uptake` | `fluxes__root_water_uptake` |
| `runoff` | `mm/time` | total runoff | `total_runoff` | `fluxes__runoff` |
| `sat_excess_runoff` | `mm/time` | saturation excess runoff | `saturation_excess_runoff` | `fluxes__sat_excess_runoff` |
| `snow` | `mm/time` | amount of precipitation in solid form | `snowfall` | `fluxes__snow` |
| `snow_melt` | `mm/time` | snow melt | `snow_melt_flux` | `fluxes__snow_melt` |
| `soil_capillary_flux` | `mm/time` | soil capillary flux per layer | `soil_capillary_flux` | `fluxes__soil_capillary_flux` |
| `sublimation` | `mm/time` | sublimation of the snow | `snow_sublimation` | `fluxes__sublimation` |
| `surface_runoff` | `mm/time` | total surface runoff | `total_surface_runoff` | `fluxes__surface_runoff` |
| `transpiration` | `mm/time` | transpiration | `transpiration` | `fluxes__transpiration` |
| `zero_c_eco_flow` | `gC/m2/time` | helper for resetting c_eco_flow in every time step | `zero_vector_for_c_eco_flow` | `fluxes__zero_c_eco_flow` |
| `zero_c_eco_influx` | `gC/m2/time` | helper for resetting c_eco_influx in every time step | `zero_vector_for_c_eco_influx` | `fluxes__zero_c_eco_influx` |

:::

## Pools

:::details Show table (24)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `TWS` | `mm` | terrestrial water storage including all water pools | `terrestrial_water_storage` | `pools__TWS` |
| `cEco` | `gC/m2` | carbon content of cEco pool(s) | `ecosystem_carbon_storage_content` | `pools__cEco` |
| `cLit` | `gC/m2` | carbon content of cLit pool(s) | `litter_carbon_storage_content` | `pools__cLit` |
| `cLitFast` | `gC/m2` | carbon content of cLitFast pool(s) | `litter_carbon_storage_content_fast_turnover` | `pools__cLitFast` |
| `litter_carbon_storage_content_slow_turnover` | `gC/m2` | carbon content of cLitSlow pool(s) | `cLitSlow` | `pools__cLitSlow` |
| `cSoil` | `gC/m2` | carbon content of cSoil pool(s) | `soil_carbon_storage_content` | `pools__cSoil` |
| `cSoilOld` | `gC/m2` | carbon content of cSoilOld pool(s) | `old_soil_carbon_storage_content_slow_turnover` | `pools__cSoilOld` |
| `cSoilSlow` | `gC/m2` | carbon content of cSoilSlow pool(s) | `soil_carbon_storage_content_slow_turnover` | `pools__cSoilSlow` |
| `cVeg` | `gC/m2` | carbon content of cVeg pool(s) | `vegetation_carbon_storage_content` | `pools__cVeg` |
| `cVegLeaf` | `gC/m2` | carbon content of cVegLeaf pool(s) | `leaf_carbon_storage_content` | `pools__cVegLeaf` |
| `cVegReserve` | `gC/m2` | carbon content of cVegReserve pool(s) that does not respire | `reserve_carbon_storage_content` | `pools__cVegReserve` |
| `cVegRoot` | `gC/m2` | carbon content of cVegRoot pool(s) | `root_carbon_storage_content` | `pools__cVegRoot` |
| `cVegWood` | `gC/m2` | carbon content of cVegWood pool(s) | `wood_carbon_storage_content` | `pools__cVegWood` |
| `groundW` | `mm` | water storage in groundW pool(s) | `groundwater_storage` | `pools__groundW` |
| `snowW` | `mm` | water storage in snowW pool(s) | `snow_water_equivalent` | `pools__snowW` |
| `soilW` | `mm` | water storage in soilW pool(s) | `soil_moisture_storage` | `pools__soilW` |
| `surfaceW` | `mm` | water storage in surfaceW pool(s) | `surface_water_storage` | `pools__surfaceW` |
| `zeroΔTWS` | `mm` | helper variable to reset ΔTWS to zero in every time step | `zero_with_size_` | `pools__zeroΔTWS` |
| `ΔTWS` | `mm` | change in water storage in TWS pool(s) | `delta_change_TWS` | `pools__ΔTWS` |
| `ΔcEco` | `mm` | change in water storage in cEco pool(s) | `delta_change_cEco` | `pools__ΔcEco` |
| `ΔgroundW` | `mm` | change in water storage in groundW pool(s) | `delta_change_groundW` | `pools__ΔgroundW` |
| `ΔsnowW` | `mm` | change in water storage in snowW pool(s) | `delta_change_snowW` | `pools__ΔsnowW` |
| `ΔsoilW` | `mm` | change in water storage in soilW pool(s) | `delta_change_soilW` | `pools__ΔsoilW` |
| `ΔsurfaceW` | `mm` | change in water storage in surfaceW pool(s) | `delta_change_surfaceW` | `pools__ΔsurfaceW` |

:::

## States

:::details Show table (14)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `LAI` | `m2/m2` | leaf area index | `leaf_area_index` | `states__LAI` |
| `PAW` | `mm` | amount of water available for transpiration per soil layer | `plant_available_water` | `states__PAW` |
| `Tair_prev` | `degree_C` | air temperature in the previous time step | `Tair_previous_timestep` | `states__Tair_prev` |
| `WBP` | `mm` | water balance tracker pool that starts with rain and ends up with 0 after allocating to soil percolation | `water_balance_pool` | `states__WBP` |
| `aboveground_biomass` | `gC/m2` | carbon content on the cVegWood component | `aboveground_woody_biomass` | `states__aboveground_biomass` |
| `ambient_CO2` | `ppm` | ambient co2 concentration | `ambient_CO2_concentration` | `states__ambient_CO2` |
| `cEco_prev` | `gC/m2` | ecosystem carbon content of the previous time step | `ecosystem_carbon_pool_previous_timestep` | `states__cEco_prev` |
| `c_remain` | `gC/m2` | amount of carbon to keep in the ecosystem vegetation pools in case of disturbances | `carbon_remain` | `states__c_remain` |
| `fAPAR` | `fraction` | fraction of absorbed photosynthetically active radiation | `fraction_absorbed_photosynthetic_radiation` | `states__fAPAR` |
| `frac_snow` | `fraction` | fractional coverage of grid with snow | `fractional_snow_cover` | `states__frac_snow` |
| `frac_tree` | `fraction` | fractional coverage of grid with trees | `fractional_tree_cover` | `states__frac_tree` |
| `frac_vegetation` | `fraction` | fractional coverage of grid with vegetation | `fractional_vegetation_cover` | `states__frac_vegetation` |
| `total_water` | `mm` | sum of water storage across all components | `total_water` | `states__total_water` |
| `total_water_prev` | `mm` | sum of water storage across all components in previous time step | `total_water_previous` | `states__total_water_prev` |

:::

## Diagnostics

:::details Show table (55)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `C_to_N_cVeg` | `ratio` | carbon to nitrogen ratio in the vegetation pools | `carbon_to_nitrogen_ratio` | `diagnostics__C_to_N_cVeg` |
| `WUE` | `gC/mmH2O` | water use efficiency of the ecosystem | `ecosystem_water_use_efficiency` | `diagnostics__WUE` |
| `WUENoCO2` | `gC/mmH2O` | water use efficiency of the ecosystem without CO2 effect | `ecosystem_water_use_efficiency_without_co2_effect` | `diagnostics__WUENoCO2` |
| `auto_respiration_f_airT` | `scalar` | effect of air temperature on autotrophic respiration. 0: no decomposition, >1 increase in decomposition rate | `air_temperature_effect_autotrophic_respiration` | `diagnostics__auto_respiration_f_airT` |
| `c_allocation` | `fraction` | fraction of gpp allocated to different (live) carbon pools | `cabon_allocation` | `diagnostics__c_allocation` |
| `c_allocation_f_LAI` | `fraction` | effect of LAI on carbon allocation. 1: no stress, 0: complete stress | `LAI_effect_carbon_allocation` | `diagnostics__c_allocation_f_LAI` |
| `c_allocation_f_W_N` | `fraction` | effect of water and nutrient on carbon allocation. 1: no stress, 0: complete stress | `W_N_effect_carbon_allocation` | `diagnostics__c_allocation_f_W_N` |
| `c_allocation_f_cloud` | `fraction` | effect of cloud on carbon allocation. 1: no stress, 0: complete stress | `cloud_effect_carbon_allocation` | `diagnostics__c_allocation_f_cloud` |
| `c_allocation_f_soilT` | `scalar` | effect of soil temperature on carbon allocation. 1: no stress, 0: complete stress | `soil_temperature_effect_carbon_allocation` | `diagnostics__c_allocation_f_soilT` |
| `c_allocation_f_soilW` | `fraction` | effect of soil moisture on carbon allocation. 1: no stress, 0: complete stress | `soil_moisture_effect_carbon_allocation` | `diagnostics__c_allocation_f_soilW` |
| `c_eco_k` | `/time` | decomposition rate of carbon per pool | `carbon_decomposition_rate` | `diagnostics__c_eco_k` |
| `c_eco_k_base` | `/time` | base carbon decomposition rate of the carbon pools | `c eco k base` | `diagnostics__c_eco_k_base` |
| `c_eco_k_f_LAI` | `fraction` | effect of LAI on carbon decomposition rate. 1: no stress, 0: complete stress | `LAI_effect_carbon_decomposition_rate` | `diagnostics__c_eco_k_f_LAI` |
| `c_eco_k_f_soilT` | `scalar` | effect of soil temperature on heterotrophic respiration respiration. 0: no decomposition, >1 increase in decomposition | `soil_temperature_effect_carbon_decomposition_rate` | `diagnostics__c_eco_k_f_soilT` |
| `c_eco_k_f_soilW` | `fraction` | effect of soil moisture on carbon decomposition rate. 1: no stress, 0: complete stress | `soil_moisture_effect_carbon_decomposition_rate` | `diagnostics__c_eco_k_f_soilW` |
| `c_eco_k_f_soil_props` | `fraction` | effect of soil_props on carbon decomposition rate. 1: no stress, 0: complete stress | `soil_property_effect_carbon_decomposition_rate` | `diagnostics__c_eco_k_f_soil_props` |
| `c_eco_k_f_veg_props` | `fraction` | effect of veg_props on carbon decomposition rate. 1: no stress, 0: complete stress | `vegetation_property_effect_carbon_decomposition_rate` | `diagnostics__c_eco_k_f_veg_props` |
| `c_eco_τ` | `years` | number of years needed for carbon turnover per carbon pool | `carbon_turnover_per_pool` | `diagnostics__c_eco_τ` |
| `c_flow_A_array` | `fraction` | an array indicating the flow direction and connections across different pools, with elements larger than 0 indicating flow from column pool to row pool | `carbon_flow_array` | `diagnostics__c_flow_A_array` |
| `c_flow_A_vec` | `fraction` | fraction of the carbon loss fron a (giver) pool that flows to a (taker) pool | `carbon_flow_vector` | `diagnostics__c_flow_A_vec` |
| `c_flow_E_array` | `fraction` | an array containing the efficiency of each flow in the c_flow_A_array | `carbon_flow_efficiency_array` | `diagnostics__c_flow_E_array` |
| `eco_stressor` | `fraction` | ecosystem stress on carbon flow | `carbon_flow_ecosystem_stressor` | `diagnostics__eco_stressor` |
| `eco_stressor_prev` | `fraction` | ecosystem stress on carbon flow in the previous time step | `carbon_flow_ecosystem_stressor_previous_timestep` | `diagnostics__eco_stressor_prev` |
| `gpp_climate_stressors` | `fraction` | a collection of all gpp climate stressors including light, temperature, radiation, and vpd | `climate_effect_per_factor_gpp` | `diagnostics__gpp_climate_stressors` |
| `gpp_demand` | `gC/m2/time` | demand driven gross primary prorDuctivity | `demand_driven_gpp` | `diagnostics__gpp_demand` |
| `gpp_f_airT` | `fraction` | effect of air temperature on gpp. 1: no stress, 0: complete stress | `air_temperature_effect_gpp` | `diagnostics__gpp_f_airT` |
| `gpp_f_climate` | `fraction` | effect of climate on gpp. 1: no stress, 0: complete stress | `net_climate_effect_gpp` | `diagnostics__gpp_f_climate` |
| `gpp_f_cloud` | `fraction` | effect of cloud on gpp. 1: no stress, 0: complete stress | `cloudiness_index_effect_gpp` | `diagnostics__gpp_f_cloud` |
| `gpp_f_light` | `fraction` | effect of light on gpp. 1: no stress, 0: complete stress | `light_effect_gpp` | `diagnostics__gpp_f_light` |
| `gpp_f_soilW` | `fraction` | effect of soil moisture on gpp. 1: no stress, 0: complete stress | `soil_moisture_effect_gpp` | `diagnostics__gpp_f_soilW` |
| `gpp_f_vpd` | `fraction` | effect of vpd on gpp. 1: no stress, 0: complete stress | `vapor_pressure_deficit_effect_gpp` | `diagnostics__gpp_f_vpd` |
| `gpp_potential` | `gC/m2/time` | potential gross primary prorDcutivity | `potential_productivity` | `diagnostics__gpp_potential` |
| `k_respiration_maintain` | `/time` | metabolism rate for maintenance respiration | `loss_rate_maintenance_respiration` | `diagnostics__k_respiration_maintain` |
| `k_respiration_maintain_su` | `/time` | metabolism rate for maintenance respiration to be used in old analytical solution to steady state | `loss_rate_maintenance_respiration_spinup` | `diagnostics__k_respiration_maintain_su` |
| `k_shedding_leaf` | `/time` | loss rate of carbon flow from leaf to litter | `carbon_shedding_rate_leaf` | `diagnostics__k_shedding_leaf` |
| `k_shedding_leaf_frac` | `fraction` | fraction of carbon loss from leaf that flows to litter pool | `carbon_shedding_fraction_leaf` | `diagnostics__k_shedding_leaf_frac` |
| `k_shedding_root` | `/time` | loss rate of carbon flow from root to litter | `carbon_shedding_rate_root` | `diagnostics__k_shedding_root` |
| `k_shedding_root_frac` | `fraction` | fraction of carbon loss from root that flows to litter pool | `carbon_shedding_fraction_root` | `diagnostics__k_shedding_root_frac` |
| `leaf_to_reserve` | `/time` | loss rate of carbon flow from leaf to reserve | `carbon_flow_rate_leaf_to_reserve` | `diagnostics__leaf_to_reserve` |
| `leaf_to_reserve_frac` | `fraction` | fraction of carbon loss from leaf that flows to leaf | `carbon_flow_fraction_leaf_to_reserve` | `diagnostics__leaf_to_reserve_frac` |
| `max_root_depth` | `mm` | maximum depth of root | `maximum_rooting_depth` | `diagnostics__max_root_depth` |
| `p_E_vec` | `` | carbon flow efficiency | `p E vec` | `diagnostics__p_E_vec` |
| `p_F_vec` | `fraction` | carbon flow efficiency fraction | `p F vec` | `diagnostics__p_F_vec` |
| `reserve_to_leaf` | `/time` | loss rate of carbon flow from reserve to root | `carbon_flow_rate_reserve_to_leaf` | `diagnostics__reserve_to_leaf` |
| `reserve_to_leaf_frac` | `fraction` | fraction of carbon loss from reserve that flows to leaf | `carbon_flow_fraction_reserve_to_leaf` | `diagnostics__reserve_to_leaf_frac` |
| `reserve_to_root` | `/time` | loss rate of carbon flow from reserve to root | `carbon_flow_rate_reserve_to_root` | `diagnostics__reserve_to_root` |
| `reserve_to_root_frac` | `fraction` | fraction of carbon loss from reserve that flows to root | `carbon_flow_fraction_reserve_to_root` | `diagnostics__reserve_to_root_frac` |
| `root_to_reserve` | `/time` | loss rate of carbon flow from root to reserve | `carbon_flow_rate_root_to_reserve` | `diagnostics__root_to_reserve` |
| `root_to_reserve_frac` | `fraction` | fraction of carbon loss from root that flows to reserve | `carbon_flow_fraction_root_to_reserve` | `diagnostics__root_to_reserve_frac` |
| `root_water_efficiency` | `fraction` | a efficiency like number that indicates the ease/fraction of soil water that can extracted by the root per layer | `root_water_efficiency` | `diagnostics__root_water_efficiency` |
| `slope_eco_stressor` | `/time` | potential rate of change in ecosystem stress on carbon flow | `slope_carbon_flow_ecosystem_stressor` | `diagnostics__slope_eco_stressor` |
| `transpiration_supply` | `mm` | total amount of water available in soil for transpiration | `supply_moisture_for_transpiration` | `diagnostics__transpiration_supply` |
| `water_balance` | `mm` | misbalance of the water for the given time step calculated as the differences between total input, output and change in storages | `water_balance_error` | `diagnostics__water_balance` |
| `ηA` | `number` | scalar of autotrophic carbon pool for steady state guess | `eta_autotrophic_pools` | `diagnostics__ηA` |
| `ηH` | `number` | scalar of heterotrophic carbon pool for steady state guess | `eta_heterotrophic_pools` | `diagnostics__ηH` |

:::

## Others

:::details Show table (78)

**`callocation`** (4)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `cVeg_names` | `string` | name of vegetation carbon pools used for carbon allocation | `name_veg_pools` | `cAllocation__cVeg_names` |
| `cVeg_nzix` | `number` | number of pools/layers in each vegetation carbon component | `number_per_veg_pool` | `cAllocation__cVeg_nzix` |
| `cVeg_zix` | `number` | number of pools/layers in each vegetation carbon component | `index_veg_pools` | `cAllocation__cVeg_zix` |
| `c_allocation_to_veg` | `fraction` | carbon allocation to each vvegetation pool | `carbon_allocation_veg` | `cAllocation__c_allocation_to_veg` |

**`callocationtreefraction`** (1)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `cVeg_names_for_c_allocation_frac_tree` | `string` | name of vegetation carbon pools used in tree fraction correction for carbon allocation | `veg_pools_corrected_for_tree_cover` | `cAllocationTreeFraction__cVeg_names_for_c_allocation_frac_tree` |

**`ccycle`** (1)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `zixVeg` | `integer` | a vector of indices for vegetation pools within the array of carbon pools in cEco | `index_veg_pools` | `cCycle__zixVeg` |

**`ccycleconsistency`** (4)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `giver_lower_indices` | `number` | indices of carbon pools whose flow is >0 below the diagonal in carbon flow matrix | `carbon_giver_lower_indices` | `cCycleConsistency__giver_lower_indices` |
| `giver_lower_unique` | `number` | unique indices of carbon pools whose flow is >0 below the diagonal in carbon flow matrix | `carbon_giver_lower_unique_indices` | `cCycleConsistency__giver_lower_unique` |
| `giver_upper_indices` | `number` | indices of carbon pools whose flow is >0 above the diagonal in carbon flow matrix | `carbon_giver_upper_indices` | `cCycleConsistency__giver_upper_indices` |
| `giver_upper_unique` | `number` | unique indices of carbon pools whose flow is >0 above the diagonal in carbon flow matrix | `carbon_giver_upper_unique_indices` | `cCycleConsistency__giver_upper_unique` |

**`ccycledisturbance`** (2)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `c_lose_to_zix_vec` | `` |  | `index_carbon_loss_to_pool` | `cCycleDisturbance__c_lose_to_zix_vec` |
| `zix_veg_all` | `` |  | `index_all_veg_pools` | `cCycleDisturbance__zix_veg_all` |

**`cflow`** (3)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `aSrc` | `string` | name of the source pool for the carbon flow | `carbon_source_pool_name` | `cFlow__aSrc` |
| `aTrg` | `string` | name of the target pool for carbon flow | `carbon_target_pool_name` | `cFlow__aTrg` |
| `c_flow_A_vec_ind` | `number` | indices of flow from giver to taker for carbon flow vector | `index_carbon_flow_vector` | `cFlow__c_flow_A_vec_ind` |

**`constants`** (12)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `c_flow_order` | `number` | order of pooling while calculating the carbon flow | `carbon_flow_order` | `constants__c_flow_order` |
| `c_giver` | `number` | index of the source carbon pool for a given flow | `carbon_giver_pool` | `constants__c_giver` |
| `c_taker` | `number` | index of the source carbon pool for a given flow | `carbon_taker_pool` | `constants__c_taker` |
| `n_TWS` | `number` | total number of water pools | `num_layers_TWS` | `constants__n_TWS` |
| `n_groundW` | `number` | total number of layers in groundwater pool | `num_layers_groundW` | `constants__n_groundW` |
| `n_snowW` | `number` | total number of layers in snow pool | `num_layers_snowW` | `constants__n_snowW` |
| `n_soilW` | `number` | total number of layers in soil moisture pool | `num_layers_soilW` | `constants__n_soilW` |
| `n_surfaceW` | `number` | total number of layers in surface water pool | `num_layers_surfaceW` | `constants__n_surfaceW` |
| `o_one` | `number` | a helper type stable 1 to be used across all models | `type_stable_one` | `constants__o_one` |
| `t_three` | `number` | a type stable 3 | `t three` | `constants__t_three` |
| `t_two` | `number` | a type stable 2 | `t two` | `constants__t_two` |
| `z_zero` | `number` | a helper type stable 0 to be used across all models | `type_stable_zero` | `constants__z_zero` |

**`drainage`** (1)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `drainage` | `mm/time` | soil moisture drainage per soil layer | `soil_moisture_drainage` | `fluxes__drainage` |

**`evaporation`** (1)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `PET_evaporation` | `mm/time` | potential soil evaporation | `potential_soil_evaporation` | `fluxes__PET_evaporation` |

**`gppdiffradiation`** (2)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `CI_max` | `fraction` | maximum of cloudiness index until the time step from the beginning of simulation (including spinup) | `maximum_cloudiness_index` | `gppDiffRadiation__CI_max` |
| `CI_min` | `fraction` | minimum of cloudiness index until the time step from the beginning of simulation (including spinup) | `minimum_cloudiness_index` | `gppDiffRadiation__CI_min` |

**`models`** (3)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `c_model` | `symbol` | a base carbon cycle model to loop through the pools and fill the main or component pools needed for using static arrays. A mandatory field for every carbon model realization | `base_carbon_model` | `models__c_model` |
| `unsat_k_model` | `symbol` | name of the model used to calculate unsaturated hydraulic conductivity | `unsat k model` | `models__unsat_k_model` |
| `w_model` | `symbol` | a base water cycle model to loop through the pools and fill the main or component pools needed for using static arrays. A mandatory field for every water model/pool realization | `w model` | `models__w_model` |

**`percolation`** (1)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `percolation` | `mm/time` | amount of moisture percolating to the top soil layer | `soil_water_percolation` | `fluxes__percolation` |

**`properties`** (42)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `LIGEFF` | `fraction` |  | `LIGEFF` | `properties__LIGEFF` |
| `LIGNIN` | `fraction` |  | `LIGNIN` | `properties__LIGNIN` |
| `LITC2N` | `fraction` |  | `LITC2N` | `properties__LITC2N` |
| `MTF` | `fraction` |  | `MTF` | `properties__MTF` |
| `SCLIGNIN` | `fraction` |  | `SCLIGNIN` | `properties__SCLIGNIN` |
| `cumulative_soil_depths` | `mm` | the depth to the bottom of each soil layer | `cumulative_soil_depth` | `properties__cumulative_soil_depths` |
| `k_fc` | `mm/time` | hydraulic conductivity of soil at field capacity per layer | `k_field_capacity` | `properties__k_fc` |
| `k_sat` | `mm/time` | hydraulic conductivity of soil at saturation per layer | `k_saturated` | `properties__k_sat` |
| `k_wp` | `mm/time` | hydraulic conductivity of soil at wilting point per layer | `k_wilting_point` | `properties__k_wp` |
| `soil_layer_thickness` | `mm` | thickness of each soil layer | `soil_thickness_per_layer` | `properties__soil_layer_thickness` |
| `soil_α` | `number` | alpha parameter of soil per layer | `soil_α` | `properties__soil_α` |
| `soil_β` | `number` | beta parameter of soil per layer | `soil_β` | `properties__soil_β` |
| `sp_k_fc` | `mm/time` | calculated/input hydraulic conductivity of soil at field capacity per layer | `soil_property_k_fc` | `properties__sp_k_fc` |
| `sp_k_sat` | `mm/time` | calculated/input hydraulic conductivity of soil at saturation per layer | `soil_property_k_saturated` | `properties__sp_k_sat` |
| `sp_k_wp` | `mm/time` | calculated/input hydraulic conductivity of soil at wilting point per layer | `soil_property_k_wilting_point` | `properties__sp_k_wp` |
| `sp_α` | `number` | calculated/input alpha parameter of soil per layer | `soil_property_α` | `properties__sp_α` |
| `sp_β` | `number` | calculated/input beta parameter of soil per layer | `soil_property_β` | `properties__sp_β` |
| `sp_θ_fc` | `m3/m3` | calculated/input moisture content of soil at field capacity per layer | `soil_property_θ_field_capacity` | `properties__sp_θ_fc` |
| `sp_θ_sat` | `m3/m3` | calculated/input moisture content of soil at saturation (porosity) per layer | `soil_property_θ_saturated` | `properties__sp_θ_sat` |
| `sp_θ_wp` | `m3/m3` | calculated/input moisture content of soil at wilting point per layer | `soil_property_θ_wilting_point` | `properties__sp_θ_wp` |
| `sp_ψ_fc` | `m` | calculated/input matric potential of soil at field capacity per layer | `soil_property_ψ_field_capacity` | `properties__sp_ψ_fc` |
| `sp_ψ_sat` | `m` | calculated/input matric potential of soil at saturation per layer | `soil_property_ψ_saturated` | `properties__sp_ψ_sat` |
| `sp_ψ_wp` | `m` | calculated/input matric potential of soil at wiliting point per layer | `soil_property_ψ_wilting_point` | `properties__sp_ψ_wp` |
| `st_clay` | `fraction` | fraction of clay content in the soil | `soil_texture_clay` | `properties__st_clay` |
| `st_orgm` | `fraction` | fraction of organic matter content in the soil per layer | `soil_texture_orgm` | `properties__st_orgm` |
| `st_sand` | `fraction` | fraction of sand content in the soil per layer | `soil_texture_sand` | `properties__st_sand` |
| `st_silt` | `fraction` | fraction of silt content in the soil per layer | `soil_texture_silt` | `properties__st_silt` |
| `w_awc` | `mm` | maximum amount of water available for vegetation/transpiration per soil layer (w_sat-_wp) | `w_available_water_capacity` | `properties__w_awc` |
| `w_fc` | `mm` | amount of water in the soil at field capacity per layer | `w_field_capacity` | `properties__w_fc` |
| `w_sat` | `mm` | amount of water in the soil at saturation per layer | `w_saturated` | `properties__w_sat` |
| ` w_wp` | `mm` | amount of water in the soil at wiliting point per layer | `wilting_point` | `properties__w_wp` |
| `θ_fc` | `m3/m3` | moisture content of soil at field capacity per layer | `θ_field_capacity` | `properties__θ_fc` |
| `θ_sat` | `m3/m3` | moisture content of soil at saturation (porosity) per layer | `θ_saturated` | `properties__θ_sat` |
| `θ_wp` | `m3/m3` | moisture content of soil at wilting point per layer | `θ_wilting_point` | `properties__θ_wp` |
| `ψ_fc` | `m` | matric potential of soil at field capacity per layer | `ψ_field_capacity` | `properties__ψ_fc` |
| `ψ_sat` | `m` | matric potential of soil at saturation per layer | `ψ_saturated` | `properties__ψ_sat` |
| `ψ_wp` | `m` | matric potential of soil at wiliting point per layer | `ψ_wilting_point` | `properties__ψ_wp` |
| `∑soil_depth` | `mm` | total depth of soil | `total_depth_of_soil_column` | `properties__∑soil_depth` |
| `∑available_water_capacity` | `mm` | total amount of water available for vegetation/transpiration | `∑available_water_capacity` | `properties__∑w_awc` |
| `∑w_fc` | `mm` | total amount of water in the soil at field capacity | `∑w_field_capacity` | `properties__∑w_fc` |
| `∑w_sat` | `mm` | total amount of water in the soil at saturation | `∑w_saturated` | `properties__∑w_sat` |
| `∑w_wp` | `mm` | total amount of water in the soil at wiliting point | `∑wilting_point` | `properties__∑w_wp` |

**`rootwaterefficiency`** (1)

| standard_name | units | description | long_name | Key |
|---|---|---|---|---|
| `root_over` | `boolean` | a boolean indicating if the root is allowed to exract water from a given layer depending on maximum rooting depth | `is_root_over` | `rootWaterEfficiency__root_over` |

:::

