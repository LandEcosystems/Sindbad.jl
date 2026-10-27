export cFlowSoilProperties_none

struct cFlowSoilProperties_none <: cFlowSoilProperties end

function define(params::cFlowSoilProperties_none, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.constants
        cEco ⇐ land.pools
    end 
    ## calculate variables
    p_E_vec = eltype(cEco).(zero([c_taker...]))

    if cEco isa SVector
        p_E_vec = SVector{length(p_E_vec)}(p_E_vec)
    end

    p_F_vec = eltype(cEco).(zero([c_taker...]))
    if cEco isa SVector
        p_F_vec = SVector{length(p_F_vec)}(p_F_vec)
    end

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