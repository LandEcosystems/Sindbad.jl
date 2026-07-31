```@docs
SindbadTEM.Processes
```
## Processes (models + approaches)

### EVI

```@docs
EVI
```
:::details EVI approaches

:::tabs

== EVI_constant
```@docs
EVI_constant
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/EVI/EVI_constant.jl)

== EVI_forcing
```@docs
EVI_forcing
```

**Calculated using:**

```julia
Inputs: :forcing => :f_EVI
Outputs: :states => :EVI
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/EVI/EVI_forcing.jl)


:::


----

### LAI

```@docs
LAI
```
:::details LAI approaches

:::tabs

== LAI_cVegLeaf
```@docs
LAI_cVegLeaf
```

**Calculated using:**

```julia
Inputs: :pools => :cVegLeaf
Outputs: :states => :LAI
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/LAI/LAI_cVegLeaf.jl)

== LAI_constant
```@docs
LAI_constant
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/LAI/LAI_constant.jl)

== LAI_forcing
```@docs
LAI_forcing
```

**Calculated using:**

```julia
Inputs: :forcing => :f_LAI
Outputs: :states => :LAI
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/LAI/LAI_forcing.jl)


:::


----

### NDVI

```@docs
NDVI
```
:::details NDVI approaches

:::tabs

== NDVI_constant
```@docs
NDVI_constant
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/NDVI/NDVI_constant.jl)

== NDVI_forcing
```@docs
NDVI_forcing
```

**Calculated using:**

```julia
Inputs: :forcing => :f_NDVI
Outputs: :states => :NDVI
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/NDVI/NDVI_forcing.jl)


:::


----

### NDWI

```@docs
NDWI
```
:::details NDWI approaches

:::tabs

== NDWI_constant
```@docs
NDWI_constant
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/NDWI/NDWI_constant.jl)

== NDWI_forcing
```@docs
NDWI_forcing
```

**Calculated using:**

```julia
Inputs: :forcing => :f_NDWI
Outputs: :states => :NDWI
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/NDWI/NDWI_forcing.jl)


:::


----

### NIRv

```@docs
NIRv
```
:::details NIRv approaches

:::tabs

== NIRv_constant
```@docs
NIRv_constant
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/NIRv/NIRv_constant.jl)

== NIRv_forcing
```@docs
NIRv_forcing
```

**Calculated using:**

```julia
Inputs: :forcing => :f_NIRv
Outputs: :states => :NIRv
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/NIRv/NIRv_forcing.jl)


:::


----

### PET

```@docs
PET
```
:::details PET approaches

:::tabs

== PET_Lu2005
```@docs
PET_Lu2005
```

**Calculated using:**

```julia
Inputs: :forcing => :f_rn, :forcing => :f_airT, :states => :Tair_prev
Outputs: :fluxes => :PET, :states => :Tair_prev
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/PET/PET_Lu2005.jl)

== PET_PriestleyTaylor1972
```@docs
PET_PriestleyTaylor1972
```

**Calculated using:**

```julia
Inputs: :forcing => :f_rn, :forcing => :f_airT, :constants => :z_zero
Outputs: :fluxes => :PET
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/PET/PET_PriestleyTaylor1972.jl)

== PET_forcing
```@docs
PET_forcing
```

**Calculated using:**

```julia
Inputs: :forcing => :f_PET
Outputs: :fluxes => :PET
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/PET/PET_forcing.jl)


:::


----

### PFT

```@docs
PFT
```
:::details PFT approaches

:::tabs

== PFT_constant
```@docs
PFT_constant
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/PFT/PFT_constant.jl)


:::


----

### WUE

```@docs
WUE
```
:::details WUE approaches

:::tabs

== WUE_Medlyn2011
```@docs
WUE_Medlyn2011
```

**Calculated using:**

```julia
Inputs: :forcing => :f_psurf_day, :forcing => :f_VPD_day, :states => :ambient_CO2, :WUE => :umol_to_gC
Outputs: :states => :ci, :states => :ciNoCO2, :diagnostics => :WUENoCO2, :diagnostics => :WUE
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/WUE/WUE_Medlyn2011.jl)

== WUE_VPDDay
```@docs
WUE_VPDDay
```

**Calculated using:**

```julia
Inputs: :forcing => :f_VPD_day, :constants => :z_zero, :constants => :o_one
Outputs: :diagnostics => :WUE
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/WUE/WUE_VPDDay.jl)

== WUE_VPDDayCo2
```@docs
WUE_VPDDayCo2
```

**Calculated using:**

```julia
Inputs: :forcing => :f_VPD_day, :states => :ambient_CO2, :constants => :z_zero, :constants => :o_one
Outputs: :diagnostics => :WUENoCO2, :diagnostics => :WUE
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/WUE/WUE_VPDDayCo2.jl)

== WUE_constant
```@docs
WUE_constant
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/WUE/WUE_constant.jl)

== WUE_expVPDDayCo2
```@docs
WUE_expVPDDayCo2
```

**Calculated using:**

```julia
Inputs: :forcing => :f_VPD_day, :states => :ambient_CO2
Outputs: :diagnostics => :WUENoCO2, :diagnostics => :WUE
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/WUE/WUE_expVPDDayCo2.jl)


:::


----

### ambientCO2

```@docs
ambientCO2
```
:::details ambientCO2 approaches

:::tabs

== ambientCO2_constant
```@docs
ambientCO2_constant
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/ambientCO2/ambientCO2_constant.jl)

== ambientCO2_forcing
```@docs
ambientCO2_forcing
```

**Calculated using:**

```julia
Inputs: :forcing => :f_ambient_CO2
Outputs: :states => :ambient_CO2
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/ambientCO2/ambientCO2_forcing.jl)


:::


----

### autoRespiration

```@docs
autoRespiration
```
:::details autoRespiration approaches

:::tabs

== autoRespiration_Thornley2000A
```@docs
autoRespiration_Thornley2000A
```

**Calculated using:**

```julia
Inputs: :diagnostics => :k_respiration_maintain, :diagnostics => :k_respiration_maintain_su, :fluxes => :c_eco_efflux, :fluxes => :auto_respiration_growth, :fluxes => :auto_respiration_maintain, :pools => :cEco, :pools => :cVeg, :fluxes => :gpp, :diagnostics => :C_to_N_cVeg, :diagnostics => :c_allocation, :diagnostics => :auto_respiration_f_airT
Outputs: :diagnostics => :k_respiration_maintain, :diagnostics => :k_respiration_maintain_su, :fluxes => :auto_respiration_growth, :fluxes => :auto_respiration_maintain, :fluxes => :c_eco_efflux
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/autoRespiration/autoRespiration_Thornley2000A.jl)

== autoRespiration_Thornley2000B
```@docs
autoRespiration_Thornley2000B
```

**Calculated using:**

```julia
Inputs: :diagnostics => :k_respiration_maintain, :diagnostics => :k_respiration_maintain_su, :fluxes => :c_eco_efflux, :fluxes => :auto_respiration_growth, :fluxes => :auto_respiration_maintain, :pools => :cEco, :pools => :cVeg, :fluxes => :gpp, :diagnostics => :C_to_N_cVeg, :diagnostics => :auto_respiration_f_airT, :diagnostics => :c_allocation
Outputs: :diagnostics => :k_respiration_maintain, :diagnostics => :k_respiration_maintain_su, :fluxes => :auto_respiration_growth, :fluxes => :auto_respiration_maintain, :fluxes => :c_eco_efflux
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/autoRespiration/autoRespiration_Thornley2000B.jl)

== autoRespiration_Thornley2000C
```@docs
autoRespiration_Thornley2000C
```

**Calculated using:**

```julia
Inputs: :diagnostics => :k_respiration_maintain, :diagnostics => :k_respiration_maintain_su, :diagnostics => :Fd, :fluxes => :c_eco_efflux, :fluxes => :auto_respiration_growth, :fluxes => :auto_respiration_maintain, :pools => :cEco, :pools => :cVeg, :fluxes => :gpp, :diagnostics => :C_to_N_cVeg, :diagnostics => :auto_respiration_f_airT, :diagnostics => :c_allocation, :constants => :z_zero, :constants => :o_one
Outputs: :diagnostics => :k_respiration_maintain, :diagnostics => :k_respiration_maintain_su, :fluxes => :auto_respiration_growth, :fluxes => :auto_respiration_maintain, :fluxes => :c_eco_efflux
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/autoRespiration/autoRespiration_Thornley2000C.jl)

== autoRespiration_none
```@docs
autoRespiration_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/autoRespiration/autoRespiration_none.jl)


:::


----

### autoRespirationAirT

```@docs
autoRespirationAirT
```
:::details autoRespirationAirT approaches

:::tabs

== autoRespirationAirT_Q10
```@docs
autoRespirationAirT_Q10
```

**Calculated using:**

```julia
Inputs: :forcing => :f_airT
Outputs: :diagnostics => :auto_respiration_f_airT
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/autoRespirationAirT/autoRespirationAirT_Q10.jl)

== autoRespirationAirT_none
```@docs
autoRespirationAirT_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/autoRespirationAirT/autoRespirationAirT_none.jl)


:::


----

### cAllocation

```@docs
cAllocation
```
:::details cAllocation approaches

:::tabs

== cAllocation_Friedlingstein1999
```@docs
cAllocation_Friedlingstein1999
```

**Calculated using:**

```julia
Inputs: :states => :c_allocation, :cAllocation => :cVeg_names, :cAllocation => :cVeg_nzix, :cAllocation => :cVeg_zix, :cAllocation => :c_allocation_to_veg, :diagnostics => :c_allocation_f_W_N, :diagnostics => :c_allocation_f_LAI, :constants => :z_zero, :constants => :o_one
Outputs: :diagnostics => :c_allocation
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocation/cAllocation_Friedlingstein1999.jl)

== cAllocation_GSI
```@docs
cAllocation_GSI
```

**Calculated using:**

```julia
Inputs: :cAllocation => :cVeg_names, :cAllocation => :cVeg_zix, :cAllocation => :cVeg_nzix, :cAllocation => :c_allocation_to_veg, :diagnostics => :c_allocation, :diagnostics => :c_allocation_f_soilW, :diagnostics => :c_allocation_f_soilT, :constants => :t_two
Outputs: :diagnostics => :c_allocation
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocation/cAllocation_GSI.jl)

== cAllocation_fixed
```@docs
cAllocation_fixed
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocation/cAllocation_fixed.jl)

== cAllocation_none
```@docs
cAllocation_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocation/cAllocation_none.jl)


:::


----

### cAllocationLAI

```@docs
cAllocationLAI
```
:::details cAllocationLAI approaches

:::tabs

== cAllocationLAI_Friedlingstein1999
```@docs
cAllocationLAI_Friedlingstein1999
```

**Calculated using:**

```julia
Inputs: :states => :LAI
Outputs: :diagnostics => :c_allocation_f_LAI
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationLAI/cAllocationLAI_Friedlingstein1999.jl)

== cAllocationLAI_none
```@docs
cAllocationLAI_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationLAI/cAllocationLAI_none.jl)


:::


----

### cAllocationNutrients

```@docs
cAllocationNutrients
```
:::details cAllocationNutrients approaches

:::tabs

== cAllocationNutrients_Friedlingstein1999
```@docs
cAllocationNutrients_Friedlingstein1999
```

**Calculated using:**

