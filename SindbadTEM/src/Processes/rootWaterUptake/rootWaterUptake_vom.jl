export rootWaterUptake_vom

#! format: off
@bounds @describe @units @timescale @with_kw struct rootWaterUptake_vom{T1,T2,T3,T4,T5,T6,T7,T8} <: rootWaterUptake
    nvg::T1 = 1.56 | (0.0, 20.0) | "n value of the soil hydraulic parameters" | "m" | ""
    Ω_root::T2 = 1.0e09 | (1.0e06, 1.0e09) | "root resistance" | "s m-1" | ""
    p_mpbar::T3 = 10.2 | (0.0, 20.0) | "Conversion coefficient from pressure (bar) to hydraulic head (m)" | "" | ""
    i_rootrad::T4 = 3e-04 | (1e-05, 1e-03) | "root radius" | "m" | ""
    avg::T5 = 3.6 | (0.0, 20.0) | "a value of the soil hydraulic parameters" | "m" | ""
    mdstore::T6 = 300.0 | (50.0, 500.0) | "Maximum plant water storage" | "mm" | ""
    a::T7 = 0.036 | (0.003, 0.3) | "upscale factors from hourly to daily" | "" | ""
    b::T8 = 1.35 | (0.0, 2.0) | "upscale factors from hourly to daily" | "" | ""
end
#! format: on

function define(params::rootWaterUptake_vom, forcing, land, helpers)

    ## unpack land variables
    @unpack_rootWaterUptake_vom params
    @unpack_nt begin
        soilW ⇐ land.pools
        (z_zero, o_one, t_two) ⇐ land.constants
        cVegWood ⇐ land.pools
    end
    
    root_water_uptake = zero(soilW)

    plant_water_storage = mdstore * 0.95

    MM_PER_DAY = 24 * 3600 * 1000

    ## pack land variables
    @pack_nt begin
        root_water_uptake ⇒ land.fluxes
        (plant_water_storage, mdstore, MM_PER_DAY) ⇒ land.diagnostics
    end
    return land
end

function compute(params::rootWaterUptake_vom, forcing, land, helpers)

    ## unpack land variables
    @unpack_rootWaterUptake_vom params
    @unpack_nt begin
        PAW ⇐ land.states
        (soilW, ΔsoilW) ⇐ land.pools
        root_water_uptake ⇐ land.fluxes
        (z_zero, o_one) ⇐ land.constants
        (max_root_depth, MM_PER_DAY)  ⇐ land.diagnostics
        (sp_θ_wp, sp_θ_fc, soil_layer_thickness, sp_θ_sat) ⇐ land.properties
        PT ⇐ land.fluxes
        (root_surface_area, plant_water_storage)  ⇐ land.diagnostics
        root_over ⇐ land.rootWaterEfficiency
    end

    root_layer = sum(root_over .> 0)
    gravity_depth = 0.0

    PT_dis = PT_distribution(params, land, helpers)

    for sl ∈ eachindex(land.pools.soilW) # RWU occurs in each root layer, not all soil layers
        if sl < root_layer # only calculate RWU for the soil layers with roots

            gravity_depth = sum(soil_layer_thickness[1:sl] ./ 1000) - soil_layer_thickness[sl] / 1000 / 2 # from mm to m

            # Volumetric water content, m3/m3, because the remaining soil water metrics are in m3/m3
            # saturated_degree = maxZero(minOne(((soilW[sl] + ΔsoilW[sl]) / soil_layer_thickness[sl] - sp_θ_wp[sl]) / (sp_θ_fc[sl] - sp_θ_wp[sl])))
            θ = (soilW[sl] + ΔsoilW[sl]) / soil_layer_thickness[sl]
            saturated_degree = maxZero(minOne(θ / sp_θ_sat[sl]))
            # @show saturated_degree, θ

            RWU_layer = maxZero(min(PT_dis[sl], PAW[sl]))

            # # we assume that when soil is fully saturated, there is no RWU.
            # if z_zero < saturated_degree < o_one && θ > sp_θ_wp[sl] # only calculate RWU when the soil is not saturated and not lower than wilting point

            #     ψ_soil, ψ_root, Ω_soil, RWU_layer_pot = cal_RWU(params, land, saturated_degree, gravity_depth, sl)

            #     # when Plant has many storaged water, it will be constrained by the potential transpiration. Vice versa.
            #     # if plant_water_storage > 0.92 * mdstore
            #     #     RWU_layer = maxZero(min(RWU_layer_pot * MM_PER_DAY, PT_dis[sl], PAW[sl])) # limit RWU by the potential transpiration from each layer. This is baded on the demand and supply concept.
            #     # else
            #     #     RWU_layer = maxZero(min(RWU_layer_pot * MM_PER_DAY, PAW[sl]))
            #     # end

            #     # RWU_layer = maxZero(min(RWU_layer_pot * MM_PER_DAY, PT_dis[sl], PAW[sl]))
            #     RWU_layer = maxZero(min(PT_dis[sl], PAW[sl]))
                
            #     # if sl == 1
            #     #     @show RWU_layer, RWU_layer_pot * MM_PER_DAY, PT_dis[sl], PT, ψ_soil, ψ_root, saturated_degree, Ω_soil, sp_θ_wp[sl]
            #     # end

            # else
            #     RWU_layer = z_zero
            # end

        else
            RWU_layer = z_zero
        end
        
        # RWU_layer = maxZero(RWU_layer)

        @rep_elem RWU_layer ⇒ (root_water_uptake, sl, :soilW)
        @add_to_elem -root_water_uptake[sl] ⇒ (ΔsoilW, sl, :soilW)
    end

    # pack land variables
    @pack_nt begin
        root_water_uptake ⇒ land.fluxes
        ΔsoilW ⇒ land.pools
    end
    return land
