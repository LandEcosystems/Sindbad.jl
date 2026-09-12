export cTauVegProperties_none

struct cTauVegProperties_none <: cTauVegProperties end

function define(params::cTauVegProperties_none, forcing, land, helpers)

    @unpack_nt cEco ⇐ land.pools

    ## calculate variables
    c_eco_k_f_veg_props = one.(cEco)

    ## pack land variables
    @pack_nt c_eco_k_f_veg_props ⇒ land.diagnostics
    return land

end

purpose(::Type{cTauVegProperties_none}) = "Sets the effect of vegetation properties on decomposition rates to 1 (no vegetation effect)."

@doc """

$(getModelDocString(cTauVegProperties_none))

---

# Extended help
"""
cTauVegProperties_none
