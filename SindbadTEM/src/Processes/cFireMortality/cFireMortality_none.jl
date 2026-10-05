export cFireMortality_none

struct cFireMortality_none <: cFireMortality end

function define(params::cFireMortality_none, forcing, land, helpers)
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