```julia
Inputs: :states => :PAW, :properties => :∑w_awc, :diagnostics => :c_allocation_f_soilW, :diagnostics => :c_allocation_f_soilT, :fluxes => :PET, :constants => :z_zero, :constants => :o_one
Outputs: :cAllocationNutrients => :c_allocation_f_W_N
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationNutrients/cAllocationNutrients_Friedlingstein1999.jl)

== cAllocationNutrients_none
```@docs
cAllocationNutrients_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationNutrients/cAllocationNutrients_none.jl)


:::


----

### cAllocationRadiation

```@docs
cAllocationRadiation
```
:::details cAllocationRadiation approaches

:::tabs

== cAllocationRadiation_GSI
```@docs
cAllocationRadiation_GSI
```

**Calculated using:**

```julia
Inputs: :forcing => :f_PAR, :diagnostics => :c_allocation_f_cloud_prev, :constants => :z_zero, :constants => :o_one
Outputs: :diagnostics => :c_allocation_c_allocation_f_cloud, :diagnostics => :c_allocation_f_cloud_prev
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationRadiation/cAllocationRadiation_GSI.jl)

== cAllocationRadiation_RgPot
```@docs
cAllocationRadiation_RgPot
```

**Calculated using:**

```julia
Inputs: :forcing => :f_rg_pot, :cAllocationRadiation => :rg_pot_max
Outputs: :diagnostics => :c_allocation_f_cloud, :diagnostics => :rg_pot_max
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationRadiation/cAllocationRadiation_RgPot.jl)

== cAllocationRadiation_gpp
```@docs
cAllocationRadiation_gpp
```

**Calculated using:**

```julia
Inputs: :diagnostics => :gpp_f_cloud
Outputs: :diagnostics => :c_allocation_f_cloud
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationRadiation/cAllocationRadiation_gpp.jl)

== cAllocationRadiation_none
```@docs
cAllocationRadiation_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationRadiation/cAllocationRadiation_none.jl)


:::


----

### cAllocationSoilT

```@docs
cAllocationSoilT
```
:::details cAllocationSoilT approaches

:::tabs

== cAllocationSoilT_Friedlingstein1999
```@docs
cAllocationSoilT_Friedlingstein1999
```

**Calculated using:**

```julia
Inputs: :diagnostics => :c_allocation_f_soilT
Outputs: :diagnostics => :c_allocation_f_soilT
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationSoilT/cAllocationSoilT_Friedlingstein1999.jl)

== cAllocationSoilT_gpp
```@docs
cAllocationSoilT_gpp
```

**Calculated using:**

```julia
Inputs: :diagnostics => :gpp_f_airT
Outputs: :diagnostics => :c_allocation_f_soilT
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationSoilT/cAllocationSoilT_gpp.jl)

== cAllocationSoilT_gppGSI
```@docs
cAllocationSoilT_gppGSI
```

**Calculated using:**

```julia
Inputs: :diagnostics => :gpp_f_airT, :diagnostics => :c_allocation_f_soilT_prev
Outputs: :diagnostics => :c_allocation_f_soilT, :diagnostics => :c_allocation_f_soilT_prev
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationSoilT/cAllocationSoilT_gppGSI.jl)

== cAllocationSoilT_none
```@docs
cAllocationSoilT_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationSoilT/cAllocationSoilT_none.jl)


:::


----

### cAllocationSoilW

```@docs
cAllocationSoilW
```
:::details cAllocationSoilW approaches

:::tabs

== cAllocationSoilW_Friedlingstein1999
```@docs
cAllocationSoilW_Friedlingstein1999
```

**Calculated using:**

```julia
Inputs: :diagnostics => :c_eco_k_f_soilW
Outputs: :diagnostics => :c_allocation_f_soilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationSoilW/cAllocationSoilW_Friedlingstein1999.jl)

== cAllocationSoilW_gpp
```@docs
cAllocationSoilW_gpp
```

**Calculated using:**

```julia
Inputs: :diagnostics => :gpp_f_soilW
Outputs: :diagnostics => :c_allocation_f_soilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationSoilW/cAllocationSoilW_gpp.jl)

== cAllocationSoilW_gppGSI
```@docs
cAllocationSoilW_gppGSI
```

**Calculated using:**

```julia
Inputs: :diagnostics => :gpp_f_soilW, :diagnostics => :c_allocation_f_soilW_prev
Outputs: :diagnostics => :c_allocation_f_soilW, :diagnostics => :c_allocation_f_soilW_prev
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationSoilW/cAllocationSoilW_gppGSI.jl)

== cAllocationSoilW_none
```@docs
cAllocationSoilW_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationSoilW/cAllocationSoilW_none.jl)


:::


----

### cAllocationTreeFraction

```@docs
cAllocationTreeFraction
```
:::details cAllocationTreeFraction approaches

:::tabs

== cAllocationTreeFraction_Friedlingstein1999
```@docs
cAllocationTreeFraction_Friedlingstein1999
```

**Calculated using:**

```julia
Inputs: :states => :frac_tree, :diagnostics => :c_allocation, :cAllocationTreeFraction => :cVeg_names_for_c_allocation_frac_tree, :constants => :z_zero, :constants => :o_one
Outputs: :diagnostics => :c_allocation
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cAllocationTreeFraction/cAllocationTreeFraction_Friedlingstein1999.jl)


:::


----

### cBiomass

```@docs
cBiomass
```
:::details cBiomass approaches

:::tabs

== cBiomass_simple
```@docs
cBiomass_simple
```

**Calculated using:**

```julia
Inputs: :pools => :cVegWood, :pools => :cVegLeaf
Outputs: :states => :aboveground_biomass
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cBiomass/cBiomass_simple.jl)

== cBiomass_treeGrass
```@docs
cBiomass_treeGrass
```

**Calculated using:**

```julia
Inputs: :pools => :cVegWood, :pools => :cVegLeaf, :states => :frac_tree
Outputs: :states => :aboveground_biomass
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cBiomass/cBiomass_treeGrass.jl)

== cBiomass_treeGrass_cVegReserveScaling
```@docs
cBiomass_treeGrass_cVegReserveScaling
```

**Calculated using:**

```julia
Inputs: :pools => :cVegWood, :pools => :cVegLeaf, :pools => :cVegReserve, :pools => :cVegRoot, :states => :frac_tree
Outputs: :states => :aboveground_biomass
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cBiomass/cBiomass_treeGrass_cVegReserveScaling.jl)


:::


----

### cCycle

```@docs
cCycle
```
:::details cCycle approaches

:::tabs

== cCycle_CASA
```@docs
cCycle_CASA
```

**Calculated using:**

```julia
Inputs: :cCycle => :c_eco_efflux, :cCycle => :c_eco_influx, :cCycle => :c_eco_flow, :fluxes => :c_eco_efflux, :fluxes => :c_eco_flow, :fluxes => :c_eco_influx, :fluxes => :c_eco_out, :fluxes => :c_eco_npp, :pools => :cEco, :pools => :cVeg, :fluxes => :gpp, :diagnostics => :c_eco_k, :diagnostics => :c_allocation, :cFlow => :p_E_vec, :cFlow => :p_F_vec, :cFlow => :p_giver, :cFlow => :p_taker, :constants => :c_flow_order, :diagnostics => :c_eco_τ
Outputs: :fluxes => :nee, :fluxes => :c_eco_npp, :fluxes => :auto_respiration, :fluxes => :eco_respiration, :fluxes => :hetero_respiration, :states => :c_eco_efflux, :states => :c_eco_flow, :states => :c_eco_influx, :states => :c_eco_out, :states => :c_eco_npp
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cCycle/cCycle_CASA.jl)

== cCycle_GSI
```@docs
cCycle_GSI
```

**Calculated using:**

```julia
Inputs: :diagnostics => :c_allocation, :diagnostics => :c_eco_k, :diagnostics => :c_flow_A_vec, :fluxes => :c_eco_efflux, :fluxes => :c_eco_flow, :fluxes => :c_eco_influx, :fluxes => :c_eco_out, :fluxes => :c_eco_npp, :fluxes => :zero_c_eco_flow, :fluxes => :zero_c_eco_influx, :pools => :cEco, :pools => :cVeg, :pools => :ΔcEco, :states => :cEco_prev, :fluxes => :gpp, :constants => :c_flow_order, :constants => :c_giver, :constants => :c_taker, :models => :c_model
Outputs: :pools => :cEco, :fluxes => :nee, :fluxes => :npp, :fluxes => :auto_respiration, :fluxes => :eco_respiration, :fluxes => :hetero_respiration, :fluxes => :c_eco_efflux, :fluxes => :c_eco_flow, :fluxes => :c_eco_influx, :fluxes => :c_eco_out, :fluxes => :c_eco_npp, :states => :cEco_prev, :pools => :ΔcEco
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cCycle/cCycle_GSI.jl)

== cCycle_simple
```@docs
cCycle_simple
```

**Calculated using:**

```julia
Inputs: :cCycle => :zixVeg, :fluxes => :c_eco_efflux, :fluxes => :c_eco_flow, :fluxes => :c_eco_influx, :fluxes => :c_eco_out, :fluxes => :c_eco_npp, :fluxes => :zero_c_eco_flow, :fluxes => :zero_c_eco_influx, :states => :cEco_prev, :pools => :cEco, :diagnostics => :c_flow_A_vec, :diagnostics => :c_eco_k, :pools => :ΔcEco, :fluxes => :gpp, :constants => :c_giver, :constants => :c_taker, :constants => :c_flow_order, :constants => :z_zero, :constants => :o_one
Outputs: :pools => :cEco, :fluxes => :nee, :fluxes => :npp, :fluxes => :auto_respiration, :fluxes => :eco_respiration, :fluxes => :hetero_respiration, :fluxes => :c_eco_efflux, :fluxes => :c_eco_flow, :fluxes => :c_eco_influx, :fluxes => :c_eco_out, :fluxes => :c_eco_npp, :states => :cEco_prev, :pools => :ΔcEco
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cCycle/cCycle_simple.jl)


:::


----

### cCycleBase

```@docs
cCycleBase
```
:::details cCycleBase approaches

:::tabs

== cCycleBase_CASA
```@docs
cCycleBase_CASA
```

**Calculated using:**

```julia
Inputs: :diagnostics => :C_to_N_cVeg, :constants => :o_one
Outputs: :diagnostics => :c_eco_k_base
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cCycleBase/cCycleBase_CASA.jl)

== cCycleBase_GSI
```@docs
cCycleBase_GSI
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cCycleBase/cCycleBase_GSI.jl)

== cCycleBase_GSI_PlantForm
```@docs
cCycleBase_GSI_PlantForm
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cCycleBase/cCycleBase_GSI_PlantForm.jl)

== cCycleBase_GSI_PlantForm_LargeKReserve
```@docs
cCycleBase_GSI_PlantForm_LargeKReserve
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cCycleBase/cCycleBase_GSI_PlantForm_LargeKReserve.jl)

== cCycleBase_simple
```@docs
cCycleBase_simple
```

**Calculated using:**

```julia
Inputs: :diagnostics => :C_to_N_cVeg, :constants => :o_one
Outputs: :diagnostics => :C_to_N_cVeg, :diagnostics => :c_eco_k_base, :diagnostics => :c_flow_A_array
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cCycleBase/cCycleBase_simple.jl)


:::


----

### cCycleConsistency

```@docs
cCycleConsistency
```
:::details cCycleConsistency approaches

:::tabs

