export vegFraction_none

struct vegFraction_none <: vegFraction end

function precompute(params::vegFraction_none, forcing, land, helpers)
    @unpack_nt o_one ⇐ land.constants

    # Neutral fallback when no vegetation-cover forcing is available.
    frac_vegetation = o_one
    @pack_nt frac_vegetation ⇒ land.states
    return land
end

purpose(::Type{vegFraction_none}) = "Assumes full vegetation cover when no vegetation-fraction forcing is available."

@doc """

$(getModelDocString(vegFraction_none))

---

# Extended help

This neutral approach sets `frac_vegetation` to one. It is intended for site-level
simulations whose forcing does not contain `f_frac_vegetation`.
"""
vegFraction_none
