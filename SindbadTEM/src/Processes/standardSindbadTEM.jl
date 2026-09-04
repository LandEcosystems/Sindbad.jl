export standard_sindbad_model
export all_available_sindbad_model


# List all models of SINDBAD in the order they would be normally be called. 
# ? Let's not do this ? And better be consistent and get the order from the model_structure.json file
# ? But, if we most then, some guidelines of where to include new ones would be helpful.
# When adding a new process, create a new copy of this jl file to work with.
# ? Relying on this hinders the addition of new processes at will by new users.

"""
    standard_sindbad_model


Default ordered list of SINDBAD models
"""
standard_sindbad_model = (:constants, 
    :wCycleBase,
    :rainSnow,
    :rainIntensity,
    :PET,
    :ambientCO2,
    :getPools,
    :soilTexture,
    :soilProperties,
    :soilWBase,
    :PFT,
    :plantForm,
    :EVI,
    :LAI,
    :NDVI,
    :NIRv,
    :NDWI,
    :frozenFraction,
    :vegFraction,
    :treeFraction,
    :fAPAR,
    :rootMaximumDepth,
    :rootWaterEfficiency,
    :snowFraction,
    :sublimation,
    :snowMelt,
    :interception,
    :runoffInfiltrationExcess,
    :saturatedFraction,
    :runoffSaturationExcess,
    :runoffInterflow,
    :runoffOverland,
    :runoffSurface,
    :runoffBase,
    :percolation,
    :evaporation,
    :drainage,
    :capillaryFlow,
    :groundWRecharge,
    :groundWSoilWInteraction,
    :groundWSurfaceWInteraction,
    :transpirationDemand,
    :vegAvailableWater,
    :transpirationSupply,
    :gppPotential,
    :gppDiffRadiation,
    :gppDirRadiation,
    :gppAirT,
    :gppVPD,
    :gppSoilW,
    :gppDemand,
    :WUE,
    :gpp,
    :transpiration,
    :rootWaterUptake,
    :cVegetationDieOff,
    :cFireBurnedArea,
    :cFireCombustionCompleteness,
    :cFireMortality,
    :cCycleBase,
    :metabolicFraction,
    :lignin,
    :cMicrobialEfficiencycLit,
    :cMicrobialEfficiencycMic,
    :cMicrobialEfficiencycSoil,
    :cMicrobialEfficiency,
    :cQualityPartitionMetabolicFraction,
    :cQualityPartitionLignin,
    :cQualityPartitionSoilProperties,
    :cQualityPartition,
    :cCycleDisturbance,
    :cCropHarvestIntensity,
    :cCropHarvestEfficiency,
    :cForestryHarvestIntensity,
    :cForestryHarvestEfficiency,
    :cCycleManagement,
    :cTauSoilT,
    :cTauSoilW,
    :cTauLAI,
    :cTauSoilProperties,
    :cTauVegProperties,
    :cTau,
    :autoRespirationAirT,
    :cAllocationLAI,
    :cAllocationRadiation,
    :cAllocationSoilW,
    :cAllocationSoilT,
    :cAllocationNutrients,
    :cAllocation,
    :cAllocationTreeFraction,
    :autoRespiration,
    :cFlow,
    :cCycleConsistency,
    :cCycle,
    :evapotranspiration,
    :runoff,
    :wCycle,
    :waterBalance,
    :cBiomass,
    :deriveVariables)

"""
a tuple of all available SINDBAD models
"""
all_available_sindbad_model = Tuple(subtypes(LandEcosystem))



"""
    getSindbadModelOrder(model_name; all_models=standard_sindbad_model)

Return the default order of a SINDBAD model in the model list.

# Arguments
- `model_name`: Name of the model
- `all_models`: The list of all models (default: `standard_sindbad_model`)

# Examples
```jldoctest
julia> # Get the order of a model
julia> # getSindbadModelOrder(:gpp)
```
"""
function getSindbadModelOrder(model_name; all_models=standard_sindbad_model)
    mo = findall(x -> x == model_name, all_models)[1]
    println("The order [default] of $(model_name) in models.jl of core SINDBAD is $(mo)")
end

"""
    getSindbadModels(; all_models=standard_sindbad_model)

Return a dictionary of SINDBAD models and their approaches.

# Arguments
- `all_models`: The list of all models (default: `standard_sindbad_model`)

# Returns
- An `OrderedDict` mapping model names to lists of approach names

# Examples
```jldoctest
julia> # Get all models and approaches
julia> # models_dict = getSindbadModels()
```
"""
function getSindbadModels(; all_models=standard_sindbad_model)
    approaches = []
    for _md ∈ all_models
        push!(approaches, Pair(_md, [nameof(_x) for _x in subtypes(getfield(SindbadTEM.Processes, _md))]))
    end
    return DataStructures.OrderedDict(approaches)
end

