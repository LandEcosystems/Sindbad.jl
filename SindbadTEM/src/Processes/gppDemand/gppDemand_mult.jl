export gppDemand_mult

struct gppDemand_mult <: gppDemand end

function define(params::gppDemand_mult, forcing, land, helpers)
    @unpack_nt f_VPD_day ⇐ forcing
    gpp_climate_stressors = ones(typeof(f_VPD_day), 4)

    if hasproperty(land.pools, :soilW)
        @unpack_nt soilW ⇐ land.pools
        if soilW isa SVector
            gpp_climate_stressors = SVector{4}(gpp_climate_stressors)
        end
    end

    @pack_nt gpp_climate_stressors ⇒ land.diagnostics

    return land
end

function compute(params::gppDemand_mult, forcing, land, helpers)

    ## unpack land variables
    @unpack_nt begin
        gpp_f_cloud ⇐ land.diagnostics
        fAPAR ⇐ land.states
        gpp_potential ⇐ land.diagnostics
        gpp_f_light ⇐ land.diagnostics
        gpp_climate_stressors ⇐ land.diagnostics
        gpp_f_airT ⇐ land.diagnostics
        gpp_f_vpd ⇐ land.diagnostics
    end

    # set 3d scalar matrix with current scalars
    gpp_climate_stressors = repElem(gpp_climate_stressors, gpp_f_airT, 1)
    gpp_climate_stressors = repElem(gpp_climate_stressors, gpp_f_vpd, 2)
    gpp_climate_stressors = repElem(gpp_climate_stressors, gpp_f_light, 3)
    gpp_climate_stressors = repElem(gpp_climate_stressors, gpp_f_cloud, 4)

    # compute the product of all the scalars
    gpp_f_climate = gpp_f_light * gpp_f_cloud * gpp_f_airT * gpp_f_vpd

    # compute demand GPP
    gpp_demand = fAPAR * gpp_potential * gpp_f_climate

    ## pack land variables
    @pack_nt (gpp_climate_stressors, gpp_f_climate, gpp_demand) ⇒ land.diagnostics
    return land
end

purpose(::Type{gppDemand_mult}) = "Demand GPP as the product of all stress scalars."

@doc """

$(getModelDocString(gppDemand_mult))

---

# Extended help

*References*

*Versions*
 - 1.0 on 22.11.2019 [skoirala | @dr-ko]: documentation & clean up  

*Created by*
 - ncarvalhais

*Notes*
"""
gppDemand_mult
