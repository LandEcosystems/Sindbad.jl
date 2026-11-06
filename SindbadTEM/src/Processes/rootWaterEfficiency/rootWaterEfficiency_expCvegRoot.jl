export rootWaterEfficiency_expCvegRoot

#! format: off
@bounds @describe @units @timescale @with_kw struct rootWaterEfficiency_expCvegRoot{T1,T2,T3} <: rootWaterEfficiency
    k_efficiency_cVegRoot::T1 = 0.02 | (0.001, 0.3) | "rate constant of exponential relationship" | "m2/gC" | ""
    max_root_water_efficiency::T2 = 0.95 | (0.7, 0.98) | "maximum root water uptake capacity" | "" | ""
    min_root_water_efficiency::T3 = 0.1 | (0.05, 0.3) | "minimum root water uptake threshold" | "" | ""
end
#! format: on

function define(params::rootWaterEfficiency_expCvegRoot, forcing, land, helpers)
    @unpack_rootWaterEfficiency_expCvegRoot params
    @unpack_nt begin
        soilW ⇐ land.pools
    end
    ## Instantiate variables
    root_water_efficiency = one.(soilW)
    rooted_fraction = one.(soilW)
    ## pack land variables
    @pack_nt begin
        rooted_fraction ⇒ land.rootWaterEfficiency
        root_water_efficiency ⇒ land.diagnostics
    end
    return land
end

function precompute(params::rootWaterEfficiency_expCvegRoot, forcing, land, helpers)
    ## unpack parameters
    @unpack_rootWaterEfficiency_expCvegRoot params
    ## unpack land variables
    @unpack_nt begin
        rooted_fraction ⇐ land.rootWaterEfficiency
        (cumulative_soil_depths, soil_layer_thickness) ⇐ land.properties
        z_zero ⇐ land.constants
        max_root_depth ⇐ land.diagnostics
        soilW ⇐ land.pools
    end
    # one above the root depth, the rooted fraction of the layer holding it, and
    # zero below
    for sl ∈ eachindex(soilW)
        soilcumuD = sl == 1 ? z_zero : cumulative_soil_depths[sl-1]
        rootOver = max_root_depth - soilcumuD
        rootEff = clamp_zero_one(rootOver / soil_layer_thickness[sl])
        @rep_elem rootEff ⇒ (rooted_fraction, sl)
    end
    ## pack land variables
    @pack_nt rooted_fraction ⇒ land.rootWaterEfficiency
    return land
end

function compute(params::rootWaterEfficiency_expCvegRoot, forcing, land, helpers)
    ## unpack parameters
    @unpack_rootWaterEfficiency_expCvegRoot params
    ## unpack land variables
    @unpack_nt begin
        rooted_fraction ⇐ land.rootWaterEfficiency
        root_water_efficiency ⇐ land.diagnostics
        (cEco, soilW) ⇐ land.pools
    end
    ## calculate variables
    tmp_rootEff = max_root_water_efficiency -
                  (max_root_water_efficiency - min_root_water_efficiency) * (exp(-k_efficiency_cVegRoot * totalS_indices(cEco, helpers.pools.zix.cVegRoot))) # root fraction/efficiency as a function of total carbon in root pools

    for sl ∈ eachindex(soilW)
        root_water_efficiency_sl = rooted_fraction[sl] * tmp_rootEff
        @rep_elem root_water_efficiency_sl ⇒ (root_water_efficiency, sl)
    end
    ## pack land variables
    @pack_nt root_water_efficiency ⇒ land.diagnostics
    return land
end

purpose(::Type{rootWaterEfficiency_expCvegRoot}) = "Water uptake efficiency by roots set according to total root carbon."

@doc """

$(getModelDocString(rootWaterEfficiency_expCvegRoot))

---

# Extended help

*References*

*Versions*
 - 1.0 on 28.04.2020  
 - 1.1 on 02.11.2026 [skoirala | @dr-ko]: the layer holding the root depth counts
   with its rooted fraction

*Created by*
 - skoirala | @dr-ko
"""
rootWaterEfficiency_expCvegRoot
