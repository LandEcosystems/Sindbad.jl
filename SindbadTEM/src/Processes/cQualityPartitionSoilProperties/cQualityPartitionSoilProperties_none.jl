export cQualityPartitionSoilProperties_none

struct cQualityPartitionSoilProperties_none <: cQualityPartitionSoilProperties end

function define(params::cQualityPartitionSoilProperties_none, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process
    # does not own leaves the partition to the other factors.
    c_flow_QP_f_soil_props = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_QP_f_soil_props ⇒ land.diagnostics
    return land
end

function precompute(params::cQualityPartitionSoilProperties_none, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_soil_props ⇐ land.diagnostics
        c_flow_named_edges ⇐ land.cCycleBase
    end

    ## calculate variables
    # No soil-property preference between stabilization and the remaining pathway, but
    # still a partition: slow-soil and soil-microbial decomposition divides equally
    # over whichever of the two the configured structure has.
    for group ∈ QP_SOIL_PROPERTIES_GROUPS
        c_flow_QP_f_soil_props = setQPGroupEqual(c_flow_QP_f_soil_props, c_flow_named_edges, group)
    end

    ## pack land variables
    @pack_nt c_flow_QP_f_soil_props ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitionSoilProperties_none}) = "Applies no soil-property preference: slow-soil and soil-microbial decomposition divides equally between old soil carbon and the remaining pathway."

@doc """

	$(getModelDocString(cQualityPartitionSoilProperties_none))

---

# Extended help

Note that this is an equal split, not a factor of one. A giver whose outgoing
flows are all owned by this process must still divide its carbon among them, or
it would give away more than it has once the factors are multiplied. On a
structure with only one of the two pathways present, such as GSI where
`cSoilSlow` feeds only `cSoilOld`, the split degenerates to one, which is the
neutral value.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cQualityPartitionSoilProperties_none
