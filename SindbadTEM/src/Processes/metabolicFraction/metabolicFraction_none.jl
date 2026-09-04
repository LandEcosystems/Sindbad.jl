export metabolicFraction_none

struct metabolicFraction_none <: metabolicFraction end

function define(params::metabolicFraction_none, forcing, land, helpers)
    @unpack_nt z_zero ⇐ land.constants

    ## calculate variables
    # No metabolic litter: all litterfall from leaf and fine-root pools is
    # structural, and there is no litter chemistry to derive lignin effects from.
    lit_frac_metabolic = z_zero
    lit_C_to_N = z_zero
    lit_frac_lignin = z_zero
    lit_nonsol_to_sol_lignin = z_zero

    ## pack land variables
    @pack_nt (lit_C_to_N, lit_frac_lignin, lit_frac_metabolic, lit_nonsol_to_sol_lignin) ⇒ land.properties
    return land
end

purpose(::Type{metabolicFraction_none}) = "Sets the metabolic litter fraction and the litter chemistry it derives from to 0, so all litterfall is structural."

@doc """

	$(getModelDocString(metabolicFraction_none))

---

# Extended help

With `lit_frac_metabolic = 0` the complement `1 - lit_frac_metabolic` is one, so
the `lignin` process can divide by it without a guard.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
metabolicFraction_none