== cCycleConsistency_simple
```@docs
cCycleConsistency_simple
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cCycleConsistency/cCycleConsistency_simple.jl)


:::


----

### cCycleDisturbance

```@docs
cCycleDisturbance
```
:::details cCycleDisturbance approaches

:::tabs

== cCycleDisturbance_WROASTED
```@docs
cCycleDisturbance_WROASTED
```

**Calculated using:**

```julia
Inputs: :forcing => :f_dist_intensity, :cCycleDisturbance => :zix_veg_all, :cCycleDisturbance => :c_lose_to_zix_vec, :pools => :cEco, :constants => :c_giver, :constants => :c_taker, :states => :c_remain, :models => :c_model
Outputs: :pools => :cEco
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cCycleDisturbance/cCycleDisturbance_WROASTED.jl)

== cCycleDisturbance_WROASTEDMortality
```@docs
cCycleDisturbance_WROASTEDMortality
```

**Calculated using:**

```julia
Inputs: :diagnostics => :c_fVegDieOff, :diagnostics => :c_Veg_Mortality, :diagnostics => :c_Fire_Flux, :diagnostics => :c_fire_fba, :diagnostics => :c_Fire_cci, :diagnostics => :c_Fire_k, :pools => :cEco, :fluxes => :cFireTotal, :states => :c_remain, :constants => :c_giver, :constants => :c_taker, :constants => :z_zero, :constants => :o_one, :models => :c_model
Outputs: :pools => :cEco, :fluxes => :cFireTotal, :diagnostics => :c_Veg_Mortality, :diagnostics => :c_Fire_Flux
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cCycleDisturbance/cCycleDisturbance_WROASTEDMortality.jl)

== cCycleDisturbance_cFlow
```@docs
cCycleDisturbance_cFlow
```

**Calculated using:**

```julia
Inputs: :forcing => :f_dist_intensity, :cCycleDisturbance => :zix_veg_all, :cCycleDisturbance => :c_lose_to_zix_vec, :pools => :cEco, :constants => :c_giver, :constants => :c_taker, :models => :c_model, :states => :c_remain
Outputs: :pools => :cEco
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cCycleDisturbance/cCycleDisturbance_cFlow.jl)


:::


----

### cFireBurnedArea

```@docs
cFireBurnedArea
```
:::details cFireBurnedArea approaches

:::tabs

== cFireBurnedArea_forcing
```@docs
cFireBurnedArea_forcing
```

**Calculated using:**

```julia
Inputs: :forcing => :f_burnt_area
Outputs: :diagnostics => :c_fire_fba
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cFireBurnedArea/cFireBurnedArea_forcing.jl)

== cFireBurnedArea_none
```@docs
cFireBurnedArea_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cFireBurnedArea/cFireBurnedArea_none.jl)


:::


----

### cFireCombustionCompleteness

```@docs
cFireCombustionCompleteness
```
:::details cFireCombustionCompleteness approaches

:::tabs

== cFireCombustionCompleteness_none
```@docs
cFireCombustionCompleteness_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cFireCombustionCompleteness/cFireCombustionCompleteness_none.jl)

== cFireCombustionCompleteness_vanDerWerf2006
```@docs
cFireCombustionCompleteness_vanDerWerf2006
```

**Calculated using:**

```julia
Inputs: :diagnostics => :c_fire_ccMin, :diagnostics => :c_fire_ccMax, :diagnostics => :c_Fire_cci, :diagnostics => :c_Fire_cc_fW, :diagnostics => :gpp_f_soilW, :pools => :soilW, :properties => :∑w_sat, :constants => :z_zero, :constants => :o_one
Outputs: :diagnostics => :c_Fire_cci, :diagnostics => :c_Fire_cc_fW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cFireCombustionCompleteness/cFireCombustionCompleteness_vanDerWerf2006.jl)


:::


----

### cFireMortality

```@docs
cFireMortality
```
:::details cFireMortality approaches

:::tabs

== cFireMortality_none
```@docs
cFireMortality_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cFireMortality/cFireMortality_none.jl)

== cFireMortality_vanDerWerf2004
```@docs
cFireMortality_vanDerWerf2004
```

**Calculated using:**

```julia
Inputs: :diagnostics => :c_Fire_k, :states => :frac_tree, :constants => :z_zero, :constants => :o_one
Outputs: :diagnostics => :c_Fire_k
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cFireMortality/cFireMortality_vanDerWerf2004.jl)


:::


----

### cFlow

```@docs
cFlow
```
:::details cFlow approaches

:::tabs

== cFlow_CASA
```@docs
cFlow_CASA
```

**Calculated using:**

```julia
Inputs: :cFlowVegProperties => :p_E_vec, :cFlowVegProperties => :p_F_vec, :diagnostics => :p_E_vec, :diagnostics => :p_F_vec, :diagnostics => :c_flow_E_array, :constants => :z_zero, :constants => :o_one
Outputs: :constants => :c_flow_order, :cFlow => :c_flow_A_vec, :cFlow => :p_E_vec, :cFlow => :p_F_vec, :cFlow => :p_giver, :cFlow => :p_taker
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cFlow/cFlow_CASA.jl)

== cFlow_GSI
```@docs
cFlow_GSI
```

**Calculated using:**

```julia
Inputs: :cFlow => :c_flow_A_vec_ind, :diagnostics => :c_allocation_f_soilW, :diagnostics => :c_allocation_f_soilT, :diagnostics => :c_allocation_f_cloud, :diagnostics => :eco_stressor_prev, :diagnostics => :slope_eco_stressor_prev, :diagnostics => :c_eco_k, :diagnostics => :c_flow_A_vec
Outputs: :diagnostics => :leaf_to_reserve, :diagnostics => :leaf_to_reserve_frac, :diagnostics => :root_to_reserve, :diagnostics => :root_to_reserve_frac, :diagnostics => :reserve_to_leaf, :diagnostics => :reserve_to_leaf_frac, :diagnostics => :reserve_to_root, :diagnostics => :reserve_to_root_frac, :diagnostics => :eco_stressor, :diagnostics => :k_shedding_leaf, :diagnostics => :k_shedding_leaf_frac, :diagnostics => :k_shedding_root, :diagnostics => :k_shedding_root_frac, :diagnostics => :slope_eco_stressor, :diagnostics => :eco_stressor_prev, :diagnostics => :slope_eco_stressor_prev, :diagnostics => :c_eco_k, :diagnostics => :c_flow_A_vec
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cFlow/cFlow_GSI.jl)

== cFlow_none
```@docs
cFlow_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cFlow/cFlow_none.jl)

== cFlow_simple
```@docs
cFlow_simple
```

**Calculated using:**

```julia
Inputs: :diagnostics => :c_flow_A_array
Outputs: :constants => :c_flow_order, :cFlow => :c_flow_A_vec, :cFlow => :p_giver, :cFlow => :p_taker
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cFlow/cFlow_simple.jl)


:::


----

### cFlowSoilProperties

```@docs
cFlowSoilProperties
```
:::details cFlowSoilProperties approaches

:::tabs

== cFlowSoilProperties_CASA
```@docs
cFlowSoilProperties_CASA
```

**Calculated using:**

```julia
Inputs: :diagnostics => :p_E_vec, :properties => :st_clay, :properties => :st_silt
Outputs: :diagnostics => :p_E_vec, :diagnostics => :p_F_vec
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cFlowSoilProperties/cFlowSoilProperties_CASA.jl)

== cFlowSoilProperties_none
```@docs
cFlowSoilProperties_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cFlowSoilProperties/cFlowSoilProperties_none.jl)


:::


----

### cFlowVegProperties

```@docs
cFlowVegProperties
```
:::details cFlowVegProperties approaches

:::tabs

== cFlowVegProperties_CASA
```@docs
cFlowVegProperties_CASA
```

**Calculated using:**

```julia
Inputs: :cFlowVegProperties => :p_F_vec, :pools => :cEco
Outputs: :cFlowVegProperties => :p_E_vec, :cFlowVegProperties => :p_F_vec
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cFlowVegProperties/cFlowVegProperties_CASA.jl)

== cFlowVegProperties_none
```@docs
cFlowVegProperties_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cFlowVegProperties/cFlowVegProperties_none.jl)


:::


----

### cTau

```@docs
cTau
```
:::details cTau approaches

:::tabs

== cTau_mult
```@docs
cTau_mult
```

**Calculated using:**

```julia
Inputs: :diagnostics => :c_eco_k_f_veg_props, :diagnostics => :c_eco_k_f_soilW, :diagnostics => :c_eco_k_f_soilT, :diagnostics => :c_eco_k_f_soil_props, :diagnostics => :c_eco_k_f_LAI, :diagnostics => :c_eco_k_base, :diagnostics => :c_eco_k
Outputs: :diagnostics => :c_eco_k
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cTau/cTau_mult.jl)

== cTau_none
```@docs
cTau_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cTau/cTau_none.jl)


:::


----

### cTauLAI

```@docs
cTauLAI
```
:::details cTauLAI approaches

:::tabs

== cTauLAI_CASA
```@docs
cTauLAI_CASA
```

**Calculated using:**

```julia
Inputs: :diagnostics => :c_eco_k_f_LAI, :states => :LAI, :diagnostics => :c_eco_τ, :diagnostics => :c_eco_k
Outputs: :diagnostics => :p_LAI13, :diagnostics => :p_cVegLeafZix, :diagnostics => :p_cVegRootZix, :diagnostics => :c_eco_k_f_LAI
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cTauLAI/cTauLAI_CASA.jl)

== cTauLAI_none
```@docs
cTauLAI_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cTauLAI/cTauLAI_none.jl)


:::


----

### cTauSoilProperties

```@docs
cTauSoilProperties
```
:::details cTauSoilProperties approaches

:::tabs

== cTauSoilProperties_CASA
```@docs
cTauSoilProperties_CASA
```

**Calculated using:**

```julia
Inputs: :diagnostics => :c_eco_k_f_soil_props, :properties => :st_clay, :properties => :st_silt
Outputs: :diagnostics => :c_eco_k_f_soil_props
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cTauSoilProperties/cTauSoilProperties_CASA.jl)

== cTauSoilProperties_none
```@docs
cTauSoilProperties_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cTauSoilProperties/cTauSoilProperties_none.jl)


:::


----

### cTauSoilT

```@docs
cTauSoilT
```
:::details cTauSoilT approaches

:::tabs

== cTauSoilT_Q10
```@docs
cTauSoilT_Q10
```

**Calculated using:**

```julia
Inputs: :forcing => :f_airT
Outputs: :diagnostics => :c_eco_k_f_soilT
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cTauSoilT/cTauSoilT_Q10.jl)

== cTauSoilT_none
```@docs
cTauSoilT_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cTauSoilT/cTauSoilT_none.jl)


:::


----

### cTauSoilW

```@docs
cTauSoilW
```
:::details cTauSoilW approaches

:::tabs

== cTauSoilW_CASA
```@docs
cTauSoilW_CASA
```

**Calculated using:**

```julia
Inputs: :diagnostics => :c_eco_k_f_soilW, :fluxes => :rain, :pools => :soilW_prev, :diagnostics => :fsoilW_prev, :fluxes => :PET, :constants => :z_zero, :constants => :o_one
Outputs: :diagnostics => :fsoilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cTauSoilW/cTauSoilW_CASA.jl)

== cTauSoilW_GSI
```@docs
cTauSoilW_GSI
```

**Calculated using:**

```julia
Inputs: :diagnostics => :c_eco_k_f_soilW, :properties => :w_sat, :pools => :cEco, :pools => :cLit, :pools => :cSoil, :pools => :soilW
Outputs: :diagnostics => :c_eco_k_f_soilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cTauSoilW/cTauSoilW_GSI.jl)

