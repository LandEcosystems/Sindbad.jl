export cFireCombustionCompleteness_none

struct cFireCombustionCompleteness_none <: cFireCombustionCompleteness end

function define(params::cFireCombustionCompleteness_none, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools

    # Keep the downstream cFire interface complete while disabling combustion.
    c_Fire_cci = zero(cEco)
    @pack_nt c_Fire_cci ⇒ land.diagnostics
    return land
end

purpose(::Type{cFireCombustionCompleteness_none}) = "No fire forcing, no emissions"

@doc """
$(getModelDocString(cFireCombustionCompleteness_none))

---

# Extended help

*Created by*
  - Nuno | nunocarvalhais
"""
cFireCombustionCompleteness_none
