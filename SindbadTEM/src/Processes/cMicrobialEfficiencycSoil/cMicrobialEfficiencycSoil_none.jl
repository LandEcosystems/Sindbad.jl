export cMicrobialEfficiencycSoil_none

struct cMicrobialEfficiencycSoil_none <: cMicrobialEfficiencycSoil end

function define(params::cMicrobialEfficiencycSoil_none, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that the soil carbon pools add no
    # efficiency control of their own and every flow keeps what the other factors give it.
    c_flow_ME_f_cSoil = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_ME_f_cSoil ⇒ land.diagnostics
    return land
end

purpose(::Type{cMicrobialEfficiencycSoil_none}) = "Applies no control from the soil carbon pools: the transfers leaving them keep an efficiency of one."

@doc """

	$(getModelDocString(cMicrobialEfficiencycSoil_none))

---

# Extended help

A factor of one means perfect retention, not zero retention: the carbon leaving these
pools all arrives, and none of it respires through the microbial-efficiency pathway. To
give the group an efficiency of zero instead, select `_constant` with its parameter at
zero.

This is also what a structure without soil carbon pools gets whichever approach of this
process is selected, because `zix.cSoil` is then empty and no flow matches.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cMicrobialEfficiencycSoil_none