== cTauSoilW_none
```@docs
cTauSoilW_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cTauSoilW/cTauSoilW_none.jl)


:::


----

### cTauVegProperties

```@docs
cTauVegProperties
```
:::details cTauVegProperties approaches

:::tabs

== cTauVegProperties_CASA
```@docs
cTauVegProperties_CASA
```

**Calculated using:**

```julia
Inputs: :properties => :PFT, :diagnostics => :c_eco_k_f_veg_props, :constants => :z_zero, :constants => :o_one
Outputs: :diagnostics => :c_eco_τ, :properties => :C2LIGNIN, :properties => :LIGEFF, :properties => :LIGNIN, :properties => :LITC2N, :properties => :MTF, :properties => :SCLIGNIN, :diagnostics => :c_eco_k_f_veg_props
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cTauVegProperties/cTauVegProperties_CASA.jl)

== cTauVegProperties_none
```@docs
cTauVegProperties_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cTauVegProperties/cTauVegProperties_none.jl)


:::


----

### cVegetationDieOff

```@docs
cVegetationDieOff
```
:::details cVegetationDieOff approaches

:::tabs

== cVegetationDieOff_forcing
```@docs
cVegetationDieOff_forcing
```

**Calculated using:**

```julia
Inputs: :forcing => :f_dist_intensity
Outputs: :diagnostics => :c_fVegDieOff
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/cVegetationDieOff/cVegetationDieOff_forcing.jl)


:::


----

### capillaryFlow

```@docs
capillaryFlow
```
:::details capillaryFlow approaches

:::tabs

== capillaryFlow_VanDijk2010
```@docs
capillaryFlow_VanDijk2010
```

**Calculated using:**

```julia
Inputs: :properties => :k_fc, :properties => :w_sat, :fluxes => :soil_capillary_flux, :pools => :soilW, :pools => :ΔsoilW, :constants => :z_zero, :constants => :o_one
Outputs: :fluxes => :soil_capillary_flux, :pools => :ΔsoilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/capillaryFlow/capillaryFlow_VanDijk2010.jl)


:::


----

### constants

```@docs
constants
```
:::details constants approaches

:::tabs

== constants_numbers
```@docs
constants_numbers
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/constants/constants_numbers.jl)


:::


----

### deriveVariables

```@docs
deriveVariables
```
:::details deriveVariables approaches

:::tabs

== deriveVariables_simple
```@docs
deriveVariables_simple
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/deriveVariables/deriveVariables_simple.jl)


:::


----

### drainage

```@docs
drainage
```
:::details drainage approaches

:::tabs

== drainage_dos
```@docs
drainage_dos
```

**Calculated using:**

```julia
Inputs: :fluxes => :drainage, :properties => :w_sat, :properties => :soil_β, :properties => :w_fc, :pools => :soilW, :pools => :ΔsoilW, :constants => :z_zero, :constants => :o_one
Outputs: :fluxes => :drainage, :pools => :ΔsoilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/drainage/drainage_dos.jl)

== drainage_kUnsat
```@docs
drainage_kUnsat
```

**Calculated using:**

```julia
Inputs: :fluxes => :drainage, :models => :unsat_k_model, :properties => :w_sat, :properties => :w_fc, :properties => :soil_β, :properties => :k_fc, :properties => :k_sat, :pools => :soilW, :pools => :ΔsoilW, :constants => :z_zero, :constants => :o_one
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/drainage/drainage_kUnsat.jl)

== drainage_wFC
```@docs
drainage_wFC
```

**Calculated using:**

```julia
Inputs: :fluxes => :drainage, :properties => :p_nsoilLayers, :properties => :w_fc, :pools => :soilW, :pools => :ΔsoilW, :constants => :z_zero
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/drainage/drainage_wFC.jl)


:::


----

### evaporation

```@docs
evaporation
```
:::details evaporation approaches

:::tabs

== evaporation_Snyder2000
```@docs
evaporation_Snyder2000
```

**Calculated using:**

```julia
Inputs: :states => :fAPAR, :pools => :soilW, :pools => :ΔsoilW, :fluxes => :PET, :fluxes => :sPET_prev, :constants => :z_zero, :constants => :o_one
Outputs: :fluxes => :sET, :fluxes => :sPET_prev, :fluxes => :evaporation, :pools => :ΔsoilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/evaporation/evaporation_Snyder2000.jl)

== evaporation_bareFraction
```@docs
evaporation_bareFraction
```

**Calculated using:**

```julia
Inputs: :states => :frac_vegetation, :pools => :ΔsoilW, :pools => :soilW, :fluxes => :PET, :constants => :z_zero, :constants => :o_one
Outputs: :fluxes => :PET_evaporation, :fluxes => :evaporation, :pools => :ΔsoilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/evaporation/evaporation_bareFraction.jl)

== evaporation_demandSupply
```@docs
evaporation_demandSupply
```

**Calculated using:**

```julia
Inputs: :pools => :soilW, :pools => :ΔsoilW, :fluxes => :PET, :constants => :z_zero
Outputs: :fluxes => :PET_evaporation, :fluxes => :evaporationSupply, :fluxes => :evaporation, :pools => :ΔsoilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/evaporation/evaporation_demandSupply.jl)

== evaporation_fAPAR
```@docs
evaporation_fAPAR
```

**Calculated using:**

```julia
Inputs: :states => :fAPAR, :pools => :soilW, :pools => :ΔsoilW, :fluxes => :PET, :constants => :z_zero, :constants => :o_one
Outputs: :fluxes => :PET_evaporation, :fluxes => :evaporation, :pools => :ΔsoilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/evaporation/evaporation_fAPAR.jl)

== evaporation_none
```@docs
evaporation_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/evaporation/evaporation_none.jl)

== evaporation_vegFraction
```@docs
evaporation_vegFraction
```

**Calculated using:**

```julia
Inputs: :states => :frac_vegetation, :pools => :soilW, :pools => :ΔsoilW, :fluxes => :PET, :constants => :z_zero, :constants => :o_one
Outputs: :fluxes => :PET_evaporation, :fluxes => :evaporation, :pools => :ΔsoilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/evaporation/evaporation_vegFraction.jl)


:::


----

### evapotranspiration

```@docs
evapotranspiration
```
:::details evapotranspiration approaches

:::tabs

== evapotranspiration_simple
```@docs
evapotranspiration_simple
```

**Calculated using:**

```julia
Inputs: :pools => :soilW, :pools => :ΔsoilW, :forcing => :f_rn
Outputs: :fluxes => :evapotranspiration, :pools => :ΔsoilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/evapotranspiration/evapotranspiration_simple.jl)

== evapotranspiration_sum
```@docs
evapotranspiration_sum
```

**Calculated using:**

```julia
Inputs: :fluxes => :evaporation, :fluxes => :interception, :fluxes => :sublimation, :fluxes => :transpiration
Outputs: :fluxes => :evapotranspiration
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/evapotranspiration/evapotranspiration_sum.jl)


:::


----

### fAPAR

```@docs
fAPAR
```
:::details fAPAR approaches

:::tabs

== fAPAR_EVI
```@docs
fAPAR_EVI
```

**Calculated using:**

```julia
Inputs: :states => :EVI
Outputs: :states => :fAPAR
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/fAPAR/fAPAR_EVI.jl)

== fAPAR_LAI
```@docs
fAPAR_LAI
```

**Calculated using:**

```julia
Inputs: :states => :LAI, :constants => :z_zero, :constants => :o_one
Outputs: :states => :fAPAR
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/fAPAR/fAPAR_LAI.jl)

== fAPAR_cVegLeaf
```@docs
fAPAR_cVegLeaf
```

**Calculated using:**

```julia
Inputs: :pools => :cVegLeaf
Outputs: :states => :fAPAR
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/fAPAR/fAPAR_cVegLeaf.jl)

== fAPAR_cVegLeafBareFrac
```@docs
fAPAR_cVegLeafBareFrac
```

**Calculated using:**

```julia
Inputs: :pools => :cVegLeaf, :states => :frac_vegetation
Outputs: Symbol("states # TODO: now use fAPAR_bare as the output for the cost function!") => :fAPAR_bare, Symbol("states # TODO: now use fAPAR_bare as the output for the cost function!") => :fAPAR
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/fAPAR/fAPAR_cVegLeafBareFrac.jl)

== fAPAR_constant
```@docs
fAPAR_constant
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/fAPAR/fAPAR_constant.jl)

== fAPAR_forcing
```@docs
fAPAR_forcing
```

**Calculated using:**

```julia
Inputs: :forcing => :f_fAPAR
Outputs: :states => :fAPAR
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/fAPAR/fAPAR_forcing.jl)

== fAPAR_vegFraction
```@docs
fAPAR_vegFraction
```

**Calculated using:**

```julia
Inputs: :states => :frac_vegetation
Outputs: :states => :fAPAR
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/fAPAR/fAPAR_vegFraction.jl)


:::


----

### getPools

```@docs
getPools
```
:::details getPools approaches

:::tabs

== getPools_simple
```@docs
getPools_simple
```

**Calculated using:**

```julia
Inputs: :fluxes => :rain, :states => :WBP
Outputs: :states => :WBP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/getPools/getPools_simple.jl)


:::


----

### gpp

```@docs
gpp
```
:::details gpp approaches

:::tabs

== gpp_coupled
```@docs
gpp_coupled
```

**Calculated using:**

```julia
Inputs: :diagnostics => :transpiration_supply, :diagnostics => :gpp_f_soilW, :diagnostics => :gpp_demand, :diagnostics => :WUE
Outputs: :fluxes => :gpp
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gpp/gpp_coupled.jl)

== gpp_min
```@docs
gpp_min
```

**Calculated using:**

```julia
Inputs: :diagnostics => :gpp_f_climate, :states => :fAPAR, :diagnostics => :gpp_potential, :diagnostics => :gpp_f_soilW
Outputs: :fluxes => :gpp, :gpp => :AllScGPP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gpp/gpp_min.jl)

== gpp_mult
```@docs
gpp_mult
```

**Calculated using:**

```julia
Inputs: :diagnostics => :gpp_f_climate, :states => :fAPAR, :diagnostics => :gpp_potential, :diagnostics => :gpp_f_soilW
Outputs: :fluxes => :gpp, :gpp => :AllScGPP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gpp/gpp_mult.jl)

== gpp_none
```@docs
gpp_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gpp/gpp_none.jl)

== gpp_transpirationWUE
```@docs
gpp_transpirationWUE
```

**Calculated using:**

```julia
Inputs: :fluxes => :transpiration, :diagnostics => :WUE
Outputs: :fluxes => :gpp
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gpp/gpp_transpirationWUE.jl)


:::


----

### gppAirT

```@docs
gppAirT
```
:::details gppAirT approaches

:::tabs

== gppAirT_CASA
```@docs
gppAirT_CASA
```

**Calculated using:**

```julia
Inputs: :forcing => :f_airT_day, :constants => :o_one
Outputs: :diagnostics => :gpp_f_airT
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppAirT/gppAirT_CASA.jl)

== gppAirT_GSI
```@docs
gppAirT_GSI
```

**Calculated using:**

```julia
Inputs: :forcing => :f_airT, :diagnostics => :gpp_f_airT_c, :diagnostics => :gpp_f_airT_h, :diagnostics => :f_smooth, :constants => :z_zero, :constants => :o_one
Outputs: :diagnostics => :gpp_f_airT, :diagnostics => :cScGPP, :diagnostics => :hScGPP, :diagnostics => :gpp_f_airT_c, :diagnostics => :gpp_f_airT_h
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppAirT/gppAirT_GSI.jl)

== gppAirT_MOD17
```@docs
gppAirT_MOD17
```

**Calculated using:**

```julia
Inputs: :forcing => :f_airT_day, :constants => :o_one
Outputs: :diagnostics => :gpp_f_airT
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppAirT/gppAirT_MOD17.jl)

