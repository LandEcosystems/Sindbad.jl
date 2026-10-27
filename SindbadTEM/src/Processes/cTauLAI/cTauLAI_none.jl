export cTauLAI_none

struct cTauLAI_none <: cTauLAI end

function define(params::cTauLAI_none, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools

    ## calculate variables
    c_eco_k_f_LAI = one.(cEco)

    ## pack land variables
    @pack_nt c_eco_k_f_LAI ⇒ land.diagnostics
    return land
end

purpose(::Type{cTauLAI_none}) = "Sets the litterfall scalar values to 1 (no LAI effect)."

@doc """

$(getModelDocString(cTauLAI_none))

---

# Extended help
"""
cTauLAI_none