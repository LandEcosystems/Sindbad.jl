export lignin_none

struct lignin_none <: lignin end

function define(params::lignin_none, forcing, land, helpers)
    @unpack_nt (o_one, z_zero) ⇐ land.constants

    ## calculate variables
    # No lignin: nothing is stabilized through the lignin-controlled pathway, and
    # decomposition rates are left untouched. lit_k_f_lignin is a multiplicative
    # rate factor, so its neutral value is one, not zero.
    lit_frac_lignin_struct = z_zero
    lit_frac_C_lignin = z_zero
    lit_frac_lignin_wood = z_zero
    lit_k_f_lignin = o_one

    ## pack land variables
    @pack_nt (lit_frac_C_lignin, lit_frac_lignin_struct, lit_frac_lignin_wood, lit_k_f_lignin) ⇒ land.properties
    return land
end

purpose(::Type{lignin_none}) = "Sets the lignin content to 0 and leaves decomposition rates unchanged (no lignin effect)."

@doc """

	$(getModelDocString(lignin_none))

---

# Extended help

Note that `lit_k_f_lignin` is one here, not zero. The legacy
`cTauVegProperties_none` set the equivalent `LIGEFF` to zero, which is not the
neutral element of a multiplicative rate factor. That was harmless while nothing
read the value back, but it is wrong once `cTauVegProperties_CASA` consumes it.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
lignin_none
