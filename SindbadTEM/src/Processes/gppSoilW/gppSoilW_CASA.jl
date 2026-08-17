export gppSoilW_CASA

#! format: off
@bounds @describe @units @timescale @with_kw struct gppSoilW_CASA{T1} <: gppSoilW
    base_f_soilW::T1 = 0.2 | (0, 1) | "base water stress" | "" | ""
end
#! format: on

function define(params::gppSoilW_CASA, forcing, land, helpers)
    ## unpack parameters and forcing
    ## unpack land variables
    @unpack_nt begin
        z_zero ⇐ land.constants
    end
    gpp_f_soilW_prev = z_zero

    ## pack land variables
    @pack_nt gpp_f_soilW_prev ⇒ land.diagnostics
    return land
end

function compute(params::gppSoilW_CASA, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppSoilW_CASA params
    @unpack_nt f_airT ⇐ forcing

    ## unpack land variables
    @unpack_nt begin
        gpp_f_soilW_prev ⇐ land.diagnostics
        PAW ⇐ land.states
        PET ⇐ land.fluxes
        (z_zero, o_one) ⇐ land.constants
    end

    OmBweOPET = (o_one - base_f_soilW) / PET

    We = base_f_soilW + OmBweOPET * sum(PAW) #@needscheck: originally, transpiration was used here but that does not make sense, as it is not calculated yet for this time step. This has been replaced by sum of plant available water.

    gpp_f_soilW = clamp_zero_one(ifelse((f_airT > z_zero) & (PET > z_zero), We, gpp_f_soilW_prev)) # use the current We if the temperature and PET are favorable, else use the previous one.

    gpp_f_soilW_prev = gpp_f_soilW

    ## pack land variables
    @pack_nt (OmBweOPET, gpp_f_soilW, gpp_f_soilW_prev) ⇒ land.diagnostics
    return land
end


purpose(::Type{gppSoilW_CASA}) = "Soil moisture stress on GPP potential based on base stress and the relative ratio of PET and PAW (CASA)."

@doc """

$(getModelDocString(gppSoilW_CASA))

---

# Extended help

*References*
 - Forkel; M.; Carvalhais; N.; Schaphoff; S.; v. Bloh; W.; Migliavacca; M.  Thurner; M.; & Thonicke; K.: Identifying environmental controls on  vegetation greenness phenology through model–data integration  Biogeosciences; 11; 7025–7050; https://doi.org/10.5194/bg-11-7025-2014;2014.

*Versions*
 - 1.1 on 22.01.2021 [skoirala | @dr-ko]

*Created by*
 - skoirala | @dr-ko

*Notes*
"""
gppSoilW_CASA
