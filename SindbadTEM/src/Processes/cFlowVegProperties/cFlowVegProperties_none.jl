export cFlowVegProperties_none

struct cFlowVegProperties_none <: cFlowVegProperties end

function define(params::cFlowVegProperties_none, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools

    @unpack_nt c_taker ⇐ land.constants

    ## calculate variables
    p_E_vec = getVectorOfType(cEco, length(c_taker))
    p_F_vec = getVectorOfType(cEco, length(c_taker))

    ## pack land variables
    @pack_nt (p_E_vec, p_F_vec) ⇒ land.cFlowVegProperties
    return land
end

purpose(::Type{cFlowVegProperties_none}) = "Sets carbon transfers between pools to 0 (no transfer)."

@doc """

$(getModelDocString(cFlowVegProperties_none))

---

# Extended help
"""
cFlowVegProperties_none
