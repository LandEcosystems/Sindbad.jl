export cAllocationSoilT_gppGSI

#! format: off
@bounds @describe @units @timescale @with_kw struct cAllocationSoilT_gppGSI{T1} <: cAllocationSoilT
    τ_Tsoil::T1 = 0.2 | (0.001, 1.0) | "temporal change rate for the temperature-limiting function" | "" | ""
end
#! format: on

function define(params::cAllocationSoilT_gppGSI, forcing, land, helpers)
    @unpack_nt o_one ⇐ land.constants

    ## unpack parameters
    @unpack_cAllocationSoilT_gppGSI params

    # assume initial prev as one (no stress)
    c_allocation_f_soilT_prev = o_one

    @pack_nt c_allocation_f_soilT_prev ⇒ land.diagnostics
    return land
end

function compute(params::cAllocationSoilT_gppGSI, forcing, land, helpers)
    ## unpack parameters
    @unpack_cAllocationSoilT_gppGSI params

    ## unpack land variables
    @unpack_nt begin
        gpp_f_airT ⇐ land.diagnostics
        c_allocation_f_soilT_prev ⇐ land.diagnostics
    end

    # computation for the temperature effect on decomposition/mineralization
    c_allocation_f_soilT = c_allocation_f_soilT_prev + (gpp_f_airT - c_allocation_f_soilT_prev) * τ_Tsoil

    # set the prev
    c_allocation_f_soilT_prev = c_allocation_f_soilT

    ## pack land variables
    @pack_nt (c_allocation_f_soilT, c_allocation_f_soilT_prev) ⇒ land.diagnostics
    return land
end

purpose(::Type{cAllocationSoilT_gppGSI}) = "Calculates the temperature effect on allocation as for GPP using the GSI approach."

@doc """

$(getModelDocString(cAllocationSoilT_gppGSI))

---

# Extended help

*References*
 - Forkel M, Carvalhais N, Schaphoff S, von Bloh W, Migliavacca M, Thurner M, Thonicke K [2014] Identifying environmental controls on vegetation greenness phenology through model–data integration. Biogeosciences, 11, 7025–7050.
 - Forkel, M., Migliavacca, M., Thonicke, K., Reichstein, M., Schaphoff, S., Weber, U., Carvalhais, N. (2015).  Codominant water control on global interannual variability and trends in land surface phenology & greenness.
 - Jolly, William M., Ramakrishna Nemani, & Steven W. Running. "A generalized, bioclimatic index to predict foliar phenology in response to climate." Global Change Biology 11.4 [2005]: 619-632.

*Versions*
 - 1.0 on 12.01.2020 [sbesnard]  

*Created by*
 - ncarvalhais & sbesnard
"""
cAllocationSoilT_gppGSI