end

function cal_RWU(params::rootWaterUptake_vom, land, saturated_degree, gravity_depth, sl)

    @unpack_rootWaterUptake_vom params
    @unpack_nt begin
        (root_surface_area, plant_water_storage)  ⇐ land.diagnostics
        (sp_k_sat, soil_layer_thickness) ⇐ land.properties
        (z_zero, o_one) ⇐ land.constants
    end

    # soil hydraulic property
    cvg = o_one - o_one/nvg

    ksat = sp_k_sat[sl] * 1.15741e-08 # from mm/day to m/s

    # the upward is positive.

    # soil hydraulic head, m
    ψ_matric = -1 * (saturated_degree ^ (-1 / cvg) - 1) ^ (1 / nvg) / avg
    ψ_gravity = -1 * gravity_depth
    ψ_soil = ψ_matric + ψ_gravity

    # @show plant_water_storage, mdstore
    # root hydraulic head, m
    if plant_water_storage < mdstore
        f = a * log(1 - plant_water_storage / mdstore)  + b # f is used to upcale hourly to daily root water uptake
        mdstore_factor = (750 * mdstore / (mdstore + mdstore)^2 + 1 / mdstore)
        ΔPWS = mdstore - plant_water_storage
        ψ_root = -1 * ΔPWS * mdstore_factor * p_mpbar / f
    else
        ψ_root = z_zero
    end

    # soil resistance, s m-1
    Kunsat = ksat * sqrt(saturated_degree) * (1 - (1 - saturated_degree^(1/cvg))^cvg)^2
    Ω_soil = sqrt(π / 2) * sqrt(i_rootrad * soil_layer_thickness[sl] / 1000 / root_surface_area[sl]) / Kunsat

    if saturated_degree == o_one
        RWU_layer = z_zero
    else
        RWU_layer = maxZero((ψ_soil - ψ_root) * root_surface_area[sl] / (Ω_root + Ω_soil))
    end

    return ψ_soil, ψ_root, Ω_soil, RWU_layer
end

function PT_distribution(params::rootWaterUptake_vom, land, helpers)

    ### the distribution of potential transpiration to each soil layer is calculated based on the Noah-MP default scheme.

    @unpack_rootWaterUptake_vom params
    @unpack_nt begin
        (soilW, ΔsoilW) ⇐ land.pools
        (max_root_depth)  ⇐ land.diagnostics
        PT ⇐ land.fluxes
        (sp_θ_wp, sp_θ_fc, sp_θ_sat, soil_layer_thickness) ⇐ land.properties
        (root_surface_area)  ⇐ land.diagnostics
        root_over ⇐ land.rootWaterEfficiency
    end

    root_layer = sum(root_over .> 0)
    PT_distribution = zeros(root_layer)
    Rsf = sum(root_surface_area[1:root_layer])

    for sl ∈ 1:root_layer
        # Volumetric water content, m3/m3, because the remaining soil water metrics are in m3/m3
        θ = (soilW[sl] + ΔsoilW[sl]) / soil_layer_thickness[sl]
        # saturated_degree = maxZero(minOne(θ / sp_θ_sat[sl]))

        saturated_degree = maxZero(minOne((θ - sp_θ_wp[sl]) / (sp_θ_fc[sl] - sp_θ_wp[sl])))
        if sl == 1
            PT_distribution[sl] = PT * saturated_degree * root_surface_area[sl] / Rsf # total PT
        else
            # PT_distribution[sl] = (PT - sum(PT_distribution[1 : sl-1])) * saturated_degree * root_surface_area[sl] / Rsf # total PT
            PT_distribution[sl] = PT * saturated_degree * root_surface_area[sl] / Rsf # total PT
        end
    end

    return PT_distribution
end

@doc """
rootUptake from each soil layer is a function of water potential difference, resistance from soil and root, and root surface area. And also limited by the potential transpiration (calculated based on Shuttleworth-Wallace dual source model) from each layer.

---

# compute:
Root water uptake (extract water from soil) using rootWaterUptake_vom

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

update pools and diagnostics in rootWaterUptake_vom

 - land.pools.soilW
 - land.diagnostics.plant_water_storage

---

# Extended help

*References*
 - Schymanski, S. J., Sivapalan, M., Roderick, M. L., Beringer, J., & Hutley, L. B. (2008). An optimality-based model of the coupled soil moisture and root dynamics. Hydrology and Earth System Sciences, 12(3), 913–932.
 - Bieri, C. A., Dominguez, F., Miguez-Macho, G. & Fan, Y. Implementing deep soil and dynamic root uptake in Noah-MP (v4.5): impact on Amazon dry-season transpiration. Geoscientific Model Development 18, 3755–3779 (2025).

*Versions*
 - 1.0 on 16.03.2025 [jzhou]

*Created by:*
 - jzhou

*Notes*
 - assumes that the uptake from each layer is a function of water potential difference, resistance from soil and root, and root surface area.
 - change in plant water storage equal to the difference between root water uptake and transpiration
"""
rootWaterUptake_vom
