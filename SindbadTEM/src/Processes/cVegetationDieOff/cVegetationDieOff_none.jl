export cVegetationDieOff_none

struct cVegetationDieOff_none <: cVegetationDieOff end

function define(params::cVegetationDieOff_none, forcing, land, helpers)
    ## unpack forcing
    @unpack_nt z_zero ⇐ land.constants

    c_f_cVeg_dieOff = z_zero
    @pack_nt c_f_cVeg_dieOff ⇒ land.diagnostics
    return land
end

purpose(::Type{cVegetationDieOff_none}) = "Set the fraction of vegetation that die off to zero."

@doc """

$(getModelDocString(cVegetationDieOff_none))

---

# Extended help

*References*

*Versions*
 - 1.0 on 26.10.2026

*Created by:*
 - skoirala
"""
cVegetationDieOff_none
