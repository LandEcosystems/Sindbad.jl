export cAllocation_Friedlingstein1999

#! format: off
@bounds @describe @units @timescale @with_kw struct cAllocation_Friedlingstein1999{T1,T2,T3} <: cAllocation
    so::T1 = 0.3 | (0.0, 1.0) | "fractional carbon allocation to stem for non-limiting conditions" | "fractional" | ""
    ro::T2 = 0.3 | (0.0, 1.0) | "fractional carbon allocation to root for non-limiting conditions" | "fractional" | ""
    rel_Y::T3 = 2.0 | (1.0, Inf) | "normalization parameter" | "dimensionless" | ""
end
#! format: on

function define(params::cAllocation_Friedlingstein1999, forcing, land, helpers)
    @unpack_cAllocation_Friedlingstein1999 params
    @unpack_nt begin 
        cEco ⇐ land.pools
        cEcoZix = zix ⇐ helpers.pools 
    end

    ## Instantiate variables
    c_allocation = zero(cEco) #sujan
    c_allocation_to_veg = zero(cEco)
    cVeg_names = (:cVegRoot, :cVegWood, :cVegLeaf)
    cVeg_nzix = []
    cVeg_zix = []
    land_pools = getfield(land, :pools)
    for cpName ∈ cVeg_names
        zix = getZix(getfield(land_pools, cpName), getfield(cEcoZix, cpName))
        nZix = oftype(first(c_allocation), length(zix))
        push!(cVeg_nzix, nZix)
        push!(cVeg_zix, zix)
    end
    cVeg_nzix = Tuple(cVeg_nzix)
    cVeg_zix = Tuple(cVeg_zix)
    ## pack land variables
    @pack_nt begin
        c_allocation ⇒ land.diagnostics
        (cVeg_names, cVeg_nzix, cVeg_zix, c_allocation_to_veg) ⇒ land.cAllocation
    end
    return land
end

function compute(params::cAllocation_Friedlingstein1999, forcing, land, helpers)
    ## unpack parameters
    @unpack_cAllocation_Friedlingstein1999 params

    ## unpack land variables
    @unpack_nt begin
        c_allocation ⇐ land.states
        (cVeg_names, cVeg_nzix, cVeg_zix, c_allocation_to_veg) ⇐ land.cAllocation
        c_allocation_f_W_N ⇐ land.diagnostics
        c_allocation_f_LAI ⇐ land.diagnostics
        (z_zero, o_one) ⇐ land.constants
    end
    ## unpack land variables
    # allocation to root; wood & leaf
    a_cVegRoot = ro * (rel_Y + o_one) * c_allocation_f_LAI / (c_allocation_f_LAI + rel_Y * c_allocation_f_W_N)
    a_cVegWood = so * (rel_Y + o_one) * c_allocation_f_W_N / (rel_Y * c_allocation_f_LAI + c_allocation_f_W_N)
    a_cVegLeaf = o_one - cVegRoot - cVegWood

    @rep_elem a_cVegRoot ⇒ (c_allocation_to_veg, 1, :cEco)
    @rep_elem a_cVegWood ⇒ (c_allocation_to_veg, 2, :cEco)
    @rep_elem a_cVegLeaf ⇒ (c_allocation_to_veg, 3, :cEco)


    # distribute the allocation according to pools
    for cl in eachindex(cVeg_names)
        zix = cVeg_zix[cl]
        nZix = cVeg_nzix[cl]
        for ix ∈ zix
            c_allocation_to_veg_ix = c_allocation_to_veg[cl] / nZix
            @rep_elem c_allocation_to_veg_ix ⇒ (c_allocation, ix, :cEco)
        end
    end

    ## pack land variables
    @pack_nt c_allocation ⇒ land.diagnostics
    return land
end

purpose(::Type{cAllocation_Friedlingstein1999}) = "Dynamically allocates carbon based on LAI, moisture, and nutrient availability, following Friedlingstein et al. (1999)."

@doc """

$(getModelDocString(cAllocation_Friedlingstein1999))

---

# Extended help

*References*
 - Friedlingstein; P.; G. Joel; C.B. Field; & I.Y. Fung; 1999: Toward an allocation scheme for global terrestrial carbon models. Glob. Change Biol.; 5; 755-770; doi:10.1046/j.1365-2486.1999.00269.x.

*Versions*
 - 1.0 on 12.01.2020 [sbesnard]  

*Created by*
 - ncarvalhais
"""
cAllocation_Friedlingstein1999
