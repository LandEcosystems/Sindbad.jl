export cFlowStress_none

struct cFlowStress_none <: cFlowStress end

function define(params::cFlowStress_none, forcing, land, helpers)
    @unpack_nt begin
        cEco ⇐ land.pools
    end
    eco_stressor = one(cEco[1])
    eco_stressor_prev = one(cEco[1])
    slope_eco_stressor = one(cEco[1])
    slope_eco_stressor_prev = one(cEco[1])
    ## pack land variables
    @pack_nt begin
        (
            eco_stressor, slope_eco_stressor, 
            eco_stressor_prev, slope_eco_stressor_prev, 
        ) ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cFlowStress_none}) = "."

@doc """

$(getModelDocString(cFlowStress_none))

---

# Extended help
"""
cFlowStress_none
