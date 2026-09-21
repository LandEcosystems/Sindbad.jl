export cFlowLitterfall_none

struct cFlowLitterfall_none <: cFlowLitterfall end

function define(params::cFlowLitterfall_none, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools
    shedding_rate = zero(cEco[1])
    @pack_nt shedding_rate ⇒ land.diagnostics
    return land
end

purpose(::Type{cFlowLitterfall_none}) = "."

@doc """

$(getModelDocString(cFlowLitterfall_none))

---

# Extended help
"""
cFlowLitterfall_none
