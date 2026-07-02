export rootSurfaceArea_Biomass

#! format: off
@bounds @describe @units @timescale @with_kw struct rootSurfaceArea_Biomass{T1} <: rootSurfaceArea
    min_Rsf::T1 = 0.3 | (0.03, 3) | "minimum root surface area" | "m2/m2" | "could use root:shoot ratio as a constraint"
end
#! format: on

@doc """ 
define function is maily used to initialize parameters or variable structure """
function define(params::rootSurfaceArea_Biomass, forcing, land, helpers)

    ## unpack land variables
    @unpack_rootSurfaceArea_Biomass params
    @unpack_nt begin
        (soilW) ⇐ land.pools
        plant_form ⇐ land.states
        o_one ⇐ land.constants
    end

    root_surface_area = zero(soilW)

    if plant_form == :tree
        a = 50 * o_one # "specific root surface area" | "m2/kg" | "convert biomass to area, obtain from Niu et al., JAMES, 2020, Table 1"
        alpha = 3.9 * o_one # "root distribution index" | "dimensionless" | "obtain from Arora and Boer, AMS, 2003, Table 3"
    elseif plant_form == :shrub
        a = 100 * o_one
        alpha = 3.8 * o_one
    elseif plant_form == :herb
        a = 200 * o_one
        alpha = 4.3 * o_one
    else
        a = 50 * o_one
        alpha = 3 * o_one
    end

    ## pack land variables
    @pack_nt begin
        root_surface_area ⇒ land.diagnostics
        (a, alpha) ⇒ land.diagnostics
    end
    return land
end

function compute(params::rootSurfaceArea_Biomass, forcing, land, helpers)

    ## unpack land variables
    @unpack_rootSurfaceArea_Biomass params
    @unpack_nt begin
        (soilW) ⇐ land.pools
        (root_surface_area, max_root_depth) ⇐ land.diagnostics
        soil_layer_thickness ⇐ land.properties
        (z_zero, o_one) ⇐ land.constants
        root_over ⇐ land.rootWaterEfficiency
    end

    root_layer = sum(root_over .> 0)

    # root surface area in each layer
    for sl ∈ eachindex(land.pools.soilW)

        if sl < root_layer
            area_from_layer = cal_Rsf(params, land, sl) # m2/m2
            # area_from_layer = max(area_from_layer, min_Rsf)
        else
            area_from_layer = z_zero
        end

        @rep_elem area_from_layer ⇒ (root_surface_area, sl, :soilW)

    end

    # pack land variables
    @pack_nt root_surface_area ⇒ land.diagnostics
    return land
end

# function get_a_alpha(plant_form)

#     if plant_form == :tree
#         a = 50
#         alpha = 3.9
#     elseif plant_form == :shrub
#         a = 100
#         alpha = 3.8
#     elseif plant_form == :herb
#         a = 200
#         alpha = 4.3
#     else
#         a = 50
#         alpha = 3
#     end

#     return a, alpha
# end

function cal_Rsf(params::rootSurfaceArea_Biomass, land, sl)

    @unpack_rootSurfaceArea_Biomass params
    @unpack_nt begin
        cVegRoot ⇐ land.pools
        soil_layer_thickness ⇐ land.properties
        (z_zero, o_one) ⇐ land.constants
        (a, alpha) ⇐ land.diagnostics
    end

    # a, alpha = get_a_alpha(plant_form)

    fraction(depth) = exp(-alpha * depth)
    if sl == 1
        thickness_min = z_zero
    else
        thickness_min = sum(soil_layer_thickness[1:(sl-1)]) / 1000 # from mm to m
    end
    cum_fraction, _ = quadgk(fraction, thickness_min, sum(soil_layer_thickness[1:sl]) / 1000)

    area_from_layer = a * totalS(cVegRoot) / 1000 * cum_fraction # from gC/m2/Time to kgC/m2/Time

    return area_from_layer
end

@doc """
root surface area from each soil layer is a function of the root biomass in the layer and PFT-specific parameters

---

# compute:
Root surface area (extract water from soil) using rootSurfaceArea_Biomass

*Inputs*
 - land.fluxes.gpp: actual gpp
 - land.pools.soilW: soil moisture
 - land.diagnostics.c_allocation: root allocation proportion

*Outputs*
 - land.diagnostics.root_surface_area: root surface area from each soil layer [nZix of soilW], m2/m2

# update

# Extended help

*References*
Arora, V.K., Boer, G.J., 2003. A Representation of Variable Root Distribution in Dynamic Vegetation Models.
Niu, G.-Y., Fang, Y.-H., Chang, L.-L., Jin, J., Yuan, H., Zeng, X., 2020. Enhancing the Noah-MP Ecosystem Response to Droughts With an Explicit Representation of Plant Water Storage Supplied by Dynamic Root Water Uptake. Journal of Advances in Modeling Earth Systems 12, e2020MS002062. https://doi.org/10.1029/2020MS002062

*Versions*
 - 1.0 on 16.03.2025 [jzhou]

*Created by:*
 - jzhou

*Notes*
 - assumes that the root surface area from each layer remains functional to the root biomass and depth
"""

rootSurfaceArea_Biomass