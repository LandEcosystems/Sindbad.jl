export groundWRecharge_dos

#! format: off
@bounds @describe @units @timescale @with_kw struct groundWRecharge_dos{T1, T2} <: groundWRecharge
    dos_exp::T1 = 1.5 | (1.0, 3.0) | "exponent of non-linearity for dos influence on drainage to groundwater" | "" | ""
    n24::T2 = 1.0 | (-Inf, Inf) | "Time scale (day to hour) Parameters" | "" | "day"
end
#! format: on

function define(params::groundWRecharge_dos, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        z_zero ⇐ land.constants
    end

    gw_recharge = z_zero

    ## pack land variables
    @pack_nt begin
        gw_recharge ⇒ land.fluxes
    end
    return land
end

function compute(params::groundWRecharge_dos, forcing, land, helpers)
    ## unpack parameters
    @unpack_groundWRecharge_dos params

    ## unpack land variables
    @unpack_nt begin
        (w_sat, soil_β) ⇐ land.properties
        (ΔsoilW, soilW, ΔgroundW, groundW) ⇐ land.pools
        (z_zero, o_one) ⇐ land.constants
        # n_groundW ⇐ land.constants
        n_groundW = groundW ⇐ helpers.pools.n_layers
    end
    # calculate recharge
    dos_soil_end = clampZeroOne((soilW[end] + ΔsoilW[end]) / w_sat[end])
    recharge_fraction = clampZeroOne((dos_soil_end)^(dos_exp * soil_β[end])) * n24
    gw_recharge = recharge_fraction * (soilW[end] + ΔsoilW[end])

    ΔgroundW = addToEachElem(ΔgroundW, gw_recharge / n_groundW)
    @add_to_elem -gw_recharge ⇒ (ΔsoilW, lastindex(ΔsoilW), :soilW)

    ## pack land variables
    @pack_nt begin
        gw_recharge ⇒ land.fluxes
        (ΔsoilW, ΔgroundW) ⇒ land.pools
    end
    return land
end


purpose(::Type{groundWRecharge_dos}) = "Groundwater recharge as an exponential function of the degree of saturation of the lowermost soil layer."

@doc """

$(getModelDocString(groundWRecharge_dos))

---

# Extended help

*References*

*Versions*
 - 1.0 on 11.11.2019 [skoirala | @dr-ko]: clean up  

*Created by*
 - skoirala | @dr-ko
"""
groundWRecharge_dos
