export cQualityPartitioncSoil_none

struct cQualityPartitioncSoil_none <: cQualityPartitioncSoil end

function define(params::cQualityPartitioncSoil_none, forcing, land, helpers)
    @unpack_nt begin
        c_taker ⇐ land.cCycleBase
        cEco ⇐ land.pools
    end

    # One value per active carbon transfer, neutral so that every flow this process
    # does not own leaves the partition to the other factors.
    c_flow_QP_f_cSoil = getVectorOfType(cEco, length(c_taker), one)

    @pack_nt c_flow_QP_f_cSoil ⇒ land.diagnostics
    return land
end

function precompute(params::cQualityPartitioncSoil_none, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        c_flow_QP_f_cSoil ⇐ land.diagnostics
        c_flow_qp_groups ⇐ land.cCycleBase
    end

    ## calculate variables
    # No soil-property preference between stabilization and the remaining pathway, but
    # still a partition: slow-soil decomposition divides equally over whichever of
    # the two the configured structure has.
    for (stabilized_positions, other_positions) ∈ c_flow_qp_groups.cSoil
        n_out = length(stabilized_positions) + length(other_positions)
        n_out == 0 && continue
        frac_out = safe_divide(one(eltype(c_flow_QP_f_cSoil)), n_out)
        for i ∈ (stabilized_positions..., other_positions...)
            c_flow_QP_f_cSoil = repElem(c_flow_QP_f_cSoil, frac_out, i)
        end
    end

    ## pack land variables
    @pack_nt c_flow_QP_f_cSoil ⇒ land.diagnostics
    return land
end

purpose(::Type{cQualityPartitioncSoil_none}) = "Applies no soil-property preference: slow-soil decomposition divides equally between old soil carbon and the remaining pathway."

@doc """

	$(getModelDocString(cQualityPartitioncSoil_none))

---

# Extended help

Note that this is an equal split, not a factor of one. A giver whose outgoing
flows are all owned by this process must still divide its carbon among them, or
it would give away more than it has once the factors are multiplied. On a
structure with only one outflow present, such as GSI where `cSoilSlow` feeds only
`cSoilOld`, the split degenerates to one, which is the neutral value.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]: as the cSoilSlow half of cQualityPartitionSoilProperties_none
 - 2.0 on 10.09.2026 [skoirala]: split off into its own cQualityPartitioncSoil factor

*Created by*
 - skoirala

"""
cQualityPartitioncSoil_none
