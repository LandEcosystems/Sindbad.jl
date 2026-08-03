export gppDemand_min

struct gppDemand_min <: gppDemand end

function define(params::gppDemand_min, forcing, land, helpers)
    @unpack_nt begin
        land_pools = pools ⇐ land 
        gpp_potential ⇐ land.diagnostics
    end

    gpp_climate_stressors = ones(typeof(gpp_potential), 4)
    if hasproperty(land_pools, :soilW)
        @unpack_nt soilW ⇐ land.pools
        if soilW isa SVector
            gpp_climate_stressors = SVector{4}(gpp_climate_stressors)
        end
    end

    @pack_nt gpp_climate_stressors ⇒ land.diagnostics

    return land
end

function compute(params::gppDemand_min, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        fAPAR ⇐ land.states
        (gpp_f_cloud, gpp_potential, gpp_f_light, gpp_climate_stressors, gpp_f_airT, gpp_f_vpd) ⇐ land.diagnostics
    end

    # set 3d scalar matrix with current scalars
    gpp_climate_stressors = repElem(gpp_climate_stressors, gpp_f_airT, gpp_climate_stressors, gpp_climate_stressors, 1)
    gpp_climate_stressors = repElem(gpp_climate_stressors, gpp_f_vpd, gpp_climate_stressors, gpp_climate_stressors, 2)
    gpp_climate_stressors = repElem(gpp_climate_stressors, gpp_f_light, gpp_climate_stressors, gpp_climate_stressors, 3)
    gpp_climate_stressors = repElem(gpp_climate_stressors, gpp_f_cloud, gpp_climate_stressors, gpp_climate_stressors, 4)

    # compute the minumum of all the scalars
    gpp_f_climate = minimum(gpp_climate_stressors)

    # compute demand GPP
    gpp_demand = fAPAR * gpp_potential * gpp_f_climate

    ## pack land variables
    @pack_nt (gpp_f_climate, gpp_demand) ⇒ land.diagnostics
    return land
end

purpose(::Type{gppDemand_min}) = "Demand GPP as the minimum of all stress scalars (most limiting factor)."

@doc """

$(getModelDocString(gppDemand_min))

---

# Extended help

*References*

*Versions*
 - 1.0 on 22.11.2019 [skoirala | @dr-ko]: documentation & clean up  

*Created by*
 - ncarvalhais

*Notes*
"""
gppDemand_min