== gppAirT_Maekelae2008
```@docs
gppAirT_Maekelae2008
```

**Calculated using:**

```julia
Inputs: :forcing => :f_airT_day, :constants => :o_one, :diagnostics => :X_prev
Outputs: :diagnostics => :gpp_f_airT, :diagnostics => :X_prev
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppAirT/gppAirT_Maekelae2008.jl)

== gppAirT_TEM
```@docs
gppAirT_TEM
```

**Calculated using:**

```julia
Inputs: :forcing => :f_airT_day, :constants => :z_zero, :constants => :o_one, :constants => :t_two
Outputs: :diagnostics => :gpp_f_airT
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppAirT/gppAirT_TEM.jl)

== gppAirT_Wang2014
```@docs
gppAirT_Wang2014
```

**Calculated using:**

```julia
Inputs: :forcing => :f_airT_day, :diagnostics => :z_zero, :diagnostics => :o_one
Outputs: :diagnostics => :gpp_f_airT
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppAirT/gppAirT_Wang2014.jl)

== gppAirT_none
```@docs
gppAirT_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppAirT/gppAirT_none.jl)


:::


----

### gppDemand

```@docs
gppDemand
```
:::details gppDemand approaches

:::tabs

== gppDemand_min
```@docs
gppDemand_min
```

**Calculated using:**

```julia
Inputs: :states => :fAPAR, :diagnostics => :gpp_f_cloud, :diagnostics => :gpp_potential, :diagnostics => :gpp_f_light, :diagnostics => :gpp_climate_stressors, :diagnostics => :gpp_f_airT
Outputs: :diagnostics => :gpp_f_climate, :diagnostics => :gpp_demand
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppDemand/gppDemand_min.jl)

== gppDemand_mult
```@docs
gppDemand_mult
```

**Calculated using:**

```julia
Inputs: :diagnostics => :gpp_f_cloud, :states => :fAPAR, :diagnostics => :gpp_potential, :diagnostics => :gpp_f_light, :diagnostics => :gpp_climate_stressors, :diagnostics => :gpp_f_airT, :diagnostics => :gpp_f_vpd
Outputs: :diagnostics => :gpp_climate_stressors, :diagnostics => :gpp_f_climate, :diagnostics => :gpp_demand
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppDemand/gppDemand_mult.jl)

== gppDemand_none
```@docs
gppDemand_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppDemand/gppDemand_none.jl)


:::


----

### gppDiffRadiation

```@docs
gppDiffRadiation
```
:::details gppDiffRadiation approaches

:::tabs

== gppDiffRadiation_GSI
```@docs
gppDiffRadiation_GSI
```

**Calculated using:**

```julia
Inputs: :forcing => :f_rg, :diagnostics => :gpp_f_cloud_prev, :diagnostics => :MJ_to_W, :constants => :z_zero, :constants => :o_one
Outputs: :diagnostics => :gpp_f_cloud, :diagnostics => :gpp_f_cloud_prev
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppDiffRadiation/gppDiffRadiation_GSI.jl)

== gppDiffRadiation_Turner2006
```@docs
gppDiffRadiation_Turner2006
```

**Calculated using:**

```julia
Inputs: :forcing => :f_rg, :forcing => :f_rg_pot, :diagnostics => :CI_min, :diagnostics => :CI_max, :constants => :z_zero
Outputs: :diagnostics => :gpp_f_cloud, :diagnostics => :CI_min, :diagnostics => :CI_max
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppDiffRadiation/gppDiffRadiation_Turner2006.jl)

== gppDiffRadiation_Wang2015
```@docs
gppDiffRadiation_Wang2015
```

**Calculated using:**

```julia
Inputs: :forcing => :f_rg, :forcing => :f_rg_pot, :gppDiffRadiation => :CI_min, :gppDiffRadiation => :CI_max, :constants => :z_zero
Outputs: :diagnostics => :gpp_f_cloud, :gppDiffRadiation => :CI_min, :gppDiffRadiation => :CI_max
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppDiffRadiation/gppDiffRadiation_Wang2015.jl)

== gppDiffRadiation_none
```@docs
gppDiffRadiation_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppDiffRadiation/gppDiffRadiation_none.jl)


:::


----

### gppDirRadiation

```@docs
gppDirRadiation
```
:::details gppDirRadiation approaches

:::tabs

== gppDirRadiation_Maekelae2008
```@docs
gppDirRadiation_Maekelae2008
```

**Calculated using:**

```julia
Inputs: :forcing => :f_PAR, :states => :fAPAR
Outputs: :diagnostics => :gpp_f_light
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppDirRadiation/gppDirRadiation_Maekelae2008.jl)

== gppDirRadiation_none
```@docs
gppDirRadiation_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppDirRadiation/gppDirRadiation_none.jl)


:::


----

### gppPotential

```@docs
gppPotential
```
:::details gppPotential approaches

:::tabs

== gppPotential_Monteith
```@docs
gppPotential_Monteith
```

**Calculated using:**

```julia
Inputs: :forcing => :f_PAR
Outputs: :diagnostics => :gpp_potential
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppPotential/gppPotential_Monteith.jl)


:::


----

### gppSoilW

```@docs
gppSoilW
```
:::details gppSoilW approaches

:::tabs

== gppSoilW_CASA
```@docs
gppSoilW_CASA
```

**Calculated using:**

```julia
Inputs: :forcing => :f_airT, :diagnostics => :gpp_f_soilW_prev, :states => :PAW, :fluxes => :PET, :constants => :z_zero, :constants => :o_one
Outputs: :diagnostics => :OmBweOPET, :diagnostics => :gpp_f_soilW, :diagnostics => :gpp_f_soilW_prev
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppSoilW/gppSoilW_CASA.jl)

== gppSoilW_GSI
```@docs
gppSoilW_GSI
```

**Calculated using:**

```julia
Inputs: :properties => :∑w_awc, :properties => :∑w_wp, :pools => :soilW, :diagnostics => :gpp_f_soilW_prev
Outputs: :diagnostics => :gpp_f_soilW, :diagnostics => :gpp_f_soilW_prev
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppSoilW/gppSoilW_GSI.jl)

== gppSoilW_Keenan2009
```@docs
gppSoilW_Keenan2009
```

**Calculated using:**

```julia
Inputs: :properties => :∑w_sat, :properties => :∑w_wp, :pools => :soilW
Outputs: :diagnostics => :gpp_f_soilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppSoilW/gppSoilW_Keenan2009.jl)

== gppSoilW_Stocker2020
```@docs
gppSoilW_Stocker2020
```

**Calculated using:**

```julia
Inputs: :properties => :∑w_fc, :properties => :∑w_wp, :pools => :soilW, :constants => :z_zero, :constants => :o_one, :constants => :t_two
Outputs: :diagnostics => :gpp_f_soilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppSoilW/gppSoilW_Stocker2020.jl)

== gppSoilW_none
```@docs
gppSoilW_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppSoilW/gppSoilW_none.jl)


:::


----

### gppVPD

```@docs
gppVPD
```
:::details gppVPD approaches

:::tabs

== gppVPD_MOD17
```@docs
gppVPD_MOD17
```

**Calculated using:**

```julia
Inputs: :forcing => :f_VPD_day, :constants => :z_zero, :constants => :o_one
Outputs: :diagnostics => :gpp_f_vpd
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppVPD/gppVPD_MOD17.jl)

== gppVPD_Maekelae2008
```@docs
gppVPD_Maekelae2008
```

**Calculated using:**

```julia
Inputs: :forcing => :f_VPD_day, :constants => :o_one
Outputs: :diagnostics => :gpp_f_vpd
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppVPD/gppVPD_Maekelae2008.jl)

== gppVPD_PRELES
```@docs
gppVPD_PRELES
```

**Calculated using:**

```julia
Inputs: :forcing => :f_VPD_day, :states => :ambient_CO2, :constants => :o_one
Outputs: :diagnostics => :gpp_f_vpd
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppVPD/gppVPD_PRELES.jl)

== gppVPD_expco2
```@docs
gppVPD_expco2
```

**Calculated using:**

```julia
Inputs: :forcing => :f_VPD_day, :states => :ambient_CO2, :constants => :z_zero, :constants => :o_one
Outputs: :diagnostics => :gpp_f_vpd
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppVPD/gppVPD_expco2.jl)

== gppVPD_none
```@docs
gppVPD_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/gppVPD/gppVPD_none.jl)


:::


----

### groundWRecharge

```@docs
groundWRecharge
```
:::details groundWRecharge approaches

:::tabs

== groundWRecharge_dos
```@docs
groundWRecharge_dos
```

**Calculated using:**

```julia
Inputs: :properties => :w_sat, :properties => :soil_β, :pools => :ΔsoilW, :pools => :soilW, :pools => :ΔgroundW, :pools => :groundW, :constants => :z_zero, :constants => :o_one
Outputs: :fluxes => :gw_recharge, :pools => :ΔsoilW, :pools => :ΔgroundW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/groundWRecharge/groundWRecharge_dos.jl)

== groundWRecharge_fraction
```@docs
groundWRecharge_fraction
```

**Calculated using:**

```julia
Inputs: :pools => :ΔsoilW, :pools => :soilW, :pools => :ΔgroundW, :pools => :groundW
Outputs: :fluxes => :gw_recharge, :pools => :ΔsoilW, :pools => :ΔgroundW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/groundWRecharge/groundWRecharge_fraction.jl)

== groundWRecharge_kUnsat
```@docs
groundWRecharge_kUnsat
```

**Calculated using:**

```julia
Inputs: :properties => :w_sat, :models => :unsat_k_model, :pools => :ΔsoilW, :pools => :soilW, :pools => :ΔgroundW, :pools => :groundW
Outputs: :fluxes => :gw_recharge, :pools => :ΔsoilW, :pools => :ΔgroundW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/groundWRecharge/groundWRecharge_kUnsat.jl)

== groundWRecharge_none
```@docs
groundWRecharge_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/groundWRecharge/groundWRecharge_none.jl)


:::


----

### groundWSoilWInteraction

```@docs
groundWSoilWInteraction
```
:::details groundWSoilWInteraction approaches

:::tabs

== groundWSoilWInteraction_VanDijk2010
```@docs
groundWSoilWInteraction_VanDijk2010
```

**Calculated using:**

```julia
Inputs: :properties => :k_fc, :properties => :k_sat, :properties => :w_sat, :pools => :ΔsoilW, :pools => :ΔgroundW, :pools => :groundW, :pools => :soilW, :models => :unsat_k_model, :constants => :z_zero, :constants => :o_one, :fluxes => :gw_recharge
Outputs: :fluxes => :gw_capillary_flux, :fluxes => :gw_recharge, :pools => :ΔsoilW, :pools => :ΔgroundW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/groundWSoilWInteraction/groundWSoilWInteraction_VanDijk2010.jl)

== groundWSoilWInteraction_gradient
```@docs
groundWSoilWInteraction_gradient
```

**Calculated using:**

```julia
Inputs: :properties => :w_sat, :pools => :ΔsoilW, :pools => :soilW, :pools => :ΔgroundW, :pools => :groundW, :constants => :n_groundW, :constants => :z_zero, :fluxes => :gw_recharge
Outputs: :fluxes => :gw_capillary_flux, :fluxes => :gw_recharge, :pools => :ΔsoilW, :pools => :ΔgroundW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/groundWSoilWInteraction/groundWSoilWInteraction_gradient.jl)

