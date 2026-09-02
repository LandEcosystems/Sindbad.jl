export cAllocationTreeFraction_Friedlingstein1999

#! format: off
@bounds @describe @units @timescale @with_kw struct cAllocationTreeFraction_Friedlingstein1999{T1} <: cAllocationTreeFraction
    frac_fine_to_coarse::T1 = 1.0 | (0.0, 1.0) | "carbon fraction allocated to fine roots" | "fraction" | ""
end
#! format: on

function define(params::cAllocationTreeFraction_Friedlingstein1999, forcing, land, helpers)
    ## unpack parameters
    ## calculate variables
    # cVegRoot resolves to every root pool the configured structure has, fine and coarse
    # included, so these names work under every configuration without probing for variants
    cVeg_names_for_c_allocation_frac_tree = (:cVegRoot, :cVegWood, :cVegLeaf)::Tuple
    @pack_nt cVeg_names_for_c_allocation_frac_tree ⇒ land.cAllocationTreeFraction
    return land
end

function setCAlloc(c_allocation, cAllocValue, zix, helpers)
    for ix ∈ eachindex(zix)
        @rep_elem cAllocValue * c_allocation[zix[ix]] ⇒ (c_allocation, zix[ix], :cEco)
    end
    return c_allocation
end

function compute(params::cAllocationTreeFraction_Friedlingstein1999, forcing, land, helpers)
    ## unpack parameters
    @unpack_cAllocationTreeFraction_Friedlingstein1999 params

    ## unpack land variables
    @unpack_nt begin
        frac_tree ⇐ land.states
        c_allocation ⇐ land.diagnostics
        cVeg_names_for_c_allocation_frac_tree ⇐ land.cAllocationTreeFraction
        (z_zero, o_one) ⇐ land.constants
    end
    # the allocation fractions according to the partitioning to root/wood/leaf - represents plant level allocation
    r0 = z_zero
    for ix ∈ helpers.pools.zix.cVegRoot
        r0 = r0 + c_allocation[ix]
    end
    s0 = z_zero
    for ix ∈ helpers.pools.zix.cVegWood
        s0 = s0 + c_allocation[ix]
    end
    l0 = z_zero
    for ix ∈ helpers.pools.zix.cVegLeaf
        l0 = l0 + c_allocation[ix]
    end     # this is to below ground root fine+coarse

    # adjust for spatial consideration of TreeFrac & plant level
    # partitioning between fine & coarse roots
    o_one = one(eltype(c_allocation))
    a_cVegWood = frac_tree
    a_cVegRoot = o_one + (s0 / (r0 + l0)) * (o_one - frac_tree)
    a_cVegRootF = a_cVegRoot * (frac_fine_to_coarse * frac_tree + (o_one - frac_tree))
    a_cVegRootC = a_cVegRoot * (o_one - frac_fine_to_coarse) * frac_tree
    # cVegRoot = cVegRootF + cVegRootC
    a_cVegLeaf = o_one + (s0 / (r0 + l0)) * (o_one - frac_tree)

    c_allocation = setCAlloc(c_allocation, a_cVegWood, helpers.pools.zix.cVegWood, helpers)
    c_allocation = setCAlloc(c_allocation, a_cVegRoot, helpers.pools.zix.cVegRoot, helpers)
    c_allocation = setCAlloc(c_allocation, a_cVegLeaf, helpers.pools.zix.cVegLeaf, helpers)

    @pack_nt c_allocation ⇒ land.diagnostics

    return land
end

purpose(::Type{cAllocationTreeFraction_Friedlingstein1999}) = "Adjusts allocation coefficients according to the fraction of trees to herbaceous plants and fine to coarse root partitioning."

@doc """

$(getModelDocString(cAllocationTreeFraction_Friedlingstein1999))

---

# Extended help

*References*
 - Friedlingstein; P.; G. Joel; C.B. Field; & I.Y. Fung; 1999: Toward an allocation scheme for global terrestrial carbon models. Glob. Change Biol.; 5; 755-770; doi:10.1046/j.1365-2486.1999.00269.x.

*Versions*
 - 1.0 on 12.01.2020 [sbesnard]  

*Created by*
 - ncarvalhais
"""
cAllocationTreeFraction_Friedlingstein1999
