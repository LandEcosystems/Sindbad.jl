export cMicrobialEfficiency_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct cMicrobialEfficiency_constant{T1} <: cMicrobialEfficiency
	constant_MicEff::T1 = 0.1 | (0.0, 1.0) | "Microbial efficency." | "fraction" | ""
end
#! format: on

function define(params::cMicrobialEfficiency_constant, forcing, land, helpers)
    @unpack_nt begin 
        c_taker ⇐ land.constants
        cEco ⇐ land.pools
    end

    # Allocate one value per active carbon transfer. Start from 
    # one so that vegetation flows, not mediated by microbial activity, are unchanged.
    c_flow_ME_vec = one.(eltype(cEco).(zero([c_taker...])))
    if cEco isa SVector
        c_flow_ME_vec = SVector{length(c_flow_ME_vec)}(c_flow_ME_vec)
    end

    @pack_nt c_flow_ME_vec ⇒ land.diagnostics
	return land
end

function precompute(params::cMicrobialEfficiency_constant, forcing, land, helpers)
    @unpack_cMicrobialEfficiency_constant params
    @unpack_nt begin
        c_flow_ME_vec ⇐ land.diagnostics
        (c_flow_order, c_giver, c_taker) ⇐ land.constants
        (cLit, cSoil) ⇐ land.pools
    end

    # Find litter and soil pools, where flows are mediated by microbial activity, 
    # and attribute microbial efficiency.
    zix_cLit = getZix(cLit, helpers.pools.zix.cLit)
    zix_cSoil = getZix(cSoil, helpers.pools.zix.cSoil)

    for fO ∈ c_flow_order
        give_r = c_giver[fO]
        is_decomposition = ((give_r ∈ zix_cLit) || (give_r ∈ zix_cSoil))
        me_value = is_decomposition ? constant_MicEff : one(constant_MicEff)
        c_flow_ME_vec = repElem(c_flow_ME_vec, me_value, c_flow_ME_vec, c_flow_ME_vec, fO)
    end

    @pack_nt c_flow_ME_vec ⇒ land.diagnostics
	return land
end

purpose(::Type{cMicrobialEfficiency_constant}) = "A constant microbial carbon-transfer efficiency is used in all flows originating from litter and soil pools; flows from vegetation have an efficiency of one."

@doc """ 

	$(getModelDocString(cMicrobialEfficiency_constant))

---
# Extended help
`constant_MicEff` is applied only to active carbon transfers from 
`cLit` or `cSoil` into `cLit` or `cSoil`, as diagnosed from `c_giver` and
`c_taker`. Reserve exchange, allocation, and litter shedding have a value of 1
because these carbon transfers are not mediated by microbial activity.

*References*

*Versions*
 - 1.0 on 27.08.2026 [sol]

*Created by*
 - sol

"""
cMicrobialEfficiency_constant