== groundWSoilWInteraction_gradientNeg
```@docs
groundWSoilWInteraction_gradientNeg
```

**Calculated using:**

```julia
Inputs: :properties => :w_sat, :pools => :ΔsoilW, :pools => :soilW, :pools => :ΔgroundW, :pools => :groundW, :constants => :n_groundW, :constants => :z_zero, :fluxes => :gw_recharge
Outputs: :fluxes => :gw_capillary_flux, :fluxes => :gw_recharge, :pools => :ΔsoilW, :pools => :ΔgroundW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/groundWSoilWInteraction/groundWSoilWInteraction_gradientNeg.jl)

== groundWSoilWInteraction_none
```@docs
groundWSoilWInteraction_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/groundWSoilWInteraction/groundWSoilWInteraction_none.jl)


:::


----

### groundWSurfaceWInteraction

```@docs
groundWSurfaceWInteraction
```
:::details groundWSurfaceWInteraction approaches

:::tabs

== groundWSurfaceWInteraction_fracGradient
```@docs
groundWSurfaceWInteraction_fracGradient
```

**Calculated using:**

```julia
Inputs: :pools => :ΔsurfaceW, :pools => :ΔgroundW, :pools => :groundW, :pools => :surfaceW, :constants => :n_surfaceW, :constants => :n_groundW
Outputs: :fluxes => :gw_to_suw_flux, :pools => :ΔsurfaceW, :pools => :ΔgroundW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/groundWSurfaceWInteraction/groundWSurfaceWInteraction_fracGradient.jl)

== groundWSurfaceWInteraction_fracGroundW
```@docs
groundWSurfaceWInteraction_fracGroundW
```

**Calculated using:**

```julia
Inputs: :pools => :groundW, :pools => :surfaceW, :pools => :ΔsurfaceW, :pools => :ΔgroundW, :constants => :n_surfaceW, :constants => :n_groundW
Outputs: :fluxes => :gw_to_suw_flux, :pools => :ΔsurfaceW, :pools => :ΔgroundW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/groundWSurfaceWInteraction/groundWSurfaceWInteraction_fracGroundW.jl)


:::


----

### interception

```@docs
interception
```
:::details interception approaches

:::tabs

== interception_Miralles2010
```@docs
interception_Miralles2010
```

**Calculated using:**

```julia
Inputs: :states => :WBP, :states => :fAPAR, :fluxes => :rain, :states => :rainInt
Outputs: :fluxes => :interception, :states => :WBP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/interception/interception_Miralles2010.jl)

== interception_fAPAR
```@docs
interception_fAPAR
```

**Calculated using:**

```julia
Inputs: :states => :WBP, :states => :fAPAR, :fluxes => :rain
Outputs: :fluxes => :interception, :states => :WBP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/interception/interception_fAPAR.jl)

== interception_none
```@docs
interception_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/interception/interception_none.jl)

== interception_vegFraction
```@docs
interception_vegFraction
```

**Calculated using:**

```julia
Inputs: :states => :WBP, :states => :frac_vegetation, :fluxes => :rain
Outputs: :fluxes => :interception, :states => :WBP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/interception/interception_vegFraction.jl)


:::


----

### percolation

```@docs
percolation
```
:::details percolation approaches

:::tabs

== percolation_WBP
```@docs
percolation_WBP
```

**Calculated using:**

```julia
Inputs: :pools => :ΔgroundW, :pools => :ΔsoilW, :pools => :soilW, :pools => :groundW, :states => :WBP, :constants => :o_one, :properties => :w_sat
Outputs: :fluxes => :percolation, :states => :WBP, :pools => :ΔgroundW, :pools => :ΔsoilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/percolation/percolation_WBP.jl)

== percolation_rain
```@docs
percolation_rain
```

**Calculated using:**

```julia
Inputs: :fluxes => :rain, :pools => :ΔsoilW
Outputs: :pools => :ΔsoilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/percolation/percolation_rain.jl)


:::


----

### plantForm

```@docs
plantForm
```
:::details plantForm approaches

:::tabs

== plantForm_PFT
```@docs
plantForm_PFT
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/plantForm/plantForm_PFT.jl)

== plantForm_fixed
```@docs
plantForm_fixed
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/plantForm/plantForm_fixed.jl)


:::


----

### rainIntensity

```@docs
rainIntensity
```
:::details rainIntensity approaches

:::tabs

== rainIntensity_forcing
```@docs
rainIntensity_forcing
```

**Calculated using:**

```julia
Inputs: :forcing => :f_rain_int
Outputs: :states => :rain_int
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/rainIntensity/rainIntensity_forcing.jl)

== rainIntensity_simple
```@docs
rainIntensity_simple
```

**Calculated using:**

```julia
Inputs: :forcing => :f_rain
Outputs: :states => :rain_int
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/rainIntensity/rainIntensity_simple.jl)


:::


----

### rainSnow

```@docs
rainSnow
```
:::details rainSnow approaches

:::tabs

== rainSnow_Tair
```@docs
rainSnow_Tair
```

**Calculated using:**

```julia
Inputs: :forcing => :f_rain, :forcing => :f_airT, :pools => :snowW, :pools => :ΔsnowW
Outputs: :fluxes => :precip, :fluxes => :rain, :fluxes => :snow, :pools => :ΔsnowW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/rainSnow/rainSnow_Tair.jl)

== rainSnow_forcing
```@docs
rainSnow_forcing
```

**Calculated using:**

```julia
Inputs: :forcing => :f_rain, :forcing => :f_snow, :pools => :snowW, :pools => :ΔsnowW
Outputs: :fluxes => :precip, :fluxes => :rain, :fluxes => :snow, :pools => :ΔsnowW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/rainSnow/rainSnow_forcing.jl)

== rainSnow_rain
```@docs
rainSnow_rain
```

**Calculated using:**

```julia
Inputs: :forcing => :f_rain
Outputs: :fluxes => :precip, :fluxes => :rain
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/rainSnow/rainSnow_rain.jl)


:::


----

### rootMaximumDepth

```@docs
rootMaximumDepth
```
:::details rootMaximumDepth approaches

:::tabs

== rootMaximumDepth_fracSoilD
```@docs
rootMaximumDepth_fracSoilD
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/rootMaximumDepth/rootMaximumDepth_fracSoilD.jl)


:::


----

### rootWaterEfficiency

```@docs
rootWaterEfficiency
```
:::details rootWaterEfficiency approaches

:::tabs

== rootWaterEfficiency_constant
```@docs
rootWaterEfficiency_constant
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/rootWaterEfficiency/rootWaterEfficiency_constant.jl)

== rootWaterEfficiency_expCvegRoot
```@docs
rootWaterEfficiency_expCvegRoot
```

**Calculated using:**

```julia
Inputs: :rootWaterEfficiency => :root_over, :diagnostics => :root_water_efficiency, :pools => :cVegRoot, :pools => :soilW
Outputs: :diagnostics => :root_water_efficiency
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/rootWaterEfficiency/rootWaterEfficiency_expCvegRoot.jl)

== rootWaterEfficiency_k2Layer
```@docs
rootWaterEfficiency_k2Layer
```

**Calculated using:**

```julia
Inputs: :diagnostics => :root_water_efficiency
Outputs: :diagnostics => :root_water_efficiency
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/rootWaterEfficiency/rootWaterEfficiency_k2Layer.jl)

== rootWaterEfficiency_k2fRD
```@docs
rootWaterEfficiency_k2fRD
```

**Calculated using:**

```julia
Inputs: :diagnostics => :root_water_efficiency, :states => :frac_vegetation
Outputs: :diagnostics => :root_water_efficiency
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/rootWaterEfficiency/rootWaterEfficiency_k2fRD.jl)

== rootWaterEfficiency_k2fvegFraction
```@docs
rootWaterEfficiency_k2fvegFraction
```

**Calculated using:**

```julia
Inputs: :diagnostics => :root_water_efficiency, :states => :frac_vegetation
Outputs: :diagnostics => :root_water_efficiency
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/rootWaterEfficiency/rootWaterEfficiency_k2fvegFraction.jl)


:::


----

### rootWaterUptake

```@docs
rootWaterUptake
```
:::details rootWaterUptake approaches

:::tabs

== rootWaterUptake_proportion
```@docs
rootWaterUptake_proportion
```

**Calculated using:**

```julia
Inputs: :states => :PAW, :pools => :soilW, :pools => :ΔsoilW, :fluxes => :transpiration, :fluxes => :root_water_uptake, :constants => :z_zero, :constants => :o_one
Outputs: :fluxes => :root_water_uptake, :pools => :ΔsoilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/rootWaterUptake/rootWaterUptake_proportion.jl)

== rootWaterUptake_topBottom
```@docs
rootWaterUptake_topBottom
```

**Calculated using:**

```julia
Inputs: :states => :PAW, :pools => :soilW, :states => :ΔsoilW, :states => :root_water_uptake, :fluxes => :transpiration, :constants => :z_zero
Outputs: :fluxes => :root_water_uptake, :pools => :ΔsoilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/rootWaterUptake/rootWaterUptake_topBottom.jl)


:::


----

### runoff

```@docs
runoff
```
:::details runoff approaches

:::tabs

== runoff_simple
```@docs
runoff_simple
```

**Calculated using:**

```julia
Inputs: :pools => :soilW, :pools => :ΔsoilW
Outputs: :fluxes => :runoff, :pools => :ΔsoilW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoff/runoff_simple.jl)

== runoff_sum
```@docs
runoff_sum
```

**Calculated using:**

```julia
Inputs: :fluxes => :base_runoff, :fluxes => :surface_runoff
Outputs: :fluxes => :runoff
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoff/runoff_sum.jl)


:::


----

### runoffBase

```@docs
runoffBase
```
:::details runoffBase approaches

:::tabs

== runoffBase_Zhang2008
```@docs
runoffBase_Zhang2008
```

**Calculated using:**

```julia
Inputs: :pools => :groundW, :pools => :ΔgroundW
Outputs: :fluxes => :base_runoff, :pools => :ΔgroundW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffBase/runoffBase_Zhang2008.jl)

== runoffBase_none
```@docs
runoffBase_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffBase/runoffBase_none.jl)


:::


----

### runoffInfiltrationExcess

```@docs
runoffInfiltrationExcess
```
:::details runoffInfiltrationExcess approaches

:::tabs

== runoffInfiltrationExcess_Jung
```@docs
runoffInfiltrationExcess_Jung
```

**Calculated using:**

```julia
Inputs: :states => :WBP, :states => :fAPAR, :properties => :k_sat, :fluxes => :rain, :states => :rainInt, :constants => :z_zero, :constants => :o_one
Outputs: :fluxes => :inf_excess_runoff, :states => :WBP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffInfiltrationExcess/runoffInfiltrationExcess_Jung.jl)

== runoffInfiltrationExcess_kUnsat
```@docs
runoffInfiltrationExcess_kUnsat
```

**Calculated using:**

```julia
Inputs: :states => :WBP, :models => :unsat_k_model, :constants => :z_zero, :constants => :o_one
Outputs: :fluxes => :inf_excess_runoff, :states => :WBP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffInfiltrationExcess/runoffInfiltrationExcess_kUnsat.jl)

== runoffInfiltrationExcess_none
```@docs
runoffInfiltrationExcess_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffInfiltrationExcess/runoffInfiltrationExcess_none.jl)


:::


----

### runoffInterflow

```@docs
runoffInterflow
```
:::details runoffInterflow approaches

:::tabs

