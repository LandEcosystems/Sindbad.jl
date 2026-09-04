"""
`SindbadTEM.Variables`

Submodule that exposes the canonical SINDBAD TEM variable catalog and
convenience helpers such as `sindbad_tem_variables`, `getVariableInfo`,
and `whatIs`.

Use this module when you need **metadata about model variables** (names,
units, descriptions, and land fields) for documentation, IO, or diagnostics.
"""
module Variables
    using ..SindbadTEM
    import ..SindbadTEM: DataStructures
    import ..SindbadTEM.TEMTypes: LandEcosystem

    export checkMissingVarInfo
    export defaultVariableInfo
    export getUniqueVarNames
    export getVarFull
    export getVariableInfo
    export sindbad_tem_variables
    export whatIs

    orD = DataStructures.OrderedDict

"""
`sindbad_tem_variables`

A dictionary of dictionaries that contains information about the variables in the SINDBAD models. The keys of the outer dictionary are the variable names and the inner dictionaries contain the following keys:

- `standard_name`: the standard name of the variable
- `long_name`: a longer description of the variable
- `units`: the units of the variable
- `land_field`: the field in the SINDBAD model where the variable is used
- `description`: a description of the variable
"""
sindbad_tem_variables = orD{Symbol,orD{Symbol,String}}(
    :cAllocationTreeFraction__cVeg_names_for_c_allocation_frac_tree => orD(
        :standard_name => "cVeg_names_for_c_allocation_frac_tree",
        :long_name => "veg_pools_corrected_for_tree_cover",
        :units => "string",
        :land_field => "cAllocationTreeFraction",
        :description => "name of vegetation carbon pools used in tree fraction correction for carbon allocation"
    ),
    :cAllocation__cVeg_names => orD(
        :standard_name => "cVeg_names",
        :long_name => "name_veg_pools",
        :units => "string",
        :land_field => "cAllocation",
        :description => "name of vegetation carbon pools used for carbon allocation"
    ),
    :cAllocation__cVeg_nzix => orD(
        :standard_name => "cVeg_nzix",
        :long_name => "number_per_veg_pool",
        :units => "number",
        :land_field => "cAllocation",
        :description => "number of pools/layers in each vegetation carbon component"
    ),
    :cAllocation__cVeg_zix => orD(
        :standard_name => "cVeg_zix",
        :long_name => "index_veg_pools",
        :units => "number",
        :land_field => "cAllocation",
        :description => "number of pools/layers in each vegetation carbon component"
    ),
    :cAllocation__c_allocation_to_veg => orD(
        :standard_name => "c_allocation_to_veg",
        :long_name => "carbon_allocation_veg",
        :units => "fraction",
        :land_field => "cAllocation",
        :description => "carbon allocation to each vvegetation pool"
    ),
    :cCycle__zixVeg => orD(
       :standard_name => "zixVeg",
       :long_name => "index_veg_pools",
       :units => "integer",
       :land_field => "cCycle",
       :description => "a vector of indices for vegetation pools within the array of carbon pools in cEco",
    ),
    :cCycleConsistency__giver_lower_indices => orD(
        :standard_name => "giver_lower_indices",
        :long_name => "carbon_giver_lower_indices",
        :units => "number",
        :land_field => "cCycleConsistency",
        :description => "indices of carbon pools whose flow is >0 below the diagonal in carbon flow matrix"
    ),
    :cCycleConsistency__giver_lower_unique => orD(
        :standard_name => "giver_lower_unique",
        :long_name => "carbon_giver_lower_unique_indices",
        :units => "number",
        :land_field => "cCycleConsistency",
        :description => "unique indices of carbon pools whose flow is >0 below the diagonal in carbon flow matrix"
    ),
    :cCycleConsistency__giver_upper_indices => orD(
        :standard_name => "giver_upper_indices",
        :long_name => "carbon_giver_upper_indices",
        :units => "number",
        :land_field => "cCycleConsistency",
        :description => "indices of carbon pools whose flow is >0 above the diagonal in carbon flow matrix"
    ),
    :cCycleConsistency__giver_upper_unique => orD(
        :standard_name => "giver_upper_unique",
        :long_name => "carbon_giver_upper_unique_indices",
        :units => "number",
        :land_field => "cCycleConsistency",
        :description => "unique indices of carbon pools whose flow is >0 above the diagonal in carbon flow matrix"
    ),
    :cCycleDisturbance__c_lose_to_zix_vec => orD(
        :standard_name => "c_lose_to_zix_vec",
        :long_name => "index_carbon_loss_to_pool",
        :units => "",
        :land_field => "cCycleDisturbance",
        :description => ""
    ),
    :cCycleDisturbance__zix_veg_all => orD(
        :standard_name => "zix_veg_all",
        :long_name => "index_all_veg_pools",
        :units => "",
        :land_field => "cCycleDisturbance",
        :description => ""
    ),
    :cFlow__aSrc => orD(
        :standard_name => "aSrc",
        :long_name => "carbon_source_pool_name",
        :units => "string",
        :land_field => "cFlow",
        :description => "name of the source pool for the carbon flow"
    ),
    :cFlow__aTrg => orD(
        :standard_name => "aTrg",
        :long_name => "carbon_target_pool_name",
        :units => "string",
        :land_field => "cFlow",
        :description => "name of the target pool for carbon flow"
    ),
    :constants__n_groundW => orD(
        :standard_name => "n_groundW",
        :long_name => "num_layers_groundW",
        :units => "number",
        :land_field => "constants",
        :description => "total number of layers in groundwater pool"
    ),
    :constants__n_snowW => orD(
        :standard_name => "n_snowW",
        :long_name => "num_layers_snowW",
        :units => "number",
        :land_field => "constants",
        :description => "total number of layers in snow pool"
    ),
    :constants__n_soilW => orD(
        :standard_name => "n_soilW",
        :long_name => "num_layers_soilW",
        :units => "number",
        :land_field => "constants",
        :description => "total number of layers in soil moisture pool"
    ),
    :constants__n_surfaceW => orD(
        :standard_name => "n_surfaceW",
        :long_name => "num_layers_surfaceW",
        :units => "number",
        :land_field => "constants",
        :description => "total number of layers in surface water pool"
    ),
    :constants__n_TWS => orD(
        :standard_name => "n_TWS",
        :long_name => "num_layers_TWS",
        :units => "number",
        :land_field => "constants",
        :description => "total number of water pools"
    ),
    :constants__o_one => orD(
        :standard_name => "o_one",
        :long_name => "type_stable_one",
        :units => "number",
        :land_field => "constants",
        :description => "a helper type stable 1 to be used across all models"
    ),
    :constants__t_three => orD(
        :standard_name => "t_three",
        :long_name => "t three",
        :units => "number",
        :land_field => "constants",
        :description => "a type stable 3"
    ),
    :constants__t_two => orD(
        :standard_name => "t_two",
        :long_name => "t two",
        :units => "number",
        :land_field => "constants",
        :description => "a type stable 2"
    ),
    :constants__z_zero => orD(
        :standard_name => "z_zero",
        :long_name => "type_stable_zero",
        :units => "number",
        :land_field => "constants",
        :description => "a helper type stable 0 to be used across all models"
    ),
    :diagnostics__auto_respiration_f_airT => orD(
        :standard_name => "auto_respiration_f_airT",
        :long_name => "air_temperature_effect_autotrophic_respiration",
        :units => "scalar",
        :land_field => "diagnostics",
        :description => "effect of air temperature on autotrophic respiration. 0: no decomposition, >1 increase in decomposition rate"
    ),
    :diagnostics__c_allocation => orD(
        :standard_name => "c_allocation",
        :long_name => "cabon_allocation",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "fraction of gpp allocated to different (live) carbon pools"
    ),
    :diagnostics__c_allocation_f_LAI => orD(
        :standard_name => "c_allocation_f_LAI",
        :long_name => "LAI_effect_carbon_allocation",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "effect of LAI on carbon allocation. 1: no stress, 0: complete stress"
    ),
    :diagnostics__c_allocation_f_W_N => orD(
        :standard_name => "c_allocation_f_W_N",
        :long_name => "W_N_effect_carbon_allocation",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "effect of water and nutrient on carbon allocation. 1: no stress, 0: complete stress"
    ),
    :diagnostics__c_allocation_f_cloud => orD(
        :standard_name => "c_allocation_f_cloud",
        :long_name => "cloud_effect_carbon_allocation",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "effect of cloud on carbon allocation. 1: no stress, 0: complete stress"
    ),
    :diagnostics__c_allocation_f_soilT => orD(
        :standard_name => "c_allocation_f_soilT",
        :long_name => "soil_temperature_effect_carbon_allocation",
        :units => "scalar",
        :land_field => "diagnostics",
        :description => "effect of soil temperature on carbon allocation. 1: no stress, 0: complete stress"
    ),
    :diagnostics__c_allocation_f_soilW => orD(
        :standard_name => "c_allocation_f_soilW",
        :long_name => "soil_moisture_effect_carbon_allocation",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "effect of soil moisture on carbon allocation. 1: no stress, 0: complete stress"
    ),
    :diagnostics__c_eco_k => orD(
        :standard_name => "c_eco_k",
        :long_name => "carbon_decomposition_rate",
        :units => "/time",
        :land_field => "diagnostics",
        :description => "decomposition rate of carbon per pool"
    ),
    :diagnostics__c_eco_k_base => orD(
        :standard_name => "c_eco_k_base",
        :long_name => "c eco k base",
        :units => "/time",
        :land_field => "diagnostics",
        :description => "base carbon decomposition rate of the carbon pools"
    ),
    :diagnostics__c_eco_k_f_LAI => orD(
        :standard_name => "c_eco_k_f_LAI",
        :long_name => "LAI_effect_carbon_decomposition_rate",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "effect of LAI on carbon decomposition rate. 1: no stress, 0: complete stress"
    ),
    :diagnostics__c_eco_k_f_soil_props => orD(
        :standard_name => "c_eco_k_f_soil_props",
        :long_name => "soil_property_effect_carbon_decomposition_rate",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "effect of soil_props on carbon decomposition rate. 1: no stress, 0: complete stress"
    ),
    :diagnostics__c_eco_k_f_soilT => orD(
        :standard_name => "c_eco_k_f_soilT",
        :long_name => "soil_temperature_effect_carbon_decomposition_rate",
        :units => "scalar",
        :land_field => "diagnostics",
        :description => "effect of soil temperature on heterotrophic respiration respiration. 0: no decomposition, >1 increase in decomposition"
    ),
    :diagnostics__c_eco_k_f_soilW => orD(
        :standard_name => "c_eco_k_f_soilW",
        :long_name => "soil_moisture_effect_carbon_decomposition_rate",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "effect of soil moisture on carbon decomposition rate. 1: no stress, 0: complete stress"
    ),
    :diagnostics__c_eco_k_f_veg_props => orD(
        :standard_name => "c_eco_k_f_veg_props",
        :long_name => "vegetation_property_effect_carbon_decomposition_rate",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "effect of veg_props on carbon decomposition rate. 1: no stress, 0: complete stress"
    ),
    :diagnostics__c_eco_τ => orD(
        :standard_name => "c_eco_τ",
        :long_name => "carbon_turnover_per_pool",
        :units => "years",
        :land_field => "diagnostics",
        :description => "number of years needed for carbon turnover per carbon pool"
    ),
    :cCycleBase__c_flow_order => orD(
        :standard_name => "c_flow_order",
        :long_name => "carbon_flow_order",
        :units => "number",
        :land_field => "cCycleBase",
        :description => "order of pooling while calculating the carbon flow"
    ),
    :cCycleBase__c_giver => orD(
        :standard_name => "c_giver",
        :long_name => "carbon_giver_pool",
        :units => "number",
        :land_field => "cCycleBase",
        :description => "index of the source carbon pool for a given flow"
    ),
    :cCycleBase__c_taker => orD(
        :standard_name => "c_taker",
        :long_name => "carbon_taker_pool",
        :units => "number",
        :land_field => "cCycleBase",
        :description => "index of the receiving carbon pool for a given flow"
    ),
    :cCycleBase__c_flow_named_edges => orD(
        :standard_name => "c_flow_named_edges",
        :long_name => "carbon_flow_named_edges",
        :units => "",
        :land_field => "cCycleBase",
        :description => "flow vector positions bucketed by the pool name pair they connect, as giver_to_taker, so that a cFlow approach can find the entry carrying a named transfer without knowing its index"
    ),
    :diagnostics__c_flow_A_array => orD(
        :standard_name => "c_flow_A_array",
        :long_name => "carbon_flow_array",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "an array indicating the flow direction and connections across different pools, with elements larger than 0 indicating flow from column pool to row pool"
    ),
    :diagnostics__c_flow_A_vec => orD(
        :standard_name => "c_flow_A_vec",
        :long_name => "carbon_flow_vector",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "fraction of the carbon loss fron a (giver) pool that flows to a (taker) pool"
    ),
    :diagnostics__c_flow_E_array => orD(
        :standard_name => "c_flow_E_array",
        :long_name => "carbon_flow_efficiency_array",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "an array containing the efficiency of each flow in the c_flow_A_array"
    ),
    :diagnostics__C_to_N_cVeg => orD(
        :standard_name => "C_to_N_cVeg",
        :long_name => "carbon_to_nitrogen_ratio",
        :units => "ratio",
        :land_field => "diagnostics",
        :description => "carbon to nitrogen ratio in the vegetation pools"
    ),
    :diagnostics__eco_stressor => orD(
        :standard_name => "eco_stressor",
        :long_name => "carbon_flow_ecosystem_stressor",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "ecosystem stress on carbon flow"
    ),
    :diagnostics__eco_stressor_prev => orD(
        :standard_name => "eco_stressor_prev",
        :long_name => "carbon_flow_ecosystem_stressor_previous_timestep",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "ecosystem stress on carbon flow in the previous time step"
    ),
    :diagnostics__gpp_f_airT => orD(
        :standard_name => "gpp_f_airT",
        :long_name => "air_temperature_effect_gpp",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "effect of air temperature on gpp. 1: no stress, 0: complete stress"
    ),
    :diagnostics__gpp_climate_stressors => orD(
        :standard_name => "gpp_climate_stressors",
        :long_name => "climate_effect_per_factor_gpp",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "a collection of all gpp climate stressors including light, temperature, radiation, and vpd"
    ),
    :diagnostics__gpp_demand => orD(
        :standard_name => "gpp_demand",
        :long_name => "demand_driven_gpp",
        :units => "gC/m2/time",
        :land_field => "diagnostics",
        :description => "demand driven gross primary prorDuctivity"
    ),
    :diagnostics__gpp_f_climate => orD(
        :standard_name => "gpp_f_climate",
        :long_name => "net_climate_effect_gpp",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "effect of climate on gpp. 1: no stress, 0: complete stress"
    ),
    :diagnostics__gpp_f_cloud => orD(
        :standard_name => "gpp_f_cloud",
        :long_name => "cloudiness_index_effect_gpp",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "effect of cloud on gpp. 1: no stress, 0: complete stress"
    ),
    :diagnostics__gpp_f_light => orD(
        :standard_name => "gpp_f_light",
        :long_name => "light_effect_gpp",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "effect of light on gpp. 1: no stress, 0: complete stress"
    ),
    :diagnostics__gpp_f_soilW => orD(
        :standard_name => "gpp_f_soilW",
        :long_name => "soil_moisture_effect_gpp",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "effect of soil moisture on gpp. 1: no stress, 0: complete stress"
    ),
    :diagnostics__gpp_f_vpd => orD(
        :standard_name => "gpp_f_vpd",
        :long_name => "vapor_pressure_deficit_effect_gpp",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "effect of vpd on gpp. 1: no stress, 0: complete stress"
    ),
    :diagnostics__gpp_potential => orD(
        :standard_name => "gpp_potential",
        :long_name => "potential_productivity",
        :units => "gC/m2/time",
        :land_field => "diagnostics",
        :description => "potential gross primary prorDcutivity"
    ),
    :diagnostics__k_respiration_maintain => orD(
        :standard_name => "k_respiration_maintain",
        :long_name => "loss_rate_maintenance_respiration",
        :units => "/time",
        :land_field => "diagnostics",
        :description => "metabolism rate for maintenance respiration"
    ),
    :diagnostics__k_respiration_maintain_su => orD(
        :standard_name => "k_respiration_maintain_su",
        :long_name => "loss_rate_maintenance_respiration_spinup",
        :units => "/time",
        :land_field => "diagnostics",
        :description => "metabolism rate for maintenance respiration to be used in old analytical solution to steady state"
    ),
    :diagnostics__k_shedding_leaf => orD(
        :standard_name => "k_shedding_leaf",
        :long_name => "carbon_shedding_rate_leaf",
        :units => "/time",
        :land_field => "diagnostics",
        :description => "loss rate of carbon flow from leaf to litter"
    ),
    :diagnostics__k_shedding_leaf_frac => orD(
        :standard_name => "k_shedding_leaf_frac",
        :long_name => "carbon_shedding_fraction_leaf",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "fraction of carbon loss from leaf that flows to litter pool"
    ),
    :diagnostics__k_shedding_root => orD(
        :standard_name => "k_shedding_root",
        :long_name => "carbon_shedding_rate_root",
        :units => "/time",
        :land_field => "diagnostics",
        :description => "loss rate of carbon flow from root to litter"
    ),
    :diagnostics__k_shedding_root_frac => orD(
        :standard_name => "k_shedding_root_frac",
        :long_name => "carbon_shedding_fraction_root",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "fraction of carbon loss from root that flows to litter pool"
    ),
    :diagnostics__leaf_to_reserve => orD(
        :standard_name => "leaf_to_reserve",
        :long_name => "carbon_flow_rate_leaf_to_reserve",
        :units => "/time",
        :land_field => "diagnostics",
        :description => "loss rate of carbon flow from leaf to reserve"
    ),
    :diagnostics__leaf_to_reserve_frac => orD(
        :standard_name => "leaf_to_reserve_frac",
        :long_name => "carbon_flow_fraction_leaf_to_reserve",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "fraction of carbon loss from leaf that flows to leaf"
    ),
    :diagnostics__max_root_depth => orD(
        :standard_name => "max_root_depth",
        :long_name => "maximum_rooting_depth",
        :units => "mm",
        :land_field => "diagnostics",
        :description => "maximum depth of root"
    ),
    :diagnostics__ηA => orD(
        :standard_name => "ηA",
        :long_name => "eta_autotrophic_pools",
        :units => "number",
        :land_field => "diagnostics",
        :description => "scalar of autotrophic carbon pool for steady state guess"
    ),
    :diagnostics__ηH => orD(
        :standard_name => "ηH",
        :long_name => "eta_heterotrophic_pools",
        :units => "number",
        :land_field => "diagnostics",
        :description => "scalar of heterotrophic carbon pool for steady state guess"
    ),
    :diagnostics__p_E_vec => orD(
        :standard_name => "p_E_vec",
        :long_name => "p E vec",
        :units => "",
        :land_field => "diagnostics",
        :description => ""
    ),
    :diagnostics__p_F_vec => orD(
        :standard_name => "p_F_vec",
        :long_name => "p F vec",
        :units => "",
        :land_field => "diagnostics",
        :description => ""
    ),
    :diagnostics__p_E_vec => orD(
        :standard_name => "p_E_vec",
        :long_name => "p E vec",
        :units => "",
        :land_field => "diagnostics",
        :description => "carbon flow efficiency"
    ),
    :diagnostics__p_F_vec => orD(
        :standard_name => "p_F_vec",
        :long_name => "p F vec",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "carbon flow efficiency fraction"
    ),
    :diagnostics__reserve_to_leaf => orD(
        :standard_name => "reserve_to_leaf",
        :long_name => "carbon_flow_rate_reserve_to_leaf",
        :units => "/time",
        :land_field => "diagnostics",
        :description => "loss rate of carbon flow from reserve to root"
    ),
    :diagnostics__reserve_to_leaf_frac => orD(
        :standard_name => "reserve_to_leaf_frac",
        :long_name => "carbon_flow_fraction_reserve_to_leaf",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "fraction of carbon loss from reserve that flows to leaf"
    ),
    :diagnostics__reserve_to_root => orD(
        :standard_name => "reserve_to_root",
        :long_name => "carbon_flow_rate_reserve_to_root",
        :units => "/time",
        :land_field => "diagnostics",
        :description => "loss rate of carbon flow from reserve to root"
    ),
    :diagnostics__reserve_to_root_frac => orD(
        :standard_name => "reserve_to_root_frac",
        :long_name => "carbon_flow_fraction_reserve_to_root",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "fraction of carbon loss from reserve that flows to root"
    ),
    :diagnostics__root_to_reserve => orD(
        :standard_name => "root_to_reserve",
        :long_name => "carbon_flow_rate_root_to_reserve",
        :units => "/time",
        :land_field => "diagnostics",
        :description => "loss rate of carbon flow from root to reserve"
    ),
    :diagnostics__root_to_reserve_frac => orD(
        :standard_name => "root_to_reserve_frac",
        :long_name => "carbon_flow_fraction_root_to_reserve",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "fraction of carbon loss from root that flows to reserve"
    ),
    :diagnostics__root_water_efficiency => orD(
        :standard_name => "root_water_efficiency",
        :long_name => "root_water_efficiency",
        :units => "fraction",
        :land_field => "diagnostics",
        :description => "a efficiency like number that indicates the ease/fraction of soil water that can extracted by the root per layer"
    ),
    :diagnostics__slope_eco_stressor => orD(
        :standard_name => "slope_eco_stressor",
        :long_name => "slope_carbon_flow_ecosystem_stressor",
        :units => "/time",
        :land_field => "diagnostics",
        :description => "potential rate of change in ecosystem stress on carbon flow"
    ),
    :diagnostics__transpiration_supply => orD(
        :standard_name => "transpiration_supply",
        :long_name => "supply_moisture_for_transpiration",
        :units => "mm",
        :land_field => "diagnostics",
        :description => "total amount of water available in soil for transpiration"
    ),
    :diagnostics__water_balance => orD(
        :standard_name => "water_balance",
        :long_name => "water_balance_error",
        :units => "mm",
        :land_field => "diagnostics",
        :description => "misbalance of the water for the given time step calculated as the differences between total input, output and change in storages"
    ),
    :diagnostics__WUE => orD(
        :standard_name => "WUE",
        :long_name => "ecosystem_water_use_efficiency",
        :units => "gC/mmH2O",
        :land_field => "diagnostics",
        :description => "water use efficiency of the ecosystem"
    ),
    :diagnostics__WUENoCO2 => orD(
        :standard_name => "WUENoCO2",
        :long_name => "ecosystem_water_use_efficiency_without_co2_effect",
        :units => "gC/mmH2O",
        :land_field => "diagnostics",
        :description => "water use efficiency of the ecosystem without CO2 effect"
    ),
    :fluxes__auto_respiration => orD(
        :standard_name => "auto_respiration",
        :long_name => "autotrophic_respiration",
        :units => "gC/m2/time",
        :land_field => "fluxes",
        :description => "carbon loss due to autotrophic respiration"
    ),
    :fluxes__auto_respiration_growth => orD(
        :standard_name => "auto_respiration_growth",
        :long_name => "growth_respiration",
        :units => "gC/m2/time",
        :land_field => "fluxes",
        :description => "growth respiration per vegetation pool"
    ),
    :fluxes__auto_respiration_maintain => orD(
        :standard_name => "auto_respiration_maintain",
        :long_name => "maintenance_respiration",
        :units => "gC/m2/time",
        :land_field => "fluxes",
        :description => "maintenance respiration per vegetation pool"
    ),
    :fluxes__base_runoff => orD(
        :standard_name => "base_runoff",
        :long_name => "base_runoff",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "base runoff"
    ),
    :fluxes__c_eco_efflux => orD(
        :standard_name => "c_eco_efflux",
        :long_name => "autotrophic_carbon_loss",
        :units => "gC/m2/time",
        :land_field => "fluxes",
        :description => "losss of carbon from (live) vegetation pools due to autotrophic respiration"
    ),
    :fluxes__c_eco_flow => orD(
        :standard_name => "c_eco_flow",
        :long_name => "net_carbon_flow",
        :units => "gC/m2/time",
        :land_field => "fluxes",
        :description => "flow of carbon to a given carbon pool from other carbon pools"
    ),
    :fluxes__c_eco_influx => orD(
        :standard_name => "c_eco_influx",
        :long_name => "net_carbon_influx",
        :units => "gC/m2/time",
        :land_field => "fluxes",
        :description => "net influx from allocation and efflux (npp) to each (live) carbon pool"
    ),
    :fluxes__c_eco_npp => orD(
        :standard_name => "c_eco_npp",
        :long_name => "carbon_net_primary_productivity",
        :units => "gC/m2/time",
        :land_field => "fluxes",
        :description => "npp of each carbon pool"
    ),
    :fluxes__c_eco_out => orD(
        :standard_name => "c_eco_out",
        :long_name => "total_carbon_loss",
        :units => "gC/m2/time",
        :land_field => "fluxes",
        :description => "outflux of carbon from each carbol pool"
    ),
    :fluxes__drainage => orD(
        :standard_name => "drainage",
        :long_name => "soil_moisture_drainage",
        :units => "mm/time",
        :land_field => "drainage",
        :description => "soil moisture drainage per soil layer"
    ),
    :fluxes__eco_respiration => orD(
        :standard_name => "ecosystem_respiration",
        :long_name => "total_ecosystem_respiration",
        :units => "gC/m2/time",
        :land_field => "fluxes",
        :description => "carbon loss due to ecosystem respiration"
    ),
    :fluxes__evaporation => orD(
        :standard_name => "evaporation",
        :long_name => "soil_evaporation",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "evaporation from the first soil layer"
    ),
    :fluxes__evapotranspiration => orD(
        :standard_name => "evapotranspiration",
        :long_name => "total_land_evaporation",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "total land evaporation including soil evaporation, vegetation transpiration, snow sublimation, and interception loss"
    ),
    :fluxes__gpp => orD(
        :standard_name => "gpp",
        :long_name => "gross_primary_productivity",
        :units => "gC/m2/time",
        :land_field => "fluxes",
        :description => "gross primary prorDcutivity"
    ),
    :fluxes__gw_capillary_flux => orD(
        :standard_name => "gw_capillary_flux",
        :long_name => "groundwater_capillary_flux",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "capillary flux from top groundwater layer to the lowermost soil layer"
    ),
    :fluxes__gw_recharge => orD(
        :standard_name => "gw_recharge",
        :long_name => "groundwater_recharge",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "net groundwater recharge from the lowermost soil layer, positive => soil to groundwater"
    ),
    :fluxes__hetero_respiration => orD(
        :standard_name => "hetero_respiration",
        :long_name => "heterotrophic_respiration",
        :units => "gC/m2/time",
        :land_field => "fluxes",
        :description => "carbon loss due to heterotrophic respiration"
    ),
    :fluxes__interflow_runoff => orD(
        :standard_name => "interflow_runoff",
        :long_name => "interflow_runoff",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "runoff loss from interflow in soil layers"
    ),
    :fluxes__interception => orD(
        :standard_name => "interception",
        :long_name => "interception_loss",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "interception evaporation loss"
    ),
    :fluxes__nee => orD(
        :standard_name => "nee",
        :long_name => "net_ecosystem_exchange",
        :units => "gC/m2/time",
        :land_field => "fluxes",
        :description => "net ecosystem carbon exchange for the ecosystem. negative value indicates carbon sink."
    ),
    :fluxes__npp => orD(
        :standard_name => "npp",
        :long_name => "carbon_net_primary_productivity",
        :units => "gC/m2/time",
        :land_field => "fluxes",
        :description => "net primary prorDcutivity"
    ),
    :fluxes__overland_runoff => orD(
        :standard_name => "overland_runoff",
        :long_name => "overland_runoff",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "overland runoff as a fraction of incoming water"
    ),
    :fluxes__percolation => orD(
        :standard_name => "percolation",
        :long_name => "soil_water_percolation",
        :units => "mm/time",
        :land_field => "percolation",
        :description => "amount of moisture percolating to the top soil layer"
    ),
    :fluxes__PET => orD(
        :standard_name => "PET",
        :long_name => "potential_evapotranspiration",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "potential evapotranspiration"
    ),
    :fluxes__PET_evaporation => orD(
        :standard_name => "PET_evaporation",
        :long_name => "potential_soil_evaporation",
        :units => "mm/time",
        :land_field => "evaporation",
        :description => "potential soil evaporation"
    ),
    :fluxes__precip => orD(
        :standard_name => "precip",
        :long_name => "total_precipiration",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "total land precipitation including snow and rain"
    ),
    :fluxes__rain => orD(
        :standard_name => "rain",
        :long_name => "rainfall",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "amount of precipitation in liquid form"
    ),
    :fluxes__root_water_uptake => orD(
        :standard_name => "root_water_uptake",
        :long_name => "root_water_uptake",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "amount of water uptaken for transpiration per soil layer"
    ),
    :fluxes__runoff => orD(
        :standard_name => "runoff",
        :long_name => "total_runoff",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "total runoff"
    ),
    :fluxes__sat_excess_runoff => orD(
        :standard_name => "sat_excess_runoff",
        :long_name => "saturation_excess_runoff",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "saturation excess runoff"
    ),
    :fluxes__snow => orD(
        :standard_name => "snow",
        :long_name => "snowfall",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "amount of precipitation in solid form"
    ),
    :fluxes__snow_melt => orD(
        :standard_name => "snow_melt",
        :long_name => "snow_melt_flux",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "snow melt"
    ),
    :fluxes__soil_capillary_flux => orD(
        :standard_name => "soil_capillary_flux",
        :long_name => "soil_capillary_flux",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "soil capillary flux per layer"
    ),
    :fluxes__sublimation => orD(
        :standard_name => "sublimation",
        :long_name => "snow_sublimation",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "sublimation of the snow"
    ),
    :fluxes__surface_runoff => orD(
        :standard_name => "surface_runoff",
        :long_name => "total_surface_runoff",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "total surface runoff"
    ),
    :fluxes__transpiration => orD(
        :standard_name => "transpiration",
        :long_name => "transpiration",
        :units => "mm/time",
        :land_field => "fluxes",
        :description => "transpiration"
    ),
    :fluxes__zero_c_eco_flow => orD(
        :standard_name => "zero_c_eco_flow",
        :long_name => "zero_vector_for_c_eco_flow",
        :units => "gC/m2/time",
        :land_field => "fluxes",
        :description => "helper for resetting c_eco_flow in every time step"
    ),
    :fluxes__zero_c_eco_influx => orD(
        :standard_name => "zero_c_eco_influx",
        :long_name => "zero_vector_for_c_eco_influx",
        :units => "gC/m2/time",
        :land_field => "fluxes",
        :description => "helper for resetting c_eco_influx in every time step"
    ),
    :gppDiffRadiation__CI_max => orD(
        :standard_name => "CI_max",
        :long_name => "maximum_cloudiness_index",
        :units => "fraction",
        :land_field => "gppDiffRadiation",
        :description => "maximum of cloudiness index until the time step from the beginning of simulation (including spinup)"
    ),
    :gppDiffRadiation__CI_min => orD(
        :standard_name => "CI_min",
        :long_name => "minimum_cloudiness_index",
        :units => "fraction",
        :land_field => "gppDiffRadiation",
        :description => "minimum of cloudiness index until the time step from the beginning of simulation (including spinup)"
    ),
    :models__c_model => orD(
        :standard_name => "c_model",
        :long_name => "base_carbon_model",
        :units => "symbol",
        :land_field => "models",
        :description => "a base carbon cycle model to loop through the pools and fill the main or component pools needed for using static arrays. A mandatory field for every carbon model realization"
    ),
    :models__unsat_k_model => orD(
        :standard_name => "unsat_k_model",
        :long_name => "unsat k model",
        :units => "symbol",
        :land_field => "models",
        :description => "name of the model used to calculate unsaturated hydraulic conductivity"
    ),
    :models__w_model => orD(
        :standard_name => "w_model",
        :long_name => "w model",
        :units => "symbol",
        :land_field => "models",
        :description => "a base water cycle model to loop through the pools and fill the main or component pools needed for using static arrays. A mandatory field for every water model/pool realization"
    ),
    :pools__cEco => orD(
        :standard_name => "cEco",
        :long_name => "ecosystem_carbon_storage_content",
        :units => "gC/m2",
        :land_field => "pools",
        :description => "carbon content of cEco pool(s)"
    ),
    :pools__cLit => orD(
        :standard_name => "cLit",
        :long_name => "litter_carbon_storage_content",
        :units => "gC/m2",
        :land_field => "pools",
        :description => "carbon content of cLit pool(s)"
    ),
    :pools__cLitFast => orD(
        :standard_name => "cLitFast",
        :long_name => "litter_carbon_storage_content_fast_turnover",
        :units => "gC/m2",
        :land_field => "pools",
        :description => "carbon content of cLitFast pool(s)"
    ),
    :pools__cLitSlow => orD(
        :standard_name => "litter_carbon_storage_content_slow_turnover",
        :long_name => "cLitSlow",
        :units => "gC/m2",
        :land_field => "pools",
        :description => "carbon content of cLitSlow pool(s)"
    ),
    :pools__cSoil => orD(
        :standard_name => "cSoil",
        :long_name => "soil_carbon_storage_content",
        :units => "gC/m2",
        :land_field => "pools",
        :description => "carbon content of cSoil pool(s)"
    ),
    :pools__cSoilOld => orD(
        :standard_name => "cSoilOld",
        :long_name => "old_soil_carbon_storage_content_slow_turnover",
        :units => "gC/m2",
        :land_field => "pools",
        :description => "carbon content of cSoilOld pool(s)"
    ),
    :pools__cSoilSlow => orD(
        :standard_name => "cSoilSlow",
        :long_name => "soil_carbon_storage_content_slow_turnover",
        :units => "gC/m2",
        :land_field => "pools",
        :description => "carbon content of cSoilSlow pool(s)"
    ),
    :pools__cVeg => orD(
        :standard_name => "cVeg",
        :long_name => "vegetation_carbon_storage_content",
        :units => "gC/m2",
        :land_field => "pools",
        :description => "carbon content of cVeg pool(s)"
    ),
    :pools__cVegLeaf => orD(
        :standard_name => "cVegLeaf",
        :long_name => "leaf_carbon_storage_content",
        :units => "gC/m2",
        :land_field => "pools",
        :description => "carbon content of cVegLeaf pool(s)"
    ),
    :pools__cVegReserve => orD(
        :standard_name => "cVegReserve",
        :long_name => "reserve_carbon_storage_content",
        :units => "gC/m2",
        :land_field => "pools",
        :description => "carbon content of cVegReserve pool(s) that does not respire"
    ),
    :pools__cVegRoot => orD(
        :standard_name => "cVegRoot",
        :long_name => "root_carbon_storage_content",
        :units => "gC/m2",
        :land_field => "pools",
        :description => "carbon content of cVegRoot pool(s)"
    ),
    :pools__cVegWood => orD(
        :standard_name => "cVegWood",
        :long_name => "wood_carbon_storage_content",
        :units => "gC/m2",
        :land_field => "pools",
        :description => "carbon content of cVegWood pool(s)"
    ),
    :pools__ΔcEco => orD(
        :standard_name => "ΔcEco",
        :long_name => "delta_change_cEco",
        :units => "mm",
        :land_field => "pools",
        :description => "change in water storage in cEco pool(s)"
    ),
    :pools__ΔgroundW => orD(
        :standard_name => "ΔgroundW",
        :long_name => "delta_change_groundW",
        :units => "mm",
        :land_field => "pools",
        :description => "change in water storage in groundW pool(s)"
    ),
    :pools__ΔsnowW => orD(
        :standard_name => "ΔsnowW",
        :long_name => "delta_change_snowW",
        :units => "mm",
        :land_field => "pools",
        :description => "change in water storage in snowW pool(s)"
    ),
    :pools__ΔsoilW => orD(
        :standard_name => "ΔsoilW",
        :long_name => "delta_change_soilW",
        :units => "mm",
        :land_field => "pools",
        :description => "change in water storage in soilW pool(s)"
    ),
    :pools__ΔsurfaceW => orD(
        :standard_name => "ΔsurfaceW",
        :long_name => "delta_change_surfaceW",
        :units => "mm",
        :land_field => "pools",
        :description => "change in water storage in surfaceW pool(s)"
    ),
    :pools__ΔTWS => orD(
        :standard_name => "ΔTWS",
        :long_name => "delta_change_TWS",
        :units => "mm",
        :land_field => "pools",
        :description => "change in water storage in TWS pool(s)"
    ),
    :pools__groundW => orD(
        :standard_name => "groundW",
        :long_name => "groundwater_storage",
        :units => "mm",
        :land_field => "pools",
        :description => "water storage in groundW pool(s)"
    ),
    :pools__snowW => orD(
        :standard_name => "snowW",
        :long_name => "snow_water_equivalent",
        :units => "mm",
        :land_field => "pools",
        :description => "water storage in snowW pool(s)"
    ),
    :pools__soilW => orD(
        :standard_name => "soilW",
        :long_name => "soil_moisture_storage",
        :units => "mm",
        :land_field => "pools",
        :description => "water storage in soilW pool(s)"
    ),
    :pools__surfaceW => orD(
        :standard_name => "surfaceW",
        :long_name => "surface_water_storage",
        :units => "mm",
        :land_field => "pools",
        :description => "water storage in surfaceW pool(s)"
    ),
    :pools__TWS => orD(
        :standard_name => "TWS",
        :long_name => "terrestrial_water_storage",
        :units => "mm",
        :land_field => "pools",
        :description => "terrestrial water storage including all water pools"
    ),
    :pools__zeroΔTWS => orD(
       :standard_name => "zeroΔTWS",
       :long_name => "zero_with_size_",
       :units => "mm",
       :land_field => "pools",
       :description => "helper variable to reset ΔTWS to zero in every time step",
    ),
    :properties__cumulative_soil_depths => orD(
        :standard_name => "cumulative_soil_depths",
        :long_name => "cumulative_soil_depth",
        :units => "mm",
        :land_field => "properties",
        :description => "the depth to the bottom of each soil layer"
    ),
    :properties__k_fc => orD(
        :standard_name => "k_fc",
        :long_name => "k_field_capacity",
        :units => "mm/time",
        :land_field => "properties",
        :description => "hydraulic conductivity of soil at field capacity per layer"
    ),
    :properties__k_sat => orD(
        :standard_name => "k_sat",
        :long_name => "k_saturated",
        :units => "mm/time",
        :land_field => "properties",
        :description => "hydraulic conductivity of soil at saturation per layer"
    ),
    :properties__k_wp => orD(
        :standard_name => "k_wp",
        :long_name => "k_wilting_point",
        :units => "mm/time",
        :land_field => "properties",
        :description => "hydraulic conductivity of soil at wilting point per layer"
    ),
    :properties__lit_C_to_N => orD(
        :standard_name => "lit_C_to_N",
        :long_name => "litter_carbon_to_nitrogen_ratio",
        :units => "gC/gN",
        :land_field => "properties",
        :description => "carbon-to-nitrogen ratio of litter"
    ),
    :properties__lit_frac_C_lignin => orD(
        :standard_name => "lit_frac_C_lignin",
        :long_name => "litter_carbon_fraction_of_lignin",
        :units => "fraction",
        :land_field => "properties",
        :description => "carbon fraction of lignin"
    ),
    :properties__lit_frac_lignin => orD(
        :standard_name => "lit_frac_lignin",
        :long_name => "litter_lignin_fraction",
        :units => "fraction",
        :land_field => "properties",
        :description => "fraction of litter that is lignin"
    ),
    :properties__lit_frac_lignin_struct => orD(
        :standard_name => "lit_frac_lignin_struct",
        :long_name => "litter_structural_lignin_fraction",
        :units => "fraction",
        :land_field => "properties",
        :description => "lignin as a fraction of structural litter carbon, which controls how structural litter decomposition is split between the slow soil pool and the microbial pools"
    ),
    :properties__lit_frac_lignin_wood => orD(
        :standard_name => "lit_frac_lignin_wood",
        :long_name => "woody_litter_lignin_fraction",
        :units => "fraction",
        :land_field => "properties",
        :description => "lignin fraction of woody litter, which controls the partitioning of woody and coarse-root litter decomposition"
    ),
    :properties__lit_frac_metabolic => orD(
        :standard_name => "lit_frac_metabolic",
        :long_name => "metabolic_litter_fraction",
        :units => "fraction",
        :land_field => "properties",
        :description => "fraction of leaf and fine-root litterfall routed to the metabolic litter pools; the complement goes to the structural pools"
    ),
    :properties__lit_k_f_lignin => orD(
        :standard_name => "lit_k_f_lignin",
        :long_name => "k_lignin_effect",
        :units => "fraction",
        :land_field => "properties",
        :description => "multiplicative effect of lignin content on the decomposition rate of the structural litter pools; one means no effect"
    ),
    :properties__lit_nonsol_to_sol_lignin => orD(
        :standard_name => "lit_nonsol_to_sol_lignin",
        :long_name => "nonsoluble_to_soluble_lignin",
        :units => "fraction",
        :land_field => "properties",
        :description => "scalar converting nonsoluble to soluble lignin"
    ),
    :properties__ψ_fc => orD(
        :standard_name => "ψ_fc",
        :long_name => "ψ_field_capacity",
        :units => "m",
        :land_field => "properties",
        :description => "matric potential of soil at field capacity per layer"
    ),
    :properties__ψ_sat => orD(
        :standard_name => "ψ_sat",
        :long_name => "ψ_saturated",
        :units => "m",
        :land_field => "properties",
        :description => "matric potential of soil at saturation per layer"
    ),
    :properties__ψ_wp => orD(
        :standard_name => "ψ_wp",
        :long_name => "ψ_wilting_point",
        :units => "m",
        :land_field => "properties",
        :description => "matric potential of soil at wiliting point per layer"
    ),
    :properties__soil_α => orD(
        :standard_name => "soil_α",
        :long_name => "soil_α",
        :units => "number",
        :land_field => "properties",
        :description => "alpha parameter of soil per layer"
    ),
    :properties__soil_β => orD(
        :standard_name => "soil_β",
        :long_name => "soil_β",
        :units => "number",
        :land_field => "properties",
        :description => "beta parameter of soil per layer"
    ),
    :properties__soil_layer_thickness => orD(
        :standard_name => "soil_layer_thickness",
        :long_name => "soil_thickness_per_layer",
        :units => "mm",
        :land_field => "properties",
        :description => "thickness of each soil layer"
    ),
    :properties__sp_k_fc => orD(
        :standard_name => "sp_k_fc",
        :long_name => "soil_property_k_fc",
        :units => "mm/time",
        :land_field => "properties",
        :description => "calculated/input hydraulic conductivity of soil at field capacity per layer"
    ),
    :properties__sp_k_sat => orD(
        :standard_name => "sp_k_sat",
        :long_name => "soil_property_k_saturated",
        :units => "mm/time",
        :land_field => "properties",
        :description => "calculated/input hydraulic conductivity of soil at saturation per layer"
    ),
    :properties__sp_k_wp => orD(
        :standard_name => "sp_k_wp",
        :long_name => "soil_property_k_wilting_point",
        :units => "mm/time",
        :land_field => "properties",
        :description => "calculated/input hydraulic conductivity of soil at wilting point per layer"
    ),
    :properties__sp_α => orD(
        :standard_name => "sp_α",
        :long_name => "soil_property_α",
        :units => "number",
        :land_field => "properties",
        :description => "calculated/input alpha parameter of soil per layer"
    ),
    :properties__sp_β => orD(
        :standard_name => "sp_β",
        :long_name => "soil_property_β",
        :units => "number",
        :land_field => "properties",
        :description => "calculated/input beta parameter of soil per layer"
    ),
    :properties__sp_θ_fc => orD(
        :standard_name => "sp_θ_fc",
        :long_name => "soil_property_θ_field_capacity",
        :units => "m3/m3",
        :land_field => "properties",
        :description => "calculated/input moisture content of soil at field capacity per layer"
    ),
    :properties__sp_θ_sat => orD(
        :standard_name => "sp_θ_sat",
        :long_name => "soil_property_θ_saturated",
        :units => "m3/m3",
        :land_field => "properties",
        :description => "calculated/input moisture content of soil at saturation (porosity) per layer"
    ),
    :properties__sp_θ_wp => orD(
        :standard_name => "sp_θ_wp",
        :long_name => "soil_property_θ_wilting_point",
        :units => "m3/m3",
        :land_field => "properties",
        :description => "calculated/input moisture content of soil at wilting point per layer"
    ),
    :properties__sp_ψ_fc => orD(
        :standard_name => "sp_ψ_fc",
        :long_name => "soil_property_ψ_field_capacity",
        :units => "m",
        :land_field => "properties",
        :description => "calculated/input matric potential of soil at field capacity per layer"
    ),
    :properties__sp_ψ_sat => orD(
        :standard_name => "sp_ψ_sat",
        :long_name => "soil_property_ψ_saturated",
        :units => "m",
        :land_field => "properties",
        :description => "calculated/input matric potential of soil at saturation per layer"
    ),
    :properties__sp_ψ_wp => orD(
        :standard_name => "sp_ψ_wp",
        :long_name => "soil_property_ψ_wilting_point",
        :units => "m",
        :land_field => "properties",
        :description => "calculated/input matric potential of soil at wiliting point per layer"
    ),
    :properties__st_clay => orD(
        :standard_name => "st_clay",
        :long_name => "soil_texture_clay",
        :units => "fraction",
        :land_field => "properties",
        :description => "fraction of clay content in the soil"
    ),
    :properties__st_orgm => orD(
        :standard_name => "st_orgm",
        :long_name => "soil_texture_orgm",
        :units => "fraction",
        :land_field => "properties",
        :description => "fraction of organic matter content in the soil per layer"
    ),
    :properties__st_sand => orD(
        :standard_name => "st_sand",
        :long_name => "soil_texture_sand",
        :units => "fraction",
        :land_field => "properties",
        :description => "fraction of sand content in the soil per layer"
    ),
    :properties__st_silt => orD(
        :standard_name => "st_silt",
        :long_name => "soil_texture_silt",
        :units => "fraction",
        :land_field => "properties",
        :description => "fraction of silt content in the soil per layer"
    ),
    :properties__∑soil_depth => orD(
        :standard_name => "∑soil_depth",
        :long_name => "total_depth_of_soil_column",
        :units => "mm",
        :land_field => "properties",
        :description => "total depth of soil"
    ),
    :properties__∑w_awc => orD(
        :standard_name => "∑available_water_capacity",
        :long_name => "∑available_water_capacity",
        :units => "mm",
        :land_field => "properties",
        :description => "total amount of water available for vegetation/transpiration"
    ),
    :properties__∑w_fc => orD(
        :standard_name => "∑w_fc",
        :long_name => "∑w_field_capacity",
        :units => "mm",
        :land_field => "properties",
        :description => "total amount of water in the soil at field capacity"
    ),
    :properties__∑w_sat => orD(
        :standard_name => "∑w_sat",
        :long_name => "∑w_saturated",
        :units => "mm",
        :land_field => "properties",
        :description => "total amount of water in the soil at saturation"
    ),
    :properties__∑w_wp => orD(
        :standard_name => "∑w_wp",
        :long_name => "∑wilting_point",
        :units => "mm",
        :land_field => "properties",
        :description => "total amount of water in the soil at wiliting point"
    ),
    :properties__θ_fc => orD(
        :standard_name => "θ_fc",
        :long_name => "θ_field_capacity",
        :units => "m3/m3",
        :land_field => "properties",
        :description => "moisture content of soil at field capacity per layer"
    ),
    :properties__θ_sat => orD(
        :standard_name => "θ_sat",
        :long_name => "θ_saturated",
        :units => "m3/m3",
        :land_field => "properties",
        :description => "moisture content of soil at saturation (porosity) per layer"
    ),
    :properties__θ_wp => orD(
        :standard_name => "θ_wp",
        :long_name => "θ_wilting_point",
        :units => "m3/m3",
        :land_field => "properties",
        :description => "moisture content of soil at wilting point per layer"
    ),
    :properties__w_awc => orD(
        :standard_name => "w_awc",
        :long_name => "w_available_water_capacity",
        :units => "mm",
        :land_field => "properties",
        :description => "maximum amount of water available for vegetation/transpiration per soil layer (w_sat-_wp)"
    ),
    :properties__w_fc => orD(
        :standard_name => "w_fc",
        :long_name => "w_field_capacity",
        :units => "mm",
        :land_field => "properties",
        :description => "amount of water in the soil at field capacity per layer"
    ),
    :properties__w_sat => orD(
        :standard_name => "w_sat",
        :long_name => "w_saturated",
        :units => "mm",
        :land_field => "properties",
        :description => "amount of water in the soil at saturation per layer"
    ),
    :properties__w_wp => orD(
        :standard_name => " w_wp",
        :long_name => "wilting_point",
        :units => "mm",
        :land_field => "properties",
        :description => "amount of water in the soil at wiliting point per layer"
    ),
    :rootWaterEfficiency__root_over => orD(
        :standard_name => "root_over",
        :long_name => "is_root_over",
        :units => "boolean",
        :land_field => "rootWaterEfficiency",
        :description => "a boolean indicating if the root is allowed to exract water from a given layer depending on maximum rooting depth"
    ),
    :states__ambient_CO2 => orD(
        :standard_name => "ambient_CO2",
        :long_name => "ambient_CO2_concentration",
        :units => "ppm",
        :land_field => "states",
        :description => "ambient co2 concentration"
    ),
    :states__aboveground_biomass => orD(
        :standard_name => "aboveground_biomass",
        :long_name => "aboveground_woody_biomass",
        :units => "gC/m2",
        :land_field => "states",
        :description => "carbon content on the cVegWood component",
    ),
    :states__c_remain => orD(
        :standard_name => "c_remain",
        :long_name => "carbon_remain",
        :units => "gC/m2",
        :land_field => "states",
        :description => "amount of carbon to keep in the ecosystem vegetation pools in case of disturbances"
    ),
    :states__cEco_prev => orD(
        :standard_name => "cEco_prev",
        :long_name => "ecosystem_carbon_pool_previous_timestep",
        :units => "gC/m2",
        :land_field => "states",
        :description => "ecosystem carbon content of the previous time step"
    ),
    :states__fAPAR => orD(
        :standard_name => "fAPAR",
        :long_name => "fraction_absorbed_photosynthetic_radiation",
        :units => "fraction",
        :land_field => "states",
        :description => "fraction of absorbed photosynthetically active radiation"
    ),
    :states__frac_snow => orD(
        :standard_name => "frac_snow",
        :long_name => "fractional_snow_cover",
        :units => "fraction",
        :land_field => "states",
        :description => "fractional coverage of grid with snow"
    ),
    :states__frac_tree => orD(
        :standard_name => "frac_tree",
        :long_name => "fractional_tree_cover",
        :units => "fraction",
        :land_field => "states",
        :description => "fractional coverage of grid with trees"
    ),
    :states__frac_vegetation => orD(
        :standard_name => "frac_vegetation",
        :long_name => "fractional_vegetation_cover",
        :units => "fraction",
        :land_field => "states",
        :description => "fractional coverage of grid with vegetation",
     ),
    :states__LAI => orD(
        :standard_name => "LAI",
        :long_name => "leaf_area_index",
        :units => "m2/m2",
        :land_field => "states",
        :description => "leaf area index"
    ),
    :states__PAW => orD(
        :standard_name => "PAW",
        :long_name => "plant_available_water",
        :units => "mm",
        :land_field => "states",
        :description => "amount of water available for transpiration per soil layer"
    ),
    :states__PFT => orD(
        :standard_name => "PFT",
        :long_name => "plant_functional_type",
        :units => "class",
        :land_field => "states",
        :description => "plant functional type class of the pixel, the single source of PFT for downstream processes"
    ),
    :states__Tair_prev => orD(
        :standard_name => "Tair_prev",
        :long_name => "Tair_previous_timestep",
        :units => "degree_C",
        :land_field => "states",
        :description => "air temperature in the previous time step"
    ),
    :states__total_water => orD(
        :standard_name => "total_water",
        :long_name => "total_water",
        :units => "mm",
        :land_field => "states",
        :description => "sum of water storage across all components"
    ),
    :states__total_water_prev => orD(
        :standard_name => "total_water_prev",
        :long_name => "total_water_previous",
        :units => "mm",
        :land_field => "states",
        :description => "sum of water storage across all components in previous time step"
    ),
    :states__WBP => orD(
        :standard_name => "WBP",
        :long_name => "water_balance_pool",
        :units => "mm",
        :land_field => "states",
        :description => "water balance tracker pool that starts with rain and ends up with 0 after allocating to soil percolation"
    )
)

