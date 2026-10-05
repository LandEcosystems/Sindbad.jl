export cCycleManagement_simple

#! format: off
struct cCycleManagement_simple <: cCycleManagement end
#! format: on

function define(params::cCycleManagement_simple, forcing, land, helpers)
    @unpack_nt cEco ⇐ land.pools
    @unpack_nt c_taker ⇐ land.cCycleBase

    # initialize management outputs
    c_Crop_Harvest_Product = zero(cEco)
    c_Crop_Harvest_Mortality = zero(cEco)
    c_Crop_Harvest_Flow = zero(cEco)

    c_Wood_Harvest_Product = zero(cEco)
    c_Wood_Harvest_Mortality = zero(cEco)
    c_Wood_Harvest_Flow = zero(cEco)

    @pack_nt begin 
        (c_Crop_Harvest_Product, c_Crop_Harvest_Mortality, c_Crop_Harvest_Flow) ⇒ land.diagnostics
        (c_Wood_Harvest_Product, c_Wood_Harvest_Mortality, c_Wood_Harvest_Flow) ⇒ land.diagnostics
    end
    return land
end

function compute(params::cCycleManagement_simple, forcing, land, helpers)
    ## unpack disturbance variables
    @unpack_nt begin
        (c_Crop_Harvest_Product, c_Crop_Harvest_Mortality, c_Crop_Harvest_Flow, cCropProducts) ⇐ land.diagnostics
        (c_Wood_Harvest_Product, c_Wood_Harvest_Mortality, c_Wood_Harvest_Flow, cWoodProducts) ⇐ land.diagnostics
        cEco ⇐ land.pools
        zix ⇐ helpers.pools
        c_model ⇐ land.models
    end

    for cl ∈ eachindex(cEco)
        δManagement = (
            (c_Wood_Harvest_Flow[cl] - c_Wood_Harvest_Mortality[cl]) +
            (c_Crop_Harvest_Flow[cl] - c_Crop_Harvest_Mortality[cl])
        )
        cEco_cl = cEco[cl] + δManagement
        @rep_elem cEco_cl ⇒ (cEco, cl)
    end

    @pack_nt cEco ⇒ land.pools
    land = adjustPackPoolComponents(land, helpers, c_model)

    ## pack land variables
    return land
end

purpose(::Type{cCycleManagement_simple}) = "This is used for crop and forestry harvest events. Moves carbon to export and decomposable pools, according to their respective carbon flow target pools, during harvest events."

@doc """

$(getModelDocString(cCycleManagement_simple))

---

# Extended help

*Created by*
    - Nuno | nunocarvalhais
"""
cCycleManagement_simple
