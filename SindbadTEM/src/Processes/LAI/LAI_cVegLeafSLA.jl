export LAI_cVegLeafSLA

# struct LAI_cVegLeafSLA <: LAI end
#! format: off
@bounds @describe @units @timescale @with_kw struct LAI_cVegLeafSLA{T1} <: LAI
    SLA::T1 = 0.005 | (0.002, 0.024) | "specific leaf area" | "m^2.gC^-1" | ""
end
#! format: on

# function define(params::LAI_cVegLeafSLA, forcing, land, helpers)
#     # @unpack_LAI_cVegLeafSLA params
#     SLA = Float32(0.010); #0.016;
#     ## pack land variables
#     @pack_nt SLA ⇒ land.diagnostics
#     return land
# end

function compute(params::LAI_cVegLeafSLA, forcing, land, helpers)
    ## unpack parameters
    @unpack_LAI_cVegLeafSLA params

    @unpack_nt cVegLeaf ⇐ land.pools
    # @unpack_nt SLA ⇐ land.diagnostics

    ## calculate variables
    cVegLeafTotal = totalS(cVegLeaf)
    LAI = cVegLeafTotal * SLA

    ## pack land variables
    @pack_nt LAI ⇒ land.states
    @pack_nt SLA ⇒ land.diagnostics
    return land
end


purpose(::Type{LAI_cVegLeafSLA}) = "set the value of SLA"


@doc """
sets the value of land.states.LAI from the carbon in the leaves of the previous time step
$(getModelDocString(LAI_cVegLeafSLA))

---

# compute:
Leaf area index using LAI_cVegLeafSLA

*Inputs*
 - land.pools.cEco[cVegLeafZix]: carbon in the leave

*Outputs*
 - land.states.LAI: the value of LAI for current time step
 - land.states.LAI

---

# Extended help

*References*

*Versions*
 - 1.0 on 05.05.2020 [sbesnard]

*Created by:*
 - sbesnard
"""
LAI_cVegLeafSLA
