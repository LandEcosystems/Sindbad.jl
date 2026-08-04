export groundWSoilWInteraction_gradientNeg

#! format: off
@bounds @describe @units @timescale @with_kw struct groundWSoilWInteraction_gradientNeg{T1,T2} <: groundWSoilWInteraction
    smax_scale::T1 = 0.5 | (0.0, 50.0) | "scale param to yield storage capacity of wGW" | "" | ""
    max_flux::T2 = 10.0 | (0.0, 20.0) | "maximum flux between wGW and wSoil" | "[mm d]" | ""
end
#! format: on

function define(params::groundWSoilWInteraction_gradientNeg, forcing, land, helpers)
    @unpack_nt z_zero ⇐ land.constants
    ## in case groundWReacharge is not selected in the model structure, instantiate the variable with zero
    gw_recharge = z_zero
    ## pack land variables
    @pack_nt gw_recharge ⇒ land.fluxes
    return land
end

function compute(params::groundWSoilWInteraction_gradientNeg, forcing, land, helpers)
    ## unpack parameters
    @unpack_groundWSoilWInteraction_gradientNeg params
    ## unpack land variables
    @unpack_nt begin
        w_sat ⇐ land.properties
        (ΔsoilW, soilW, ΔgroundW, groundW) ⇐ land.pools
        z_zero ⇐ land.constants
        gw_recharge ⇐ land.fluxes
        n_groundW = groundW ⇐ helpers.pools.n_layers
    end
    # maximum groundwater storage
    p_gwmax = w_sat[end] * smax_scale

    total_soilW = soilW[end] + ΔsoilW[end]
    total_groundW = totalS(groundW, ΔgroundW)

    # gradient between groundW[1] & soilW
    tmp_gradient = total_groundW / p_gwmax - total_soilW / w_sat[end] # the sign of the gradient gives direction of flow: positive = flux to soil; negative = flux to gw from soilW

    # scale gradient with pot flux rate to get pot flux
    pot_flux = tmp_gradient * max_flux # need to make sure that the flux does not overflow | underflow storages

    # adjust the pot flux to what is there
    tmp = min(pot_flux, w_sat[end] - total_soilW, total_groundW)
    tmp = max(tmp, -total_soilW, -total_groundW)

    # -> set all the positive values (from groundwater to soil) to zero
    gw_capillary_flux = at_most_zero(tmp)

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

purpose(::Type{groundWSoilWInteraction_gradientNeg}) = "Delayed/Buffer storage that does not give water to the soil when the soil is dry, but receives water from the soil when the soil is wet and the buffer is low."

@doc """

$(getModelDocString(groundWSoilWInteraction_gradientNeg))

---

# Extended help

*References*

*Versions*
 - 1.0 on 04.02.2020 [ttraut]
 - 1.0 on 23.09.2020 [ttraut]

*Created by*
 - ttraut
"""
groundWSoilWInteraction_gradientNeg
