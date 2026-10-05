export cFireCombustionCompleteness_none

struct cFireCombustionCompleteness_none <: cFireCombustionCompleteness end

function define(params::cFireCombustionCompleteness_none, forcing, land, helpers)
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