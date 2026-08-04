export saturatedFraction_none

struct saturatedFraction_none <: saturatedFraction end

function define(params::saturatedFraction_none, forcing, land, helpers)
    @unpack_nt z_zero ⇐ land.constants

    ## calculate variables
    frac_saturation = z_zero

    ## pack land variables
    @pack_nt frac_saturation ⇒ land.states
    return land
end

purpose(::Type{saturatedFraction_none}) = "Sets the saturated soil fraction to 0."

@doc """

$(getModelDocString(saturatedFraction_none))

---

# Extended help
"""
saturatedFraction_none
