export rootSurfaceArea_vom

#! format: off
@bounds @describe @units @timescale @with_kw struct rootSurfaceArea_vom{T1,T2,T3} <: rootSurfaceArea
    i_growthmax::T1 = 0.1 | (0.01, 0.5) | "wood related cost" | "" | ""
    i_rootrad::T2 = 3e-04 | (3e-05, 3e-03) | "leaf related cost" | "" | ""
    min_Rsf::T3 = 0.3 | (0.03, 3) | "minimum root surface area" | "m2/m3" | ""
end
#! format: on

@doc """ 
define function is maily used to initialize parameters or variable structure """
function define(params::rootSurfaceArea_vom, forcing, land, helpers)

    ## unpack land variables
    @unpack_rootSurfaceArea_vom params
    @unpack_nt begin
        soilW ⇐ land.pools
        soil_layer_thickness ⇐ land.properties
    end

    @inline function cal_refft(maxval_tmp, root_water_uptake, root_surface_area, changef, soilW)
        refft = (maxval_tmp == 0) ? zero(soilW) : 0.5 .* root_water_uptake ./ root_surface_area ./ maxval_tmp
        refft = ifelse.(root_water_uptake .< 0, 0, refft)
        refft = changef < 0 ? 1 .- refft : refft
        return refft  # from mm to m
    end

    root_surface_area = zero(soilW)
    for sl ∈ eachindex(land.pools.soilW) # RWU occurs in each root layer, not all soil layers
        thick = soil_layer_thickness[sl] / 1000  # from mm to m
        initial_area = min_Rsf * thick
        @rep_elem initial_area ⇒ (root_surface_area, sl, :soilW)
    end

    ## pack land variables
    @pack_nt (root_surface_area) ⇒ land.diagnostics
    @pack_nt (cal_refft) ⇒ land.diagnostics
    return land
end

function compute(params::rootSurfaceArea_vom, forcing, land, helpers)

    ## unpack land variables
    @unpack_rootSurfaceArea_vom params
    @unpack_nt begin
        soilW ⇐ land.pools
        (root_surface_area, plant_water_storage, mdstore) ⇐ land.diagnostics
        (root_water_uptake) ⇐ land.fluxes
        soil_layer_thickness ⇐ land.properties
        (sp_θ_fc, sp_θ_wp) ⇐ land.properties
        cal_refft ⇐ land.diagnostics
        max_root_depth ⇐ land.diagnostics
        (z_zero, o_one, t_two) ⇐ land.constants
    end

    root_layer = ceil(Int, max_root_depth / 500) # each soil layer is 500mm thick
    indices = 1:root_layer

    changef = (0.95 * mdstore - plant_water_storage) / (0.05 * mdstore)
    maxval_tmp = maximum(root_water_uptake[indices] ./ root_surface_area[indices])

    refft = cal_refft(maxval_tmp, root_water_uptake, root_surface_area, changef, soilW)

    for sl ∈ eachindex(land.pools.soilW) # RWU occurs in each root layer, not all soil layers

        if sl ∈ indices

            thick =  soil_layer_thickness[sl] / 1000  # from mm to m
            diff_rsf = root_surface_area[sl] * i_growthmax * changef * refft[sl] * thick
            
            index1 = thick * 2.0 * (sp_θ_fc[sl] - sp_θ_wp[sl]) / i_rootrad

            area_from_layer = min(index1, max(min_Rsf * thick, root_surface_area[sl] + diff_rsf))
        else
            area_from_layer = z_zero
        end
        @rep_elem area_from_layer ⇒ (root_surface_area, sl, :soilW)

    end

    # pack land variables
    @pack_nt (root_surface_area) ⇒ land.diagnostics
    return land
end

@doc """
root surface area from each soil layer is calculated based on VOM methodology
---

# compute:
Root surface area (extract water from soil) using rootSurfaceArea_vom

*Inputs*
 - land.fluxes.root_water_uptake: root_water_uptake
 - land.properties.soil_layer_thickness: soil_layer_thickness
 - land.diagnostics.plant_water_storage: plant_water_storage
 - land.diagnostics.mdstore: maximum plant water storage

*Outputs*
 - land.diagnostics.root_surface_area: root surface area from each soil layer [nZix of soilW], m2/m2

# update

# Extended help

*References*


*Versions*
 - 1.0 on 18.03.2025 [jzhou]

*Created by:*
 - jzhou

*Notes*

"""
rootSurfaceArea_vom
