export rootWaterUptake_NoahMP

struct rootWaterUptake_NoahMP <: rootWaterUptake end

function define(params::rootWaterUptake_NoahMP, forcing, land, helpers)

    ## unpack land variables
    # @unpack_rootWaterUptake_NoahMP params
    @unpack_nt soilW ⇐ land.pools
    
    root_water_uptake = zero(soilW)

    ## pack land variables
    @pack_nt root_water_uptake ⇒ land.fluxes
    return land
end

function compute(params::rootWaterUptake_NoahMP, forcing, land, helpers)

    ## unpack land variables
    # @unpack_rootWaterUptake_NoahMP params
    @unpack_nt begin
        PAW ⇐ land.states
        (soilW, ΔsoilW) ⇐ land.pools
        root_water_uptake ⇐ land.fluxes
        (z_zero, o_one) ⇐ land.constants
        root_over ⇐ land.rootWaterEfficiency
    end

    root_layer = sum(root_over .> 0)
    PT_dis = PT_distribution(params, land, helpers)

    for sl ∈ eachindex(land.pools.soilW) # RWU occurs in each root layer, not all soil layers
        if sl < root_layer # only calculate RWU for the soil layers with roots

            RWU_layer = maxZero(min(PT_dis[sl], PAW[sl]))

        else
            RWU_layer = z_zero
        end

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

function PT_distribution(params::rootWaterUptake_NoahMP, land, helpers)

    ### the distribution of potential transpiration to each soil layer is calculated based on the Noah-MP default scheme.

    # @unpack_rootWaterUptake_NoahMP params
    @unpack_nt begin
        (soilW, ΔsoilW) ⇐ land.pools
        # PT ⇐ land.fluxes
        PET ⇐ land.fluxes
        (sp_θ_wp, sp_θ_fc, soil_layer_thickness) ⇐ land.properties
        (root_surface_area)  ⇐ land.diagnostics
        root_over ⇐ land.rootWaterEfficiency
        fAPAR ⇐ land.states
    end
    
    PT = PET * fAPAR # potential transpiration, mm/day
    root_layer = sum(root_over .> 0)
    PT_distribution = zeros(root_layer)
    Rsf = sum(root_surface_area[1:root_layer])

    for sl ∈ 1:root_layer
        # Volumetric water content, m3/m3, because the remaining soil water metrics are in m3/m3
        θ = (soilW[sl] + ΔsoilW[sl]) / soil_layer_thickness[sl]

        saturated_degree = maxZero(minOne((θ - sp_θ_wp[sl]) / (sp_θ_fc[sl] - sp_θ_wp[sl])))
        PT_distribution[sl] = PT * saturated_degree * root_surface_area[sl] / Rsf # total PT
    end

    return PT_distribution
end

@doc """
RWU from each soil layer is a function of the potential transpiration (calculated based on Shuttleworth-Wallace dual source model) and root surface area from each layer.

---

# compute:
Root water uptake (extract water from soil) using rootWaterUptake_NoahMP

# update

---

# Extended help

*References*
 - 1. Wang, P. et al. Implementing Dynamic Root Optimization in Noah-MP for Simulating Phreatophytic Root Water Uptake. Water Resources Research 54, 1560–1575 (2018).
 - 2. Niu, G.-Y. et al. The community Noah land surface model with multiparameterization options (Noah-MP): 1. Model description and evaluation with local-scale measurements. Journal of Geophysical Research: Atmospheres 116, (2011).
 - 3. Bieri, C. A., Dominguez, F., Miguez-Macho, G. & Fan, Y. Implementing deep soil and dynamic root uptake in Noah-MP (v4.5): impact on Amazon dry-season transpiration. Geoscientific Model Development 18, 3755–3779 (2025).

*Versions*
 - 1.0 on 24.08.2025 [jzhou]

*Created by:*
 - jzhou

*Notes*
 - assumes that the uptake from each layer is a function of water potential difference, resistance from soil and root, and root surface area.
 - change in plant water storage equal to the difference between root water uptake and transpiration
"""
rootWaterUptake_NoahMP
