export cFlowReserves_none

struct cFlowReserves_none <: cFlowReserves end

function define(params::cFlowReserves_none, forcing, land, helpers)
    @unpack_nt begin
        cEco ⇐ land.pools
    end
    leaf_to_reserve = zero(cEco[1])
    root_to_reserve = zero(cEco[1])
    reserve_to_leaf = zero(cEco[1])
    reserve_to_root = zero(cEco[1])
    ## pack land variables
    @pack_nt begin
        (
            leaf_to_reserve, #leaf_to_reserve_frac, 
            root_to_reserve, #root_to_reserve_frac, 
            reserve_to_leaf, #reserve_to_leaf_frac, 
            reserve_to_root, #reserve_to_root_frac,
        ) ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cFlowReserves_none}) = "."

@doc """

$(getModelDocString(cFlowReserves_none))

---

# Extended help
"""
cFlowReserves_none