"""
    checkDisplayVariableDict(var_full)


"""
function checkDisplayVariableDict(var_full; warn_msg=true)
    sind_var_names = keys(sindbad_tem_variables)
    if var_full in sind_var_names
        print("\nExisting catalog entry for $var_full from src/sindbadVariableCatalog.jl")
        displayVariableDict(var_full, sindbad_tem_variables[var_full])
    else
        new_d = defaultVariableInfo()
        new_d[:land_field] = split(string(var_full), "__")[1]
        new_d[:standard_name] = split(string(var_full), "__")[2]
        print("\n")
        if warn_msg
            line_index = findfirst(x -> String(var_full) < x, String.(sind_var_names))
            line_index = 21 + 7 * (line_index + 1)
            @info "$(var_full) does not exist in current sindbad catalog of variables. If it is a new or known variable, create an entry around src/sindbadVariableCatalog.jl:$(line_index) (alphabetically sorted location) with correct details filled to:"
        end
        displayVariableDict(var_full, new_d, false)
    end
    return nothing
end
"""
    checkMissingVarInfo(appr)

Check for missing variable information in the SINDBAD variable catalog for a given approach or model.

# Description
The `checkMissingVarInfo` function identifies variables used in a SINDBAD model or approach that are missing detailed information in the SINDBAD variable catalog. It inspects the inputs and outputs of the model's methods (`define`, `precompute`, `compute`, `update`) and checks if their metadata (e.g., `long_name`, `description`, `units`) is properly defined. If any information is missing, it provides a warning and displays the missing details.

# Arguments
- `appr`: The SINDBAD model or approach to check for missing variable information. This can be a specific approach or a model containing multiple approaches.
- if no argument is provided, it checks all approaches in the model.

# Returns
- `nothing`: The function does not return a value but prints warnings and missing variable details to the console.

# Behavior
- For a specific approach, it checks the inputs and outputs of the methods (`define`, `precompute`, `compute`, `update`) for missing variable information.
- For a model, it recursively checks all sub-approaches for missing variable information.
- If a variable is missing metadata, it displays the missing details and provides guidance for adding the variable to the SINDBAD variable catalog.

# Example
```julia
# Check for missing variable information in a specific approach
checkMissingVarInfo(ambientCO2_constant)

# Check for missing variable information in all approaches of a model
checkMissingVarInfo(cCycle)
```
"""
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


