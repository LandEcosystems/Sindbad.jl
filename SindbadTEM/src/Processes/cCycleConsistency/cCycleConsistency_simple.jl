export cCycleConsistency_simple

struct cCycleConsistency_simple <: cCycleConsistency end

function define(params::cCycleConsistency_simple, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        cEco ⇐ land.pools
        (c_giver, c_taker) ⇐ land.cCycleBase
    end
    # make list of indices which give carbon to other pools during the flow, and separate them if 
    # they are above or below the diagonal in flow vector. A flow is one off-diagonal
    # entry at row taker, column giver, so the side of the diagonal it falls on is
    # the taker index against the giver index, with no transfer matrix needed
    giver_upper = Tuple([c_giver[f] for f ∈ eachindex(c_giver, c_taker) if c_taker[f] < c_giver[f]])
    giver_lower = Tuple([c_giver[f] for f ∈ eachindex(c_giver, c_taker) if c_taker[f] > c_giver[f]])
    giver_upper_unique = unique(giver_upper)
    giver_lower_unique = unique(giver_lower)
    giver_upper_indices = []
    for giv in giver_upper_unique
        giver_pos = findall(==(giv), c_giver)
        push!(giver_upper_indices, Tuple(giver_pos))
    end
    giver_lower_indices = []
    for giv in giver_lower_unique
        giver_pos = findall(==(giv), c_giver)
        push!(giver_lower_indices, Tuple(giver_pos))
    end
    giver_lower_indices = Tuple(giver_lower_indices)
    giver_upper_indices = Tuple(giver_upper_indices)
    @pack_nt (giver_lower_unique, giver_lower_indices, giver_upper_unique, giver_upper_indices) ⇒ land.cCycleConsistency
    return land
end

"""
throwError(land, msg)
display and error msg and stop when there is inconsistency
"""
function throwError(land, msg)
    tc_print(land)
    if hasproperty(SindbadTEM, :error_catcher)
        push!(SindbadTEM.error_catcher, land)
    end
    error(msg)
end

function checkCcycleErrors(params::cCycleConsistency_simple, forcing, land, helpers, ::DoCatchModelErrors) #when check is on
    ## unpack land variables
    @unpack_nt begin
        c_allocation ⇐ land.diagnostics
        c_flow_A_vec ⇐ land.diagnostics
        c_flow_QP_vec ⇐ land.diagnostics
        c_flow_ME_vec ⇐ land.diagnostics
        (c_giver, c_taker) ⇐ land.cCycleBase
        (giver_lower_unique, giver_lower_indices, giver_upper_unique, giver_upper_indices) ⇐ land.cCycleConsistency
        tolerance ⇐ helpers.numbers
    end

    zix_cVeg = helpers.pools.zix.cVeg
    zix_cLit = helpers.pools.zix.cLit
    zix_cMic = helpers.pools.zix.cMic
    zix_cSoil = helpers.pools.zix.cSoil

    # check allocation
    for i in eachindex(c_allocation)
        if c_allocation[i] < zero(eltype(c_allocation))
            throwError(land, "negative values in carbon_allocation at index $(i). Cannot continue")
        end
    end

    for i in eachindex(c_allocation)
        if c_allocation[i] > one(eltype(c_allocation))
            throwError(land, "carbon_allocation larger than one at index $(i). Cannot continue")
        end
    end

    if !isapprox(sum(c_allocation), one(eltype(c_allocation)); atol=tolerance)
        throwError(land, "cAllocation does not sum to 1. Cannot continue")
    end

    # Check carbon flow vector
    # A -1 in diagonals, 0 or a number in off-diagonals

    # TO SIMPLIFY QP must be finite, must remain neutral for vegetation takers, and must sum to one per giver over litter, microbial, and soil takers.
    if !isempty(c_giver)
        current_giver = c_giver[1]
        qp_sum = zero(eltype(c_flow_QP_vec))
        n_qp_flows = 0

        @inbounds for fO ∈ eachindex(c_giver, c_taker, c_flow_QP_vec)
            giver = c_giver[fO]

            if giver != current_giver
                if n_qp_flows > 0 && (!isfinite(qp_sum) || abs(qp_sum - one(qp_sum)) > tolerance)
                    throwError(land, "cQualityPartition does not contain finite values summing to one for giver pool $(current_giver). Cannot continue")
                end

                current_giver = giver
                qp_sum = zero(qp_sum)
                n_qp_flows = 0
            end

            taker = c_taker[fO]
            QP = c_flow_QP_vec[fO]

            if !isfinite(QP)
                throwError(land, "cQualityPartition contains a non-finite value at flow index $(fO). Cannot continue")
            end

            # TO SIMPLIFY QP must not modify transfers whose taker is a vegetation pool.
            if taker ∈ zix_cVeg
                if QP != one(QP)
                    throwError(land, "cQualityPartition modifies a flow into a vegetation pool at index $(fO). Cannot continue")
                end
            elseif taker ∈ zix_cLit || taker ∈ zix_cMic || taker ∈ zix_cSoil
                qp_sum += QP
                n_qp_flows += 1
            end
        end

        if n_qp_flows > 0 && (!isfinite(qp_sum) || abs(qp_sum - one(qp_sum)) > tolerance)
            throwError(land, "cQualityPartition does not contain finite values summing to one for giver pool $(current_giver). Cannot continue")
        end
    end

    # TO SIMPLIFY ME must be finite and bounded between zero and one on every carbon-flow edge.
    @inbounds for fO ∈ eachindex(c_giver, c_flow_ME_vec)
        ME = c_flow_ME_vec[fO]

        if !isfinite(ME) || ME < zero(ME) || ME > one(ME)
            throwError(land, "microbial efficiency must be finite and inside [0, 1] at flow index $(fO). Cannot continue")
        end

        # TO SIMPLIFY ME must remain neutral on transfers originating from vegetation pools.
        if c_giver[fO] ∈ cVeg && ME != one(ME)
            throwError(land, "microbial efficiency modifies a vegetation-originating flow at index $(fO). Cannot continue")
        end
    end

    # check if any of the off-diagonal values of flow vector is negative
    for i in eachindex(c_flow_A_vec)
        if c_flow_A_vec[i] < zero(eltype(c_flow_A_vec))
            throwError(land, "negative value in flow vector at index $(i). Cannot continue")
        end
    end

    # check if any of the off-diagonal values of flow vector is larger than 1.
    for i in eachindex(c_flow_A_vec)
        if c_flow_A_vec[i] > one(eltype(c_flow_A_vec))
            throwError(land, "flow is greater than one in flow vector at index $(i). Cannot continue")
        end
    end

    # check if the flow to different pools add up to 1
    # below the diagonal
    # the sum of A per column below the diagonals is always < 1. The tolerance allows for small overshoot over 1, but this may result in a negative carbon pool if frequent

    for (i, giv) in enumerate(giver_upper_unique)
        s = zero(eltype(c_flow_A_vec))
        for ind in giver_upper_indices[i]
            s = s + c_flow_A_vec[ind]
        end
        if (s - one(s)) > helpers.numbers.tolerance
            throwError(land, "sum of giver flow greater than one in upper cFlow vector for $(info.helpers.pools.components.cEco[giv]) pool. Cannot continue.")
        end
    end

    for (i, giv) in enumerate(giver_lower_unique)
        s = zero(eltype(c_flow_A_vec))
        for ind in giver_lower_indices[i]
            s = s + c_flow_A_vec[ind]
        end
        if (s - one(s)) > helpers.numbers.tolerance
            throwError(land, "sum of giver flow greater than one in lower cFlow vector for $(info.helpers.pools.components.cEco[giv]) pool. Cannot continue.")
        end
    end

    return nothing
end

function checkCcycleErrors(params::cCycleConsistency_simple, forcing, land, helpers, ::DoNotCatchModelErrors) #when check is off/false
    return nothing
end

function compute(params::cCycleConsistency_simple, forcing, land, helpers)
    checkCcycleErrors(params, forcing, land, helpers, helpers.run.catch_model_errors)
    return land
end

purpose(::Type{cCycleConsistency_simple}) = "Checks consistency in the cCycle vector, including c_allocation and cFlow."

@doc """

$(getModelDocString(cCycleConsistency_simple))

---

# Extended help

*References*

*Versions*
 - 1.0 on 12.05.2022: skoirala: julia implementation  

*Created by*
 - sbesnard
"""
cCycleConsistency_simple
