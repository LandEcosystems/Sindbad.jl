export cMicrobialEfficiency_none

struct cMicrobialEfficiency_none <: cMicrobialEfficiency end

function define(params::cMicrobialEfficiency_none, forcing, land, helpers)
    @unpack_nt begin
        (c_flow_order, c_giver, c_taker) ⇐ land.constants
        (cEco, cLit, cSoil) ⇐ land.pools
    end

    # Allocate one value per active carbon transfer. Start from 
    # one so that vegetation flows, not mediated by microbial activity, are unchanged.
    c_ME_vec = one.(eltype(cEco).(zero([c_taker...])))
    if cEco isa SVector
        c_ME_vec = SVector{length(c_ME_vec)}(c_ME_vec)
    end

    # Find litter and soil pools, where flows are mediated by microbial activity, 
    # and attribute microbial efficiency.
    zix_cLit = getZix(cLit, helpers.pools.zix.cLit)
    zix_cSoil = getZix(cSoil, helpers.pools.zix.cSoil)

    # "none" means zero microbial transfer efficiency for decomposition:
    # decomposed carbon is not retained in a receiving carbon pool through the
    # microbial-efficiency pathway, all goes to heterotrophic respiration. 
    for fO ∈ c_flow_order
        give_r = c_giver[fO]
        is_decomposition = (give_r ∈ zix_cLit || give_r ∈ zix_cSoil)
        me_value = is_decomposition ? zero(c_ME_vec[fO]) : one(c_ME_vec[fO])
        c_ME_vec = repElem(c_ME_vec, me_value, c_ME_vec, c_ME_vec, fO)
    end

    @pack_nt c_ME_vec ⇒ land.diagnostics
	return land
end

purpose(::Type{cMicrobialEfficiency_none}) = "Set microbial carbon-transfer efficiency in all flows originating from litter and soil pools to 0; flows from vegetation have an efficiency of one."

@doc """ 

	$(getModelDocString(cMicrobialEfficiency_none))

---

# Extended help

*References*

*Versions*
 - 1.0 on 27.08.2026 [sol]

*Created by*
 - sol

"""
cMicrobialEfficiency_none