== runoffInterflow_none
```@docs
runoffInterflow_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffInterflow/runoffInterflow_none.jl)

== runoffInterflow_residual
```@docs
runoffInterflow_residual
```

**Calculated using:**

```julia
Inputs: :states => :WBP
Outputs: :fluxes => :interflow_runoff, :states => :WBP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffInterflow/runoffInterflow_residual.jl)


:::


----

### runoffOverland

```@docs
runoffOverland
```
:::details runoffOverland approaches

:::tabs

== runoffOverland_Inf
```@docs
runoffOverland_Inf
```

**Calculated using:**

```julia
Inputs: :fluxes => :inf_excess_runoff
Outputs: :fluxes => :overland_runoff
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffOverland/runoffOverland_Inf.jl)

== runoffOverland_InfIntSat
```@docs
runoffOverland_InfIntSat
```

**Calculated using:**

```julia
Inputs: :fluxes => :inf_excess_runoff, :fluxes => :interflow_runoff, :fluxes => :sat_excess_runoff
Outputs: :fluxes => :overland_runoff
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffOverland/runoffOverland_InfIntSat.jl)

== runoffOverland_Sat
```@docs
runoffOverland_Sat
```

**Calculated using:**

```julia
Inputs: :fluxes => :sat_excess_runoff
Outputs: :fluxes => :overland_runoff
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffOverland/runoffOverland_Sat.jl)

== runoffOverland_none
```@docs
runoffOverland_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffOverland/runoffOverland_none.jl)


:::


----

### runoffSaturationExcess

```@docs
runoffSaturationExcess
```
:::details runoffSaturationExcess approaches

:::tabs

== runoffSaturationExcess_Bergstroem1992
```@docs
runoffSaturationExcess_Bergstroem1992
```

**Calculated using:**

```julia
Inputs: :states => :WBP, :properties => :w_sat, :pools => :soilW, :pools => :ΔsoilW
Outputs: :fluxes => :sat_excess_runoff, :states => :WBP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffSaturationExcess/runoffSaturationExcess_Bergstroem1992.jl)

== runoffSaturationExcess_Bergstroem1992MixedVegFraction
```@docs
runoffSaturationExcess_Bergstroem1992MixedVegFraction
```

**Calculated using:**

```julia
Inputs: :states => :WBP, :states => :frac_vegetation, :properties => :w_sat, :pools => :soilW, :pools => :ΔsoilW
Outputs: :fluxes => :sat_excess_runoff, :states => :WBP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffSaturationExcess/runoffSaturationExcess_Bergstroem1992MixedVegFraction.jl)

== runoffSaturationExcess_Bergstroem1992VegFraction
```@docs
runoffSaturationExcess_Bergstroem1992VegFraction
```

**Calculated using:**

```julia
Inputs: :states => :WBP, :states => :frac_vegetation, :properties => :w_sat, :pools => :soilW, :pools => :ΔsoilW
Outputs: :fluxes => :sat_excess_runoff, :runoffSaturationExcess => :β_veg, :states => :WBP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffSaturationExcess/runoffSaturationExcess_Bergstroem1992VegFraction.jl)

== runoffSaturationExcess_Bergstroem1992VegFractionFroSoil
```@docs
runoffSaturationExcess_Bergstroem1992VegFractionFroSoil
```

**Calculated using:**

```julia
Inputs: :forcing => :frac_frozen_soil, :states => :WBP, :states => :frac_vegetation, :properties => :w_sat, :pools => :soilW, :pools => :ΔsoilW, :constants => :z_zero, :constants => :o_one
Outputs: :fluxes => :sat_excess_runoff, :runoffSaturationExcess => :frac_frozen, :runoffSaturationExcess => :β_veg, :states => :WBP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffSaturationExcess/runoffSaturationExcess_Bergstroem1992VegFractionFroSoil.jl)

== runoffSaturationExcess_Bergstroem1992VegFractionPFT
```@docs
runoffSaturationExcess_Bergstroem1992VegFractionPFT
```

**Calculated using:**

```julia
Inputs: :forcing => :PFT, :states => :WBP, :states => :frac_vegetation, :runoffSaturationExcess => :β_veg, :properties => :w_sat, :pools => :soilW, :pools => :ΔsoilW
Outputs: :fluxes => :sat_excess_runoff, :states => :WBP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffSaturationExcess/runoffSaturationExcess_Bergstroem1992VegFractionPFT.jl)

== runoffSaturationExcess_Zhang2008
```@docs
runoffSaturationExcess_Zhang2008
```

**Calculated using:**

```julia
Inputs: :states => :WBP, :properties => :w_sat, :pools => :soilW, :fluxes => :PET, :pools => :ΔsoilW, :constants => :z_zero, :constants => :o_one
Outputs: :fluxes => :sat_excess_runoff, :states => :WBP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffSaturationExcess/runoffSaturationExcess_Zhang2008.jl)

== runoffSaturationExcess_none
```@docs
runoffSaturationExcess_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffSaturationExcess/runoffSaturationExcess_none.jl)

== runoffSaturationExcess_satFraction
```@docs
runoffSaturationExcess_satFraction
```

**Calculated using:**

```julia
Inputs: :states => :WBP, :states => :satFrac
Outputs: :fluxes => :sat_excess_runoff, :states => :WBP
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffSaturationExcess/runoffSaturationExcess_satFraction.jl)


:::


----

### runoffSurface

```@docs
runoffSurface
```
:::details runoffSurface approaches

:::tabs

== runoffSurface_Orth2013
```@docs
runoffSurface_Orth2013
```

**Calculated using:**

```julia
Inputs: :surface_runoff => :z, :surface_runoff => :Rdelay, :pools => :surfaceW, :fluxes => :overland_runoff
Outputs: :fluxes => :surface_runoff, :surface_runoff => :Rdelay
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffSurface/runoffSurface_Orth2013.jl)

== runoffSurface_Trautmann2018
```@docs
runoffSurface_Trautmann2018
```

**Calculated using:**

```julia
Inputs: :surface_runoff => :z, :surface_runoff => :Rdelay, :fluxes => :rain, :fluxes => :snow, :pools => :snowW, :pools => :snowW_prev, :pools => :soilW, :pools => :soilW_prev, :pools => :surfaceW, :fluxes => :evaporation, :fluxes => :overland_runoff, :fluxes => :sublimation
Outputs: :fluxes => :surface_runoff, :surface_runoff => :Rdelay, :surface_runoff => :dSurf
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffSurface/runoffSurface_Trautmann2018.jl)

== runoffSurface_all
```@docs
runoffSurface_all
```

**Calculated using:**

```julia
Inputs: :fluxes => :overland_runoff
Outputs: :fluxes => :surface_runoff
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffSurface/runoffSurface_all.jl)

== runoffSurface_directIndirect
```@docs
runoffSurface_directIndirect
```

**Calculated using:**

```julia
Inputs: :pools => :surfaceW, :pools => :ΔsurfaceW, :fluxes => :overland_runoff, :constants => :z_zero, :constants => :o_one
Outputs: :fluxes => :surface_runoff, :fluxes => :surface_runoff_direct, :fluxes => :surface_runoff_indirect, :fluxes => :suw_recharge, :pools => :ΔsurfaceW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffSurface/runoffSurface_directIndirect.jl)

== runoffSurface_directIndirectFroSoil
```@docs
runoffSurface_directIndirectFroSoil
```

**Calculated using:**

```julia
Inputs: :runoffSaturationExcess => :frac_frozen, :pools => :surfaceW, :pools => :ΔsurfaceW, :fluxes => :overland_runoff, :constants => :z_zero, :constants => :o_one
Outputs: :fluxes => :surface_runoff, :fluxes => :surface_runoff_direct, :fluxes => :surface_runoff_indirect, :fluxes => :suw_recharge, :pools => :ΔsurfaceW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffSurface/runoffSurface_directIndirectFroSoil.jl)

== runoffSurface_indirect
```@docs
runoffSurface_indirect
```

**Calculated using:**

```julia
Inputs: :pools => :surfaceW, :fluxes => :overland_runoff
Outputs: :fluxes => :surface_runoff, :fluxes => :suw_recharge, :pools => :ΔsurfaceW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffSurface/runoffSurface_indirect.jl)

== runoffSurface_none
```@docs
runoffSurface_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/runoffSurface/runoffSurface_none.jl)


:::


----

### saturatedFraction

```@docs
saturatedFraction
```
:::details saturatedFraction approaches

:::tabs

== saturatedFraction_none
```@docs
saturatedFraction_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/saturatedFraction/saturatedFraction_none.jl)


:::


----

### snowFraction

```@docs
snowFraction
```
:::details snowFraction approaches

:::tabs

== snowFraction_HTESSEL
```@docs
snowFraction_HTESSEL
```

**Calculated using:**

```julia
Inputs: :pools => :snowW, :pools => :ΔsnowW, :constants => :o_one
Outputs: :states => :frac_snow
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/snowFraction/snowFraction_HTESSEL.jl)

== snowFraction_binary
```@docs
snowFraction_binary
```

**Calculated using:**

```julia
Inputs: :pools => :snowW, :pools => :ΔsnowW, :constants => :z_zero, :constants => :o_one
Outputs: :states => :frac_snow
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/snowFraction/snowFraction_binary.jl)

== snowFraction_none
```@docs
snowFraction_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/snowFraction/snowFraction_none.jl)


:::


----

### snowMelt

```@docs
snowMelt
```
:::details snowMelt approaches

:::tabs

== snowMelt_Tair
```@docs
snowMelt_Tair
```

**Calculated using:**

```julia
Inputs: :forcing => :f_airT, :states => :WBP, :states => :frac_snow, :pools => :snowW, :pools => :ΔsnowW, :constants => :z_zero
Outputs: :fluxes => :snow_melt, :fluxes => :Tterm, :states => :WBP, :pools => :ΔsnowW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/snowMelt/snowMelt_Tair.jl)

== snowMelt_TairRn
```@docs
snowMelt_TairRn
```

**Calculated using:**

```julia
Inputs: :forcing => :f_rn, :forcing => :f_airT, :states => :WBP, :states => :frac_snow, :pools => :snowW, :pools => :ΔsnowW, :constants => :z_zero, :constants => :o_one
Outputs: :fluxes => :snow_melt, :fluxes => :potential_snow_melt, :states => :WBP, :pools => :ΔsnowW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/snowMelt/snowMelt_TairRn.jl)


:::


----

### soilProperties

```@docs
soilProperties
```
:::details soilProperties approaches

:::tabs

== soilProperties_Saxton1986
```@docs
soilProperties_Saxton1986
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/soilProperties/soilProperties_Saxton1986.jl)

== soilProperties_Saxton2006
```@docs
soilProperties_Saxton2006
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/soilProperties/soilProperties_Saxton2006.jl)


:::


----

### soilTexture

```@docs
soilTexture
```
:::details soilTexture approaches

:::tabs

== soilTexture_constant
```@docs
soilTexture_constant
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/soilTexture/soilTexture_constant.jl)

== soilTexture_forcing
```@docs
soilTexture_forcing
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/soilTexture/soilTexture_forcing.jl)


:::


----

### soilWBase

```@docs
soilWBase
```
:::details soilWBase approaches

:::tabs

== soilWBase_smax1Layer
```@docs
soilWBase_smax1Layer
```

**Calculated using:**

```julia
Inputs: :properties => :soil_layer_thickness, :properties => :w_sat, :properties => :w_fc, :properties => :w_wp
Outputs: :properties => :w_awc, :properties => :w_fc, :properties => :w_sat, :properties => :w_wp
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/soilWBase/soilWBase_smax1Layer.jl)

