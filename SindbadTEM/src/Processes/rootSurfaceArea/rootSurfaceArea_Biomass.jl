export rootSurfaceArea_Biomass

#! format: off
@bounds @describe @units @timescale @with_kw struct rootSurfaceArea_Biomass{T1} <: rootSurfaceArea
    min_Rsf::T1 = 0.3 | (0.03, 3) | "minimum root surface area, could use root:shoot ratio as a constraint?" | "m2/m2" | ""
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
    root_surface_area_fraction = zero(soilW)

    if plant_form == :tree
        a = oftype(o_one, 50) # "specific root surface area" | "m2/kg" | "convert biomass to area, obtain from Niu et al., JAMES, 2020, Table 1"
        alpha = oftype(o_one, 3.9) # "root distribution index" | "dimensionless" | "obtain from Arora and Boer, AMS, 2003, Table 3"
    elseif plant_form == :shrub
        a = oftype(o_one, 100)
        alpha = oftype(o_one, 3.8)
    elseif plant_form == :herb
        a = oftype(o_one, 200)
        alpha = oftype(o_one, 4.3)
    else
        a = oftype(o_one, 50)
        alpha = oftype(o_one, 3)
    end

    ## pack land variables
    @pack_nt begin
        root_surface_area ⇒ land.diagnostics
        root_surface_area_fraction ⇒ land.properties
        (a, alpha) ⇒ land.diagnostics
    end
    return land
end

function precompute(params::rootSurfaceArea_Biomass, forcing, land, helpers)
    @unpack_nt begin
        soilW ⇐ land.pools
        soil_layer_thickness ⇐ land.properties
        root_surface_area_fraction ⇐ land.properties
        alpha ⇐ land.diagnostics
        z_zero ⇐ land.constants
    end

    depth_lower_m = z_zero
    mm_to_m = oftype(depth_lower_m, 1.0e-3)
    @inbounds for sl in eachindex(soilW)
        depth_upper_m = depth_lower_m + soil_layer_thickness[sl] * mm_to_m
        layer_fraction = (exp(-alpha * depth_lower_m) - exp(-alpha * depth_upper_m)) / alpha
        @rep_elem layer_fraction ⇒ (root_surface_area_fraction, sl, :soilW)
        depth_lower_m = depth_upper_m
    end

    @pack_nt root_surface_area_fraction ⇒ land.properties
    return land
end

function compute(params::rootSurfaceArea_Biomass, forcing, land, helpers)

    ## unpack land variables
    @unpack_rootSurfaceArea_Biomass params
    @unpack_nt begin
        (soilW) ⇐ land.pools
        root_surface_area ⇐ land.diagnostics
        root_surface_area_fraction ⇐ land.properties
        z_zero ⇐ land.constants
        root_over ⇐ land.rootWaterEfficiency
        cVegRoot ⇐ land.pools
        a ⇐ land.diagnostics
    end

    root_layer = 0
    @inbounds for sl in eachindex(root_over)
        root_layer += root_over[sl] > zero(root_over[sl])
    end
    root_area_scale = a * totalS(cVegRoot) * oftype(a, 1.0e-3)

    # root surface area in each layer
    root_surface_area = repElems(root_surface_area) do sl
        if sl < root_layer
            root_area_scale * root_surface_area_fraction[sl] # m2/m2
        else
            z_zero
        end
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

    if sl == 1
        thickness_min = z_zero
    else
        thickness_min = sum(soil_layer_thickness[1:(sl-1)]) / 1000 # from mm to m
    end
    thickness_max = sum(soil_layer_thickness[1:sl]) / 1000
    cum_fraction = (exp(-alpha * thickness_min) - exp(-alpha * thickness_max)) / alpha

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
