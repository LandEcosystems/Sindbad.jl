export gppVPD_PRELES

#! format: off
@bounds @describe @units @timescale @with_kw struct gppVPD_PRELES{T1,T2,T3,T4} <: gppVPD
    # κ::T1 = 0.4 | (0.06, 0.7) | "" | "kPa-1" | ""
    # c_κ::T2 = 0.4 | (-50.0, 10.0) | "" | "" | ""
    κ::T1 = 0.05 | (0.01, 10.0) | "" | "kPa-1" | ""
    c_κ::T2 = 0.4 | (0.0, 10.0) | "" | "" | ""
    base_ambient_CO2::T3 = 380.0 | (340.0, 390.0) | "" | "ppm" | ""
    sat_ambient_CO2::T4 = 2000.0 | (100.0, 4000.0) | "" | "ppm" | ""
end
#! format: on

function compute(params::gppVPD_PRELES, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppVPD_PRELES params
    @unpack_nt f_VPD_day ⇐ forcing

    ## unpack land variables
    @unpack_nt begin
        ambient_CO2 ⇐ land.states
        o_one ⇐ land.constants
    end
    # fVPD_VPD                    = exp(p.gppfVPD.kappa .* -f.f_VPD_day(:,tix) .* (p.gppfVPD.base_ambient_CO2 ./ s.cd.ambCO2) .^ -p.gppfVPD.Ckappa);
    # fCO2_CO2                    = 1 + (s.cd.ambCO2 - p.gppfVPD.base_ambient_CO2) ./ (s.cd.ambCO2 - p.gppfVPD.base_ambient_CO2 + p.gppfVPD.sat_ambient_CO2);
    # VPDScGPP                    = max(0, min(1, fVPD_VPD .* fCO2_CO2));
    # d.gppfVPD.VPDScGPP(:,tix)	= VPDScGPP;

    ## calculate variables
    fVPD_VPD = exp(-κ * f_VPD_day * (base_ambient_CO2 / ambient_CO2)^-c_κ)
    fCO2_CO2 = o_one + (ambient_CO2 - base_ambient_CO2) / (ambient_CO2 - base_ambient_CO2 + sat_ambient_CO2)
    # gpp_f_vpd = clamp_zero_one(fVPD_VPD * fCO2_CO2)
    gpp_f_vpd = fVPD_VPD * fCO2_CO2

    ## pack land variables
    @pack_nt fVPD_VPD ⇒ land.diagnostics
    @pack_nt gpp_f_vpd ⇒ land.diagnostics
    return land
end

purpose(::Type{gppVPD_PRELES}) = "VPD stress on GPP potential based on Maekelae (2008) and includes the CO₂ effect based on the PRELES model."

@doc """

$(getModelDocString(gppVPD_PRELES))

---

# Extended help

*References*
 - Mäkelä, A., Pulkkinen, M., Kolari, P., et al. (2008).  Developing an empirical model of stand GPP with the LUE approachanalysis of eddy covariance data at five contrasting conifer sites in  Europe. Global change biology, 14[1], 92-108.
 - http://www.metla.fi/julkaisut/workingpapers/2012/mwp247.pdf

*Versions*
 - 1.1 on 22.11.2020 [skoirala | @dr-ko]: changing units to kpa for vpd & sign of  κ to match with Maekaelae2008  

*Created by*
 - ncarvalhais

*Notes*
 - sign of exponent is changed to have κ parameter as positive values
"""
gppVPD_PRELES
