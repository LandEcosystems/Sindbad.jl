export cFireMortality_none

struct cFireMortality_none <: cFireMortality end

function define(params::cFireMortality_none, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools

    # Keep the downstream cFire interface complete while disabling mortality.
    c_Fire_k = zero(cEco)
    @pack_nt c_Fire_k ⇒ land.diagnostics
    return land
end

purpose(::Type{cFireMortality_none}) = "No fire mortality, no emissions"

@doc """
$(getModelDocString(cFireMortality_none))

---

# Extended help

*Created by*
    - Nuno | nunocarvalhais
"""
cFireMortality_none

