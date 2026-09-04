export cAllocation_GSI

struct cAllocation_GSI <: cAllocation end

function define(params::cAllocation_GSI, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools
    ## Instantiate variables
    c_allocation = zero(cEco)
    cVeg_names = (:cVegRoot, :cVegWood, :cVegLeaf)

    c_allocation_to_veg = zero(cEco)
    cVeg_zix = Tuple{Int}[]
    cVeg_nzix = eltype(cEco)[]
    cpI = 1
    for cpName ∈ cVeg_names
        zix = getfield(helpers.pools.zix, cpName)
        nZix = oftype(first(c_allocation), length(zix))
        push!(cVeg_zix, zix)
        push!(cVeg_nzix, nZix)
    end
    cVeg_zix = Tuple(cVeg_zix)
    cVeg_nzix = Tuple(cVeg_nzix)
    ## pack land variables
    @pack_nt begin
        (cVeg_names, cVeg_zix, cVeg_nzix, c_allocation_to_veg) ⇒ land.cAllocation
        c_allocation ⇒ land.diagnostics
    end
    return land
end

function compute(params::cAllocation_GSI, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        (cVeg_names, cVeg_zix, cVeg_nzix, c_allocation_to_veg) ⇐ land.cAllocation
        c_allocation ⇐ land.diagnostics
        c_allocation_f_soilW ⇐ land.diagnostics
        c_allocation_f_soilT ⇐ land.diagnostics
        t_two ⇐ land.constants
    end
    c_two = one(c_allocation_f_soilT) + one(c_allocation_f_soilT)
    # allocation to root; wood & leaf
    a_cVegLeaf = c_allocation_f_soilW / ((c_allocation_f_soilW + c_allocation_f_soilT) * c_two)
    a_cVegWood = c_allocation_f_soilW / ((c_allocation_f_soilW + c_allocation_f_soilT) * c_two)
    a_cVegRoot = c_allocation_f_soilT / ((c_allocation_f_soilW + c_allocation_f_soilT))

    # @needscheck. from semda l and w are allocated more when there is no water stress
    # % change a2L a2R a2W according to DAS components...
    #     a2L = DASW./(DASW+DAST)./2;
    #     a2W = DASW./(DASW+DAST)./2;
    #     a2R = DAST./(DASW+DAST);

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

    @pack_nt c_allocation ⇒ land.diagnostics

    return land
end

purpose(::Type{cAllocation_GSI}) = "Dynamically allocates carbon based on temperature, water, and radiation stressors following the GSI approach."

@doc """

$(getModelDocString(cAllocation_GSI))

---

# Extended help

*References*
 - Forkel M, Carvalhais N, Schaphoff S, von Bloh W, Migliavacca M, Thurner M, Thonicke K [2014] Identifying environmental controls on vegetation greenness phenology through model–data integration. Biogeosciences, 11, 7025–7050.
 - Forkel, M., Migliavacca, M., Thonicke, K., Reichstein, M., Schaphoff, S., Weber, U., Carvalhais, N. (2015).  Codominant water control on global interannual variability and trends in land surface phenology & greenness.
  - Friedlingstein; P.; G. Joel; C.B. Field; & I.Y. Fung; 1999: Toward an allocation scheme for global terrestrial carbon models. Glob. Change Biol.; 5; 755-770; doi:10.1046/j.1365-2486.1999.00269.x.
 - Jolly, William M., Ramakrishna Nemani, & Steven W. Running. "A generalized, bioclimatic index to predict foliar phenology in response to climate." Global Change Biology 11.4 [2005]: 619-632.
 - Sharpe PJH, Rykiel EJ (1991) Modelling integrated response of plants to multiple stresses. In: Response of Plants to Multiple Stresses (eds Mooney HA, Winner WE, Pell EJ), pp. 205±224, Academic Press, San Diego, CA.

*Versions*
 - 1.0 on 12.01.2020 [sbesnard]  

*Created by*
 - ncarvalhais & sbesnard

NotesCheck if we can partition C to leaf & wood constrained by interception of light.
"""
cAllocation_GSI
