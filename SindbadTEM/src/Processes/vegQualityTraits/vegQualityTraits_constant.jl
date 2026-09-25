export vegQualityTraits_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct vegQualityTraits_constant{T1,T2,T3,T4,T5,T6,T7,T8} <: vegQualityTraits
    lit_frac_metabolic::T1 = 0.85 | (0.0, 1.0) | "fraction of leaf and fine-root litterfall routed to the metabolic litter pools" | "fraction" | ""
    lit_CN_ratio::T2 = 50.0 | (10.0, 150.0) | "carbon-to-nitrogen ratio of litter" | "gC/gN" | ""
    lit_frac_lignin::T3 = 0.2 | (0.0, 1.0) | "fraction of litter that is lignin" | "fraction" | ""
    lit_nonsol_to_sol_lignin::T4 = 2.22 | (1.0, 5.0) | "scalar converting nonsoluble to soluble lignin" | "fraction" | ""
    lit_frac_lignin_struct::T5 = 0.3 | (0.0, 1.0) | "lignin as a fraction of structural litter carbon" | "fraction" | ""
    lit_frac_C_lignin::T6 = 0.65 | (0.0, 1.0) | "carbon fraction of lignin" | "fraction" | ""
    lit_frac_lignin_wood::T7 = 0.4 | (0.0, 1.0) | "lignin fraction of woody litter" | "fraction" | ""
    lit_k_f_lignin_A::T8 = 3.0 | (0.0, 10.0) | "sensitivity of the structural litter decomposition rate to the structural lignin fraction" | "" | ""
end
#! format: on

function precompute(params::vegQualityTraits_constant, forcing, land, helpers)
    ## unpack parameters
    @unpack_vegQualityTraits_constant params

    ## calculate variables
    # effect of lignin content on the decomposition rate of the structural
    # litter pools
    lit_k_f_lignin = exp(-lit_k_f_lignin_A * lit_frac_lignin_struct)

    ## pack land variables
    @pack_nt begin
        (lit_CN_ratio, lit_frac_lignin, lit_frac_metabolic, lit_nonsol_to_sol_lignin) ⇒ land.properties
        (lit_frac_C_lignin, lit_frac_lignin_struct, lit_frac_lignin_wood, lit_k_f_lignin) ⇒ land.properties
    end
    return land
end

purpose(::Type{vegQualityTraits_constant}) = "Sets the metabolic litter fraction and structural lignin fraction, and the litter chemistry they derive from, to uniform constant values."

@doc """

	$(getModelDocString(vegQualityTraits_constant))

---

# Extended help

Use this approach to hold `lit_frac_metabolic` and `lit_frac_lignin_struct` at
prescribed values instead of deriving them from PFT-dependent litter chemistry. The
default `lit_frac_metabolic` of 0.85 is the CASA intercept `lit_frac_metabolic_A`,
which is what [`vegQualityTraits_vegType`](@ref) returns when litter contains no lignin.
The decomposition-rate effect is still derived from the prescribed lignin fraction, as

`lit_k_f_lignin = exp(-lit_k_f_lignin_A * lit_frac_lignin_struct)`

so the rate factor stays consistent with it.

This used to be two approaches, `metabolicFraction_constant` and `lignin_constant`,
merged into one so a single selection sets every litter-quality trait.

*References*
 - Potter, C. S., Randerson, J. T., Field, C. B., Matson, P. A., Vitousek, P. M., Mooney, H. A., & Klooster, S. A. (1993). Terrestrial ecosystem production: a process model based on global satellite and surface data. Global Biogeochemical Cycles, 7(4), 811-841.

*Versions*
 - 1.0 on 04.09.2026 [skoirala]: as separate metabolicFraction_constant and lignin_constant approaches
 - 2.0 on 09.09.2026 [skoirala]: merged metabolicFraction_constant and lignin_constant into vegQualityTraits_constant

*Created by*
 - skoirala

"""
vegQualityTraits_constant