"""
    defaultVariableInfo(string_key = false)

a central helper function to get the default information of a sindbad variable as a dictionary
"""
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


"""
    displayVariableDict(dk, dv, exist = true)

a helper function to display the variable information in a dict form. This also allow for direct pasting when an unknown variable is queried

# Arguments:
- `dk`: a variable to use as the key
- `dv`: a variable to use as the key
- `exist`: whether the display is for an entry that exists or not
"""
function displayVariableDict(dk, dv, exist=true)
    print("\n\n")
    if exist
        print(":$(dk)\n")
    else
        print(":$(dk) => orD(\n")
    end
    foreach(dv) do dvv
        if exist
            println("   $dvv,")
        else
            println("       $dvv,")
        end
    end
    if !exist
        print("    ),\n")
    end
    return nothing
end


"""
    getFullVariableKey(var_field::String, var_sfield::String)

returns a symbol with `field__subfield` of land to be used as a key for an entry in variable catalog

# Arguments:
- `var_field`: land field of the variable
- `var_sfield`: land subfield of the variable
"""
function getFullVariableKey(var_field::String, var_sfield::String)
    return Symbol(var_field * "__" * var_sfield)
end

"""
    getUniqueVarNames(var_pairs)

return the list of variable names to be used to write model outputs to a field. - checks if the variable name is duplicated across different fields of SINDBAD land
- uses `field__variablename` in case of duplicates, else uses the actual model variable name
"""
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


"""
    getVariableCatalogFromLand(land)

a helper function to tentatively build a default variable catalog by parsing the fields and subfields of land. This is now a legacy function because it is not recommended way to generate a new catalog. The current catalog (sindbad_tem_variables) has finalized entries, and new entries to the catalog should to be added there directly
"""
function getVariableCatalogFromLand(land)
    default_varib = defaultVariableInfo()
    landprops = propertynames(land)
    varnames = []
    variCat = DataStructures.OrderedDict()
    for lf in landprops
        lsf = propertynames(getproperty(land, lf))
        for lsff in lsf
            keyname = Symbol(string(lf) * "__" * string(lsff))
            push!(varnames, keyname)
        end
    end
    varnames = sort(varnames)
    for var_sym in varnames
        varn = string(var_sym)
        field = split(varn, "__")[1]
        subfield = split(varn, "__")[2]
        var_dict = copy(default_varib)
        var_dict[:standard_name] = subfield
        var_dict[:long_name] = replace(subfield, "_" => " ")
        var_dict[:land_field] = field
        if field == "fluxes"
            if startswith(subfield, "c_")
                var_dict[:units] = "gC/m2/time"
                var_dict[:description] = "carbon flux as $(var_dict[:long_name])"
            else
                var_dict[:units] = "mm/time"
                var_dict[:description] = "water flux as $(var_dict[:long_name])"
            end
        elseif field == "pools"
            if startswith(subfield, "c")
                var_dict[:units] = "gC/m2"
                var_dict[:description] = "carbon content of $((subfield)) pool(s)"
            elseif endswith(subfield, "W")
                var_dict[:units] = "mm"
                var_dict[:description] = "water storage in $((subfield)) pool(s)"
            end
        elseif field == "states"
            if startswith(subfield, "Δ")
                poolname = replace(subfield, "Δ" => "")
                if startswith(poolname, " c")
                    var_dict[:units] = "gC/m2"
                    var_dict[:description] = "change in carbon content of $(poolname) pool(s)"
                else
                    var_dict[:units] = "mm"
                    var_dict[:description] = "change in water storage in $(poolname) pool(s)"
                end
            else
                var_dict[:units] = "-"
            end
        elseif startswith(subfield, "frac_")
            var_dict[:units] = "fraction"
        end
        if occursin("_k", subfield)
            if endswith(subfield, "_frac")
                var_dict[:units] = "fraction"
            else
                var_dict[:units] = "/time"
            end
        end
        if occursin("_f_", subfield)
            var_af = split(subfield, "_f_")[1]
            var_afft = split(subfield, "_f_")[2]
            var_dict[:description] = "effect of $(var_afft) on $(var_af). 1: no stress, 0: complete stress"
            var_dict[:units] = "-"
        end
        variCat[var_sym] = var_dict
    end
    return variCat
end

"""
    getVarField(var_pair)

Return the field name from a pair consisting of the field and subfield of SINDBAD land.

# Arguments
- `var_pair`: A pair of `(field, subfield)` symbols

# Returns
- The field name (first element of the pair)
"""
function getVarField(var_pair)
    return first(var_pair)
end

"""
    getVarFull(var_pair)

Return the variable full name used as the key in the catalog of `sindbad_tem_variables` from a pair consisting of the field and subfield of SINDBAD land. Convention is `field__subfield` of land.

# Arguments
- `var_pair`: A pair of `(field, subfield)` symbols

# Returns
- A `Symbol` in the form `field__subfield`
"""
function getVarFull(var_pair)
    return Symbol(String(first(var_pair)) * "__" * String(last(var_pair)))
end

"""
    getVarName(var_pair)

Return the model variable name from a pair consisting of the field and subfield of SINDBAD land.

# Arguments
- `var_pair`: A pair of `(field, subfield)` symbols

# Returns
- The variable name (second element of the pair)
"""
function getVarName(var_pair)
    return last(var_pair)
end

"""
    getVariableInfo(vari_b, t_step="day")
    getVariableInfo(vari_b::Symbol, t_step="day")

Retrieve detailed information about a SINDBAD variable from the variable catalog.

# Arguments
- `vari_b`: The variable name (either as a Symbol or in the form of field__subfield)
- `t_step`: Time step of the variable (default: `"day"`)

# Returns
- A dictionary containing the following information about the variable:
  - `standard_name`: The standard name of the variable
  - `long_name`: A longer description of the variable
  - `units`: The units of the variable (with time step replaced if applicable)
  - `land_field`: The field in the SINDBAD model where the variable is used
  - `description`: A detailed description of the variable

# Notes
- If the variable is provided as a pair, it is converted to the full variable key using `getVarFull`
- Accesses `sindbad_tem_variables` catalog and `defaultVariableInfo` from `SindbadTEM.Variables` module
"""
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

"""
    whatIs(var_name::String)
    whatIs(var_field::String, var_sfield::String)
    whatIs(var_field::Symbol, var_sfield::Symbol)

A helper function to return the information of a SINDBAD variable

# Arguments:
- `var_name`: name of the variable
- `var_field`: field of the variable
- `var_sfield`: subfield of the variable

"""
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

end  # module Variables