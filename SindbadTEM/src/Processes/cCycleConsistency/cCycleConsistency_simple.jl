export cCycleConsistency_simple

struct cCycleConsistency_simple <: cCycleConsistency end

function define(params::cCycleConsistency_simple, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        cEco ⇐ land.pools
        c_flow_A_array ⇐ land.diagnostics
        c_giver ⇐ land.constants
    end
    # make list of indices which give carbon to other pools during the flow, and separate them if 
    # they are above or below the diagonal in flow vector
    giver_upper = Tuple([ind[2] for ind ∈ findall(>(0), upper_triangle_mask(c_flow_A_array) .* c_flow_A_array)])
    giver_lower = Tuple([ind[2] for ind ∈ findall(>(0), lower_triangle_mask(c_flow_A_array) .* c_flow_A_array)])
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
        (giver_lower_unique, giver_lower_indices, giver_upper_unique, giver_upper_indices) ⇐ land.cCycleConsistency
        tolerance ⇐ helpers.numbers
    end

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

    # sum per column of QP values > 0 must be 1

    # off diagonal ME values must be between 0 and 1

    # ME values in vegetation columns must be 0

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
