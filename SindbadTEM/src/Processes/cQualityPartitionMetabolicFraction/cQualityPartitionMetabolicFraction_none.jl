export cQualityPartitionMetabolicFraction_none

struct cQualityPartitionMetabolicFraction_none <: cQualityPartitionMetabolicFraction end

function define(params::cQualityPartitionMetabolicFraction_none, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process
    # does not own leaves the partition to the other factors.
    c_flow_QP_f_metabolic_fraction = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_QP_f_metabolic_fraction ⇒ land.diagnostics
    return land
end

function precompute(params::cQualityPartitionMetabolicFraction_none, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_metabolic_fraction ⇐ land.diagnostics
        c_flow_named_edges ⇐ land.cCycleBase
    end

    ## calculate variables
    # No preference between the metabolic and structural pathway, but still a
    # partition: leaf and fine-root litterfall divides equally over whichever of
    # the two the configured structure has.
    for group ∈ QP_METABOLIC_FRACTION_GROUPS
        c_flow_QP_f_metabolic_fraction =
            setQPGroupEqual(c_flow_QP_f_metabolic_fraction, c_flow_named_edges, group)
    end

    ## pack land variables
    @pack_nt c_flow_QP_f_metabolic_fraction ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitionMetabolicFraction_none}) = "Applies no metabolic-fraction preference: leaf and fine-root litterfall divides equally over the metabolic and structural litter pools."

@doc """

	$(getModelDocString(cQualityPartitionMetabolicFraction_none))

---

# Extended help

Note that this is an equal split, not a factor of one. A giver whose outgoing
flows are all owned by this process must still divide its carbon among them, or
it would give away more than it has once the factors are multiplied. On a
structure with only one of the two pathways present the split degenerates to one,
which is the neutral value.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]

*Created by*
 - skoirala

"""
cQualityPartitionMetabolicFraction_none