== soilWBase_smax2Layer
```@docs
soilWBase_smax2Layer
```

**Calculated using:**

```julia
Inputs: :properties => :soil_layer_thickness, :properties => :w_sat, :properties => :w_fc, :properties => :w_wp
Outputs: :properties => :w_awc, :properties => :w_fc, :properties => :w_sat, :properties => :w_wp, :properties => :soil_layer_thickness
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/soilWBase/soilWBase_smax2Layer.jl)

== soilWBase_smax2fRD4
```@docs
soilWBase_smax2fRD4
```

**Calculated using:**

```julia
Inputs: :forcing => :f_AWC, :forcing => :f_RDeff, :forcing => :f_RDmax, :forcing => :f_SWCmax, :properties => :soil_layer_thickness, :properties => :w_sat, :properties => :w_fc, :properties => :w_wp, :soilWBase => :rootwater_capacities
Outputs: :properties => :w_sat, :properties => :w_fc, :properties => :w_wp, :soilWBase => :rootwater_capacities
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/soilWBase/soilWBase_smax2fRD4.jl)

== soilWBase_uniform
```@docs
soilWBase_uniform
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/soilWBase/soilWBase_uniform.jl)


:::


----

### sublimation

```@docs
sublimation
```
:::details sublimation approaches

:::tabs

== sublimation_GLEAM
```@docs
sublimation_GLEAM
```

**Calculated using:**

```julia
Inputs: :forcing => :f_psurf_day, :forcing => :f_rn, :forcing => :f_airT_day, :states => :frac_snow, :pools => :snowW, :pools => :ΔsnowW, :constants => :z_zero, :constants => :o_one, :constants => :t_two
Outputs: :fluxes => :sublimation, :sublimation => :PTtermSub, :pools => :ΔsnowW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/sublimation/sublimation_GLEAM.jl)

== sublimation_none
```@docs
sublimation_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/sublimation/sublimation_none.jl)


:::


----

### transpiration

```@docs
transpiration
```
:::details transpiration approaches

:::tabs

== transpiration_coupled
```@docs
transpiration_coupled
```

**Calculated using:**

```julia
Inputs: :fluxes => :gpp, :diagnostics => :WUE
Outputs: :fluxes => :transpiration
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/transpiration/transpiration_coupled.jl)

== transpiration_demandSupply
```@docs
transpiration_demandSupply
```

**Calculated using:**

```julia
Inputs: :diagnostics => :transpiration_supply, :diagnostics => :transpiration_demand
Outputs: :fluxes => :transpiration
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/transpiration/transpiration_demandSupply.jl)

== transpiration_none
```@docs
transpiration_none
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/transpiration/transpiration_none.jl)


:::


----

### transpirationDemand

```@docs
transpirationDemand
```
:::details transpirationDemand approaches

:::tabs

== transpirationDemand_CASA
```@docs
transpirationDemand_CASA
```

**Calculated using:**

```julia
Inputs: :states => :PAW, :properties => :w_awc, :properties => :soil_α, :properties => :soil_β, :fluxes => :percolation, :fluxes => :PET
Outputs: :diagnostics => :transpiration_demand
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/transpirationDemand/transpirationDemand_CASA.jl)

== transpirationDemand_PET
```@docs
transpirationDemand_PET
```

**Calculated using:**

```julia
Inputs: :fluxes => :PET
Outputs: :diagnostics => :transpiration_demand
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/transpirationDemand/transpirationDemand_PET.jl)

== transpirationDemand_PETfAPAR
```@docs
transpirationDemand_PETfAPAR
```

**Calculated using:**

```julia
Inputs: :states => :fAPAR, :fluxes => :PET
Outputs: :diagnostics => :transpiration_demand
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/transpirationDemand/transpirationDemand_PETfAPAR.jl)

== transpirationDemand_PETvegFraction
```@docs
transpirationDemand_PETvegFraction
```

**Calculated using:**

```julia
Inputs: :states => :frac_vegetation, :fluxes => :PET
Outputs: :diagnostics => :transpiration_demand
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/transpirationDemand/transpirationDemand_PETvegFraction.jl)


:::


----

### transpirationSupply

```@docs
transpirationSupply
```
:::details transpirationSupply approaches

:::tabs

== transpirationSupply_CASA
```@docs
transpirationSupply_CASA
```

**Calculated using:**

```julia
Inputs: :states => :PAW
Outputs: :diagnostics => :transpiration_supply
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/transpirationSupply/transpirationSupply_CASA.jl)

== transpirationSupply_Federer1982
```@docs
transpirationSupply_Federer1982
```

**Calculated using:**

```julia
Inputs: :states => :PAW, :properties => :∑w_sat
Outputs: :diagnostics => :transpiration_supply
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/transpirationSupply/transpirationSupply_Federer1982.jl)

== transpirationSupply_wAWC
```@docs
transpirationSupply_wAWC
```

**Calculated using:**

```julia
Inputs: :states => :PAW
Outputs: :diagnostics => :transpiration_supply
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/transpirationSupply/transpirationSupply_wAWC.jl)

== transpirationSupply_wAWCvegFraction
```@docs
transpirationSupply_wAWCvegFraction
```

**Calculated using:**

```julia
Inputs: :states => :PAW, :states => :frac_vegetation
Outputs: :diagnostics => :transpiration_supply
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/transpirationSupply/transpirationSupply_wAWCvegFraction.jl)


:::


----

### treeFraction

```@docs
treeFraction
```
:::details treeFraction approaches

:::tabs

== treeFraction_constant
```@docs
treeFraction_constant
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/treeFraction/treeFraction_constant.jl)

== treeFraction_forcing
```@docs
treeFraction_forcing
```

**Calculated using:**

```julia
Inputs: :forcing => :f_tree_frac
Outputs: :states => :frac_tree
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/treeFraction/treeFraction_forcing.jl)


:::


----

### vegAvailableWater

```@docs
vegAvailableWater
```
:::details vegAvailableWater approaches

:::tabs

== vegAvailableWater_rootWaterEfficiency
```@docs
vegAvailableWater_rootWaterEfficiency
```

**Calculated using:**

```julia
Inputs: :properties => :w_wp, :diagnostics => :root_water_efficiency, :pools => :soilW, :pools => :ΔsoilW, :states => :PAW
Outputs: :states => :PAW
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/vegAvailableWater/vegAvailableWater_rootWaterEfficiency.jl)

== vegAvailableWater_sigmoid
```@docs
vegAvailableWater_sigmoid
```

**Calculated using:**

```julia
Inputs: :properties => :w_wp, :properties => :w_fc, :properties => :w_sat, :properties => :soil_β, :diagnostics => :root_water_efficiency, :pools => :soilW, :pools => :ΔsoilW, :states => :θ_dos, :states => :θ_fc_dos, :states => :PAW, :states => :soilW_stress, :states => :max_water, :constants => :z_zero, :constants => :o_one
Outputs: :states => :PAW, :states => :soilW_stress
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/vegAvailableWater/vegAvailableWater_sigmoid.jl)


:::


----

### vegFraction

```@docs
vegFraction
```
:::details vegFraction approaches

:::tabs

== vegFraction_constant
```@docs
vegFraction_constant
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/vegFraction/vegFraction_constant.jl)

== vegFraction_forcing
```@docs
vegFraction_forcing
```

**Calculated using:**

```julia
Inputs: :forcing => :f_frac_vegetation
Outputs: :states => :frac_vegetation
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/vegFraction/vegFraction_forcing.jl)

== vegFraction_scaledEVI
```@docs
vegFraction_scaledEVI
```

**Calculated using:**

```julia
Inputs: :states => :EVI
Outputs: :states => :frac_vegetation
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/vegFraction/vegFraction_scaledEVI.jl)

== vegFraction_scaledLAI
```@docs
vegFraction_scaledLAI
```

**Calculated using:**

```julia
Inputs: :states => :LAI
Outputs: :states => :frac_vegetation
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/vegFraction/vegFraction_scaledLAI.jl)

== vegFraction_scaledNDVI
```@docs
vegFraction_scaledNDVI
```

**Calculated using:**

```julia
Inputs: :states => :NDVI
Outputs: :states => :frac_vegetation
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/vegFraction/vegFraction_scaledNDVI.jl)

== vegFraction_scaledNIRv
```@docs
vegFraction_scaledNIRv
```

**Calculated using:**

```julia
Inputs: :states => :NIRv
Outputs: :states => :frac_vegetation
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/vegFraction/vegFraction_scaledNIRv.jl)

== vegFraction_scaledfAPAR
```@docs
vegFraction_scaledfAPAR
```

**Calculated using:**

```julia
Inputs: :states => :fAPAR
Outputs: :states => :frac_vegetation
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/vegFraction/vegFraction_scaledfAPAR.jl)


:::


----

### wCycle

```@docs
wCycle
```
:::details wCycle approaches

:::tabs

== wCycle_combined
```@docs
wCycle_combined
```

**Calculated using:**

```julia
Inputs: :pools => :TWS, :pools => :ΔTWS, :pools => :zeroΔTWS, :constants => :z_zero, :constants => :o_one
Outputs: :pools => :ΔTWS, :pools => :TWS, :states => :total_water, :states => :total_water_prev
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/wCycle/wCycle_combined.jl)

== wCycle_components
```@docs
wCycle_components
```

**Calculated using:**

```julia
Inputs: :pools => :groundW, :pools => :snowW, :pools => :soilW, :pools => :surfaceW, :pools => :TWS, :pools => :ΔgroundW, :pools => :ΔsnowW, :pools => :ΔsoilW, :pools => :ΔsurfaceW, :pools => :ΔTWS, :constants => :z_zero, :constants => :o_one, :models => :w_model
Outputs: :pools => :groundW, :pools => :snowW, :pools => :soilW, :pools => :surfaceW, :pools => :TWS, :pools => :ΔgroundW, :pools => :ΔsnowW, :pools => :ΔsoilW, :pools => :ΔsurfaceW, :states => :total_water, :states => :total_water_prev
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/wCycle/wCycle_components.jl)

== wCycle_simple
```@docs
wCycle_simple
```

**Calculated using:**

```julia
Inputs: :pools => :soilW, :pools => :ΔsoilW
Outputs: :pools => :soilW, :pools => :ΔsoilW, :states => :total_water, :states => :total_water_prev
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/wCycle/wCycle_simple.jl)


:::


----

### wCycleBase

```@docs
wCycleBase
```
:::details wCycleBase approaches

:::tabs

== wCycleBase_simple
```@docs
wCycleBase_simple
```
[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/wCycleBase/wCycleBase_simple.jl)


:::


----

### waterBalance

```@docs
waterBalance
```
:::details waterBalance approaches

:::tabs

== waterBalance_simple
```@docs
waterBalance_simple
```

**Calculated using:**

```julia
Inputs: :fluxes => :precip, :states => :total_water_prev, :states => :total_water, :states => :WBP, :fluxes => :evapotranspiration, :fluxes => :runoff
Outputs: :diagnostics => :water_balance
```

[View Source](https://github.com/LandEcosystems/Sindbad.jl/blob/main/SindbadTEM/src/Processes/waterBalance/waterBalance_simple.jl)


:::


----

## Methods

```@meta
DocTestSetup= quote
using SindbadTEM.Processes
end
```
```@autodocs
Modules = [SindbadTEM.Processes]
Filter = x -> x isa Function
Private = false
```
## Internal

```@meta
CollapsedDocStrings = false
DocTestSetup= quote
using SindbadTEM.Processes
end
```

```@autodocs
Modules = [SindbadTEM.Processes]
Public = false
```