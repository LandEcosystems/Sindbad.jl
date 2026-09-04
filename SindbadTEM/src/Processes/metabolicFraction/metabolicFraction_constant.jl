export metabolicFraction_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct metabolicFraction_constant{T1,T2,T3,T4} <: metabolicFraction
    lit_frac_metabolic::T1 = 0.85 | (0.0, 1.0) | "fraction of leaf and fine-root litterfall routed to the metabolic litter pools" | "fraction" | ""
    lit_C_to_N::T2 = 50.0 | (10.0, 150.0) | "carbon-to-nitrogen ratio of litter" | "gC/gN" | ""
    lit_frac_lignin::T3 = 0.2 | (0.0, 1.0) | "fraction of litter that is lignin" | "fraction" | ""
    lit_nonsol_to_sol_lignin::T4 = 2.22 | (1.0, 5.0) | "scalar converting nonsoluble to soluble lignin" | "fraction" | ""
end
#! format: on

function precompute(params::metabolicFraction_constant, forcing, land, helpers)
    ## unpack parameters
    @unpack_metabolicFraction_constant params

    ## pack land variables
    @pack_nt (lit_C_to_N, lit_frac_lignin, lit_frac_metabolic, lit_nonsol_to_sol_lignin) ⇒ land.properties
    return land
end

purpose(::Type{metabolicFraction_constant}) = "Sets the metabolic litter fraction and the litter chemistry it derives from to uniform constant values."

@doc """

	$(getModelDocString(metabolicFraction_constant))

---

# Extended help

Use this approach to hold `lit_frac_metabolic` at a prescribed value instead of
deriving it from the lignin-to-nitrogen ratio. The default of 0.85 is the CASA
intercept `lit_frac_metabolic_A`, which is what
[`metabolicFraction_CASA`](@ref) returns when litter contains no lignin.

*References*
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
metabolicFraction_constant
