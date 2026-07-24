export cFireBurnedArea_none

struct cFireBurnedArea_none <: cFireBurnedArea end

function define(params::cFireBurnedArea_none, forcing, land, helpers)
    return land
end

purpose(::Type{cFireBurnedArea_none}) = "No fire forcing, and therefore, no fire emissions."

@doc """

$(getModelDocString(cFireBurnedArea_none))

---

# Extended help

*Created by*
  - Nuno | nunocarvalhais
"""
cFireBurnedArea_none
