export rootWaterUptake_IBIS

#! format: off
@bounds @describe @units @timescale @with_kw struct rootWaterUptake_IBIS{T1,T2} <: rootWaterUptake
    sf::T1 = -5 | (-10, 0) | "" | "" | ""
    mdstore::T2 = 94.5 | (50.0, 500.0) | "Maximum plant water storage" | "mm" | ""
end
#! format: on

function define(params::rootWaterUptake_IBIS, forcing, land, helpers)

    ## unpack land variables
    @unpack_rootWaterUptake_IBIS params
    @unpack_nt cVegWood ⇐ land.pools
    @unpack_nt begin
        soilW ⇐ land.pools
        cEco ⇐ land.pools
        (z_zero, o_one, t_two) ⇐ land.constants
    end
    
    root_water_uptake = zero(soilW)

    plant_water_storage = mdstore * 0.95

    ## pack land variables
    @pack_nt begin
        root_water_uptake ⇒ land.fluxes
        plant_water_storage ⇒ land.diagnostics
        mdstore ⇒ land.diagnostics
    end
    return land
end

function compute(params::rootWaterUptake_IBIS, forcing, land, helpers)

    ## unpack land variables
    @unpack_rootWaterUptake_IBIS params
    @unpack_nt begin
        PAW ⇐ land.states
        (soilW, ΔsoilW) ⇐ land.pools
        root_water_uptake ⇐ land.fluxes
        (root_surface_area, plant_water_storage, mdstore) ⇐ land.diagnostics
        (sp_θ_wp, sp_θ_fc) ⇐ land.properties
        soil_layer_thickness ⇐ land.properties
        max_root_depth ⇐ land.diagnostics
        transpiration_demand ⇐ land.diagnostics
    end

    root_layer = ceil(Int, max_root_depth / 500) # each soil layer is 500mm thick
    indices = 1:root_layer

    θ = soilW ./ soil_layer_thickness
    if all(θ[1 : ceil(Int, root_layer / 3)] .< 0.2) && all(θ[ceil(Int, root_layer / 3) + 1 : root_layer] .> 0.5)
        λ = 0.50
    elseif all(θ[1 : ceil(Int, root_layer / 3)] .< 0.2) && all(0.2 .< θ[ceil(Int, root_layer / 3) + 1 : root_layer] .< 0.5)
        λ = 0.75
    elseif all(0.2 .< θ[1 : ceil(Int, root_layer / 3)] .< 0.5) && all(θ[ceil(Int, root_layer / 3) + 1 : root_layer] .> 0.5)
        λ = 0.75
    elseif all(0.2 .< θ[1 : ceil(Int, root_layer / 3)] .< 0.5) && all(θ[ceil(Int, root_layer / 3) + 1 : root_layer] .< 0.2)
        λ = 1.25
    elseif all(θ[1 : ceil(Int, root_layer / 3)] .> 0.5) && all(0.2 .< θ[ceil(Int, root_layer / 3) + 1 : root_layer] .< 0.5)
        λ = 1.25
    elseif all(θ[1 : ceil(Int, root_layer / 3)] .> 0.5) && all(θ[ceil(Int, root_layer / 3) + 1 : root_layer] .< 0.2)
        λ = 1.50
    else
        λ = 1.0
    end

    θa = zeros(length(indices))
    for i ∈ eachindex(indices)
        if sp_θ_wp[i] < θ[i] < sp_θ_fc[i]
            θa[i] = (θ[i] - sp_θ_wp[i]) / (sp_θ_fc[i] - sp_θ_wp[i])
        elseif θ[i] >= sp_θ_fc[i]
            θa[i] = 1.0
        else
            θa[i] = 0.0
        end
    end

    if all(θa .== 0.0)
        for sl ∈ eachindex(land.pools.soilW)
            RWU_layer = 0.0
            @rep_elem RWU_layer ⇒ (root_water_uptake, sl, :soilW)
            @add_to_elem -root_water_uptake[sl] ⇒ (ΔsoilW, sl, :soilW)
        end
    else

        W = (1 .- exp.(sf .* θa)) ./ (1 .- exp.(sf)) # sf is the scaling factor, sf = -5 for the soil hydraulic parameters
        Rsf = sum(root_surface_area[indices]) # total root surface area, m2/m2
        R = root_surface_area[indices] ./ Rsf # root surface area density, m2/m2

        for sl ∈ eachindex(land.pools.soilW) # RWU occurs in each root layer, not all soil layers
            if sl ∈ indices
                Fi = maxZero(R[sl] .^ λ .* W[sl] ./ sum(R .^ λ .* W)) # RWU fraction in each soil layer, Fi = R^λ * W / Σ(R^λ * W)
                RWU_layer = min(Fi * transpiration_demand, PAW[sl]) # mm day⁻¹
            else
                RWU_layer = 0.0
            end
            @rep_elem RWU_layer ⇒ (root_water_uptake, sl, :soilW)
            @add_to_elem -root_water_uptake[sl] ⇒ (ΔsoilW, sl, :soilW)
        end
    end

    # pack land variables
    @pack_nt begin
        root_water_uptake ⇒ land.fluxes
        ΔsoilW ⇒ land.pools
    end
    return land
end

@doc """
rootUptake from each soil layer is a function of water potential difference, resistance from soil and root, and root surface area.

---

# compute:
Root water uptake (extract water from soil) using rootWaterUptake_IBIS

*Inputs*
 - land.pools.soilW: soil moisture
 - land.states.PAW: plant available water
 - land.properties.w_awc: maximum soil water content
 - land.properties.sp_k_sat: soil hydraulic conductivity at saturation
 - land.properties.sp_θ_sat: soil matric porosity at saturation
 - land.properties.sp_ψ_sat: soil matric potention at saturation
  - land.properties.sp_β: properties of moisture-retention curves
 - land.diagnostics.root_surface_area: root surface area
 - land.diagnostics.plant_water_storageat: plant water storage

*Outputs*
 - land.states.root_water_uptake: moisture uptake from each soil layer [nZix of soilW]

# update

update pools and diagnostics in rootWaterUptake_IBIS

 - land.pools.soilW
 - land.diagnostics.plant_water_storage

---

# Extended help

*References*
Schymanski, S. J., Sivapalan, M., Roderick, M. L., Beringer, J., & Hutley, L. B. (2008). An optimality-based model of the coupled soil moisture and root dynamics. Hydrology and Earth System Sciences, 12(3), 913–932.


*Versions*
 - 1.0 on 16.03.2025 [jzhou]

*Created by:*
 - jzhou

*Notes*
 - assumes that the uptake from each layer is a function of water potential difference, resistance from soil and root, and root surface area.
 - change in plant water storage equal to the difference between root water uptake and transpiration
"""
rootWaterUptake_IBIS
