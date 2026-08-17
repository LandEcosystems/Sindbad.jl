export cAllocationNutrients_Friedlingstein1999

#! format: off
@bounds @describe @units @timescale @with_kw struct cAllocationNutrients_Friedlingstein1999{T1,T2} <: cAllocationNutrients
    min_L::T1 = 0.1 | (0.0, 1.0) | "" | "" | ""
    max_L::T2 = 1.0 | (0.0, 1.0) | "" | "" | ""
end
#! format: on

function compute(params::cAllocationNutrients_Friedlingstein1999, forcing, land, helpers)
    ## unpack parameters
    @unpack_cAllocationNutrients_Friedlingstein1999 params

    ## unpack land variables
    @unpack_nt begin
        PAW ⇐ land.states
        ∑w_awc ⇐ land.properties
        c_allocation_f_soilW ⇐ land.diagnostics
        c_allocation_f_soilT ⇐ land.diagnostics
        PET ⇐ land.fluxes
        (z_zero, o_one) ⇐ land.constants
    end

    # estimate NL
    nl = clamp(c_allocation_f_soilT * c_allocation_f_soilW, min_L, max_L)
    NL = ifelse(PET > z_zero, nl, one(nl)) #@needscheck is the else value one or zero? In matlab version was set to ones.

    # water limitation calculation
    WL = clamp(sum(PAW) / ∑w_awc, min_L, max_L)

    # minimum of WL & NL
    c_allocation_f_W_N = min(WL, NL)

    ## pack land variables
    @pack_nt c_allocation_f_W_N ⇒ land.cAllocationNutrients
    return land
end

purpose(::Type{cAllocationNutrients_Friedlingstein1999}) = "Calculates pseudo-nutrient limitation based on Friedlingstein et al. (1999)."

@doc """

$(getModelDocString(cAllocationNutrients_Friedlingstein1999))

---

# Extended help

*References*
 - Friedlingstein; P.; G. Joel; C.B. Field; & I.Y. Fung; 1999: Toward an allocation scheme for global terrestrial carbon models. Glob. Change Biol.; 5; 755-770; doi:10.1046/j.1365-2486.1999.00269.x.

*Notes*
 -  "There is no explicit estimate of soil mineral nitrogen in the version of CASA used for these simulations. As a surrogate; we assume that spatial variability in nitrogen mineralization & soil organic matter decomposition are identical [Townsend et al. 1995]. Nitrogen availability; N; is calculated as the product of the temperature & moisture abiotic factors used in CASA for the calculation of microbial respiration [Potter et al. 1993]." in Friedlingstein et al., 1999.#

 *Versions*
 - 1.0 on 12.01.2020 [sbesnard]  

*Created by*
 - ncarvalhais
"""
cAllocationNutrients_Friedlingstein1999
