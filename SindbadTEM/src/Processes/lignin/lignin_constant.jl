export lignin_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct lignin_constant{T1,T2,T3,T4} <: lignin
    lit_frac_lignin_struct::T1 = 0.3 | (0.0, 1.0) | "lignin as a fraction of structural litter carbon" | "fraction" | ""
    lit_frac_C_lignin::T2 = 0.65 | (0.0, 1.0) | "carbon fraction of lignin" | "fraction" | ""
    lit_frac_lignin_wood::T3 = 0.4 | (0.0, 1.0) | "lignin fraction of woody litter" | "fraction" | ""
    lit_k_f_lignin_A::T4 = 3.0 | (0.0, 10.0) | "sensitivity of the structural litter decomposition rate to the structural lignin fraction" | "" | ""
end
#! format: on

function precompute(params::lignin_constant, forcing, land, helpers)
    ## unpack parameters
    @unpack_lignin_constant params

    ## calculate variables
    # effect of lignin content on the decomposition rate of the structural
    # litter pools
    lit_k_f_lignin = exp(-lit_k_f_lignin_A * lit_frac_lignin_struct)

    ## pack land variables
    @pack_nt (lit_frac_C_lignin, lit_frac_lignin_struct, lit_frac_lignin_wood, lit_k_f_lignin) ⇒ land.properties
    return land
end

purpose(::Type{lignin_constant}) = "Sets the structural lignin fraction to a uniform constant and derives the decomposition-rate effect from it."

@doc """

	$(getModelDocString(lignin_constant))

---

# Extended help

Use this approach to prescribe `lit_frac_lignin_struct` directly instead of
deriving it from the litter chemistry published by `metabolicFraction`. The
decomposition-rate effect is still derived, as

`lit_k_f_lignin = exp(-lit_k_f_lignin_A * lit_frac_lignin_struct)`

so the rate factor stays consistent with the prescribed lignin fraction.

*References*
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
lignin_constant
