export vegQualityTraits_none

struct vegQualityTraits_none <: vegQualityTraits end

function define(params::vegQualityTraits_none, forcing, land, helpers)
    @unpack_nt (o_one, z_zero) ⇐ land.constants

    ## calculate variables
    # No metabolic litter and no lignin: all litterfall from leaf and fine-root
    # pools is structural, there is no litter chemistry to derive lignin effects
    # from, and decomposition rates are left untouched. lit_k_f_lignin is a
    # multiplicative rate factor, so its neutral value is one, not zero.
    lit_frac_metabolic = z_zero
    lit_CN_ratio = z_zero
    lit_frac_lignin = z_zero
    lit_nonsol_to_sol_lignin = z_zero
    lit_frac_lignin_struct = z_zero
    lit_frac_C_lignin = z_zero
    lit_frac_lignin_wood = z_zero
    lit_k_f_lignin = o_one

    ## pack land variables
    @pack_nt begin
        (lit_CN_ratio, lit_frac_lignin, lit_frac_metabolic, lit_nonsol_to_sol_lignin) ⇒ land.properties
        (lit_frac_C_lignin, lit_frac_lignin_struct, lit_frac_lignin_wood, lit_k_f_lignin) ⇒ land.properties
    end
    return land
end

purpose(::Type{vegQualityTraits_none}) = "Sets the metabolic litter fraction and the lignin content to 0, and leaves decomposition rates unchanged (no lignin effect)."

@doc """

	$(getModelDocString(vegQualityTraits_none))

---

# Extended help

With `lit_frac_metabolic = 0` the complement `1 - lit_frac_metabolic` is one. Note
that `lit_k_f_lignin` is one here, not zero: it is a multiplicative rate factor, and
one is its neutral element.

This used to be two approaches, `metabolicFraction_none` and `lignin_none`, merged
into one so a single selection zeroes every litter-quality trait consistently.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]: as separate metabolicFraction_none and lignin_none approaches
 - 2.0 on 09.09.2026 [skoirala]: merged metabolicFraction_none and lignin_none into vegQualityTraits_none

*Created by*
 - skoirala

"""
vegQualityTraits_none
