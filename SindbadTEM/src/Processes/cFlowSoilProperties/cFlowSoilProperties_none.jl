export cFlowSoilProperties_none

struct cFlowSoilProperties_none <: cFlowSoilProperties end

function define(params::cFlowSoilProperties_none, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end
    ## calculate variables
    p_E_vec = getVectorOfType(cEco, length(c_taker))
    p_F_vec = getVectorOfType(cEco, length(c_taker))

    ## pack land variables
    @pack_nt (p_E_vec, p_F_vec) ⇒ land.diagnostics
    return land
end

purpose(::Type{cFlowSoilProperties_none}) = "Sets carbon transfers between pools to 0 (no transfer)."

@doc """

$(getModelDocString(cFlowSoilProperties_none))

---

# Extended help
"""
cFlowSoilProperties_none
