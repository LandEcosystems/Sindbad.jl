export groundWSoilWInteraction_VanDijk2010

#! format: off
@bounds @describe @units @timescale @with_kw struct groundWSoilWInteraction_VanDijk2010{T1} <: groundWSoilWInteraction
    max_fraction::T1 = 0.5 | (0.001, 0.98) | "fraction of groundwater that can be lost to capillary flux" | "" | ""
end
#! format: on

function define(params::groundWSoilWInteraction_VanDijk2010, forcing, land, helpers)
    ## in case groundWReacharge is not selected in the model structure, instantiate the variable with zero
    @unpack_groundWSoilWInteraction_VanDijk2010 params
    gw_recharge = zero(max_fraction)
    ## pack land variables
    @pack_nt gw_recharge ⇒ land.fluxes
    return land
end

function compute(params::groundWSoilWInteraction_VanDijk2010, forcing, land, helpers)
    ## unpack parameters
    @unpack_groundWSoilWInteraction_VanDijk2010 params

    ## unpack land variables
    @unpack_nt begin
        (k_fc, k_sat, w_sat) ⇐ land.properties
        (ΔsoilW, ΔgroundW, groundW, soilW) ⇐ land.pools
        unsat_k_model ⇐ land.models
        (z_zero, o_one) ⇐ land.constants
        n_groundW = groundW ⇐ helpers.pools.n_layers
        gw_recharge ⇐ land.fluxes
    end

    # calculate recharge
    # degree of saturation & unsaturated hydraulic conductivity of the lowermost soil layer
    dosSoilend = clamp_zero_one((soilW[end] + ΔsoilW[end]) / w_sat[end])
    k_sat = k_sat[end] # assume GW is saturated
    k_fc = k_fc[end] # assume GW is saturated
    k_unsat = unsatK(land, helpers, lastindex(soilW), unsat_k_model)

    # get the capillary flux
    c_flux = sqrt(k_unsat * k_sat) * (o_one - dosSoilend)
    gw_capillary_flux = at_least_zero(min(c_flux, max_fraction * (sum(groundW) + sum(ΔgroundW)),
        soilW[end] + ΔsoilW[end]))
    # @debug gw_capillary_flux

    # adjust the delta storages
    ΔgroundW = addToEachElem(ΔgroundW, -gw_capillary_flux / n_groundW)
    @add_to_elem gw_capillary_flux ⇒ (ΔsoilW, lastindex(ΔsoilW), :soilW)

    # adjust the gw_recharge as net flux between soil and groundwater. positive from soil to gw
    gw_recharge = gw_recharge - gw_capillary_flux

    ## pack land variables
    @pack_nt begin
        (gw_capillary_flux, gw_recharge) ⇒ land.fluxes
        (ΔsoilW, ΔgroundW) ⇒ land.pools
    end
    return land
end

purpose(::Type{groundWSoilWInteraction_VanDijk2010}) = "Upward flow of water from groundwater to the lowermost soil layer using the Van Dijk (2010) method."

@doc """

$(getModelDocString(groundWSoilWInteraction_VanDijk2010))

---

# Extended help

*References*
 - AIJM Van Dijk, 2010, The Australian Water Resources Assessment System Technical Report 3. Landscape Model [version 0.5] Technical Description
 - http://www.clw.csiro.au/publications/waterforahealthycountry/2010/wfhc-aus-water-resources-assessment-system.pdf

*Versions*
 - 1.0 on 18.11.2019 [skoirala | @dr-ko]

*Created by*
 - skoirala | @dr-ko
"""
groundWSoilWInteraction_VanDijk2010
