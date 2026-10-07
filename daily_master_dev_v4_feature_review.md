# WISP development cube: feature requirement review

Review target: [Sindbad.jl / sindbad-wisp-dev](https://github.com/LandEcosystems/Sindbad.jl/tree/sindbad-wisp-dev).

Cube inspected on 2026-10-07:

```text
/Net/Groups/BGI/work_1/yuchen/SINDBAD_WISP_longcube/AUST_ent00_2014_2023/daily_master_dev_v4/daily_master_dev_v4.nc
```

This checklist lists every data variable in the cube: **33 model-input candidates and 37 auxiliary variables**. The nine coordinates are listed separately below. The stored role `model_input` identifies a candidate input; it does not automatically make the feature required.

## How to review

- **`Required = 1`**: retain this feature as an input required for the agreed model run.
- **`Required = 0`**: this feature is not required for that run.
- Please change **`0` to `1`** for any additional feature your WISP configuration requires. Correct an existing `1` to `0` if appropriate, and briefly update its review note. These flags record the team's decision; editing this file does not change the cube or model configuration.

**Initial baseline:** the branch's [WROASTED forcing configuration](https://github.com/LandEcosystems/Sindbad.jl/blob/9fe359f809c199f5ca24faf9fb65c89f0d9f87df/examples/setups/WROASTED/forcing.json) and [model structure](https://github.com/LandEcosystems/Sindbad.jl/blob/9fe359f809c199f5ca24faf9fb65c89f0d9f87df/examples/setups/WROASTED/model_structure.json), checked at commit `9fe359f809c199f5ca24faf9fb65c89f0d9f87df`. Initial `1` values identify cube fields corresponding to configured forcing inputs, including the two explicit name mappings below. Initial `0` values mean not required by this baseline, not unnecessary for every SINDBAD configuration. The intended WISP run may select different processes; reviewers should update the flags accordingly.

## Main scientific features (33)

| Cube feature | Required | Review note |
|---|:---:|---|
| `f_PAR` | 1 | Configured forcing input. |
| `f_VPD` | 1 | Configured forcing input. |
| `f_VPD_day` | 1 | Configured forcing input. |
| `f_airT` | 1 | Configured forcing input. |
| `f_airT_day` | 1 | Configured forcing input. |
| `f_ambient_CO2` | 1 | Configured forcing input. |
| `f_rain` | 1 | Configured forcing input. |
| `f_rg` | 1 | Configured forcing input. |
| `f_rg_pot` | 1 | Configured forcing input. |
| `f_rn` | 1 | Configured forcing input. |
| `f_frac_vegetation` | 1 | Configured forcing input. |
| `f_tree_frac` | 1 | Configured forcing input. |
| `fapar` | 0 | Baseline computes fAPAR internally; review if using observed fAPAR as forcing. |
| `fcover` | 0 | Not a configured baseline forcing input. |
| `forest_age` | 0 | Review if the WISP run requires forest age. |
| `lai` | 0 | Baseline computes LAI internally; review if using observed LAI as forcing. |
| `f_clay` | 1 | Configured forcing input; native soil layers require an agreed model-layer mapping. |
| `f_sand` | 1 | Configured forcing input; native soil layers require an agreed model-layer mapping. |
| `f_silt` | 1 | Configured forcing input; native soil layers require an agreed model-layer mapping. |
| `f_orgm_candidate` | 1 | Proposed source for required `f_orgm`; confirm candidate suitability and layer mapping. |
| `soil_depth_CLM` | 0 | Baseline uses `soilWBase_uniform`. Change to 1 if selecting `soilWBase_soilDepth`; map to `f_soil_depth` and convert m to mm. |
| `viirs_fire_binary` | 0 | Review for the WISP active-fire input; a detection flag is not burned-area fraction. |
| `viirs_frp_max` | 0 | Review if the WISP fire component requires daily maximum FRP. |
| `f_dist_intensity_assumed_zero` | 1 | Proposed source for required `f_dist_intensity`; this is an explicit zero-disturbance assumption. |
| `f_pft` | 1 | Configured forcing input. |
| `f_PAR_day_sum` | 0 | Review if daytime cumulative PAR is required. |
| `f_PAR_day_mean` | 0 | Review if daytime mean PAR intensity is required. |
| `f_rg_day_sum` | 0 | Review if daytime cumulative shortwave radiation is required. |
| `f_rg_day_mean` | 0 | Review if daytime mean shortwave intensity is required. |
| `f_rg_pot_day_sum` | 0 | Review if daytime cumulative potential radiation is required. |
| `f_rg_pot_day_mean` | 0 | Review if daytime mean potential radiation intensity is required. |
| `disturbance_year_2010` | 0 | Review for age initialization; year inferred from the 2010 age reference. |
| `disturbance_year_2020` | 0 | Review for age initialization; year inferred from the 2020 age reference. |

The two proposed name mappings above are review decisions, not mappings already installed in the repository. A `1` does not certify data quality or unit/dimension compatibility. In particular, [`soilWBase_soilDepth`](https://github.com/LandEcosystems/Sindbad.jl/blob/9fe359f809c199f5ca24faf9fb65c89f0d9f87df/SindbadTEM/src/Processes/soilWBase/soilWBase_soilDepth.jl) requires finite, positive depth in mm within the configured soil column; retaining `soil_depth_CLM` alone does not resolve its zero-depth cells.

## Auxiliary variables (37)

These are retained in the cube but are not forcing inputs in the baseline. Change a flag to `1` if the agreed run or its input preparation requires that variable; for example, a validity mask needed to select usable grid cells.

| Cube feature | Category | Required | Review note |
|---|---|:---:|---|
| `forest_age_member_median` | Ensemble/reference | 0 | |
| `forest_age_p10_reference` | Ensemble/reference | 0 | |
| `forest_age_p90_reference` | Ensemble/reference | 0 | |
| `forest_age_reference` | Ensemble/reference | 0 | |
| `hansen_tree_fraction_yearly_candidate` | Annual reference | 0 | |
| `hansen_tree_fraction_yearly_completed_candidate` | Annual reference | 0 | |
| `f_PAR_valid_hours` | QA | 0 | |
| `f_VPD_valid_hours` | QA | 0 | |
| `f_VPD_day_valid_hours` | QA | 0 | |
| `f_airT_valid_hours` | QA | 0 | |
| `f_airT_day_valid_hours` | QA | 0 | |
| `f_rain_valid_hours` | QA | 0 | |
| `f_rg_valid_hours` | QA | 0 | |
| `f_rg_pot_valid_hours` | QA | 0 | |
| `f_rn_valid_hours` | QA | 0 | |
| `fapar_valid_hours` | QA | 0 | |
| `fcover_valid_hours` | QA | 0 | |
| `lai_valid_hours` | QA | 0 | |
| `daylight_hours` | QA | 0 | |
| `daylight_mask_valid` | QA | 0 | |
| `forest_age_extrapolated` | QA | 0 | |
| `forest_age_source_count` | QA | 0 | |
| `forest_age_source_coverage` | QA | 0 | |
| `forest_age_valid_mask` | QA | 0 | |
| `forest_age_valid_member_count` | QA | 0 | |
| `forest_age_valid_source_count` | QA | 0 | |
| `soil_depth_valid_mask` | QA | 0 | |
| `soil_depth_zero_mask` | QA | 0 | |
| `soil_texture_sum` | QA | 0 | |
| `tree_day_estimated_flag` | QA | 0 | |
| `tree_year_estimated_flag` | QA | 0 | |
| `f_PAR_day_valid_hours` | QA | 0 | |
| `f_rg_day_valid_hours` | QA | 0 | |
| `f_rg_pot_day_valid_hours` | QA | 0 | |
| `disturbance_year_2010_valid_mask` | QA | 0 | |
| `disturbance_year_2020_valid_mask` | QA | 0 | |
| `time_bounds` | Time bounds | 0 | |

## Coordinates (9; metadata, not selectable scientific features)

`time`, `lat`, `lon`, `soil_depth`, `soil_depth_bounds_cm`, `age_member`, `age_reference_year`, `tree_year`, `tree_reference_year`.

Preserve the coordinate and layer-bound metadata needed by any retained variables; coordinates are not additional model features to concatenate.

## Required input absent from this cube

`f_burnt_area` is required by the baseline's [`cFireBurnedArea_forcing`](https://github.com/LandEcosystems/Sindbad.jl/blob/9fe359f809c199f5ca24faf9fb65c89f0d9f87df/SindbadTEM/src/Processes/cFireBurnedArea/cFireBurnedArea_forcing.jl), but is not present in this cube. It needs a separate source or derivation. `viirs_fire_binary` and `viirs_frp_max` are not equivalent replacements. The exact name `active_fire` is also absent; review `viirs_fire_binary` if that name is intended to mean a daily active-fire detection flag.
