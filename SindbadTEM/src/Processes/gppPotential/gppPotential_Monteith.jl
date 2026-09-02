export gppPotential_Monteith

#! format: off
@bounds @describe @units @timescale @with_kw struct gppPotential_Monteith{T1} <: gppPotential
    εmax::T1 = 1.0 | (0.637, 3.2) | "Maximum Radiation Use Efficiency" | "gC/MJ" | ""
end
#! format: on

function compute(params::gppPotential_Monteith, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppPotential_Monteith params
    @unpack_nt f_PAR ⇐ forcing

    ## calculate variables
    # set rueGPP to a constant
    gpp_potential = εmax * f_PAR

    ## pack land variables
    @pack_nt gpp_potential ⇒ land.diagnostics
    return land
end

purpose(::Type{gppPotential_Monteith}) = "Potential GPP based on radiation use efficiency model/concept of Monteith."

@doc """

$(getModelDocString(gppPotential_Monteith))

---

# Extended help

*References*

*Versions*
 - 1.0 on 22.11.2019 [skoirala | @dr-ko]: documentation & clean up

*Created by*
 - mjung
 - ncarvalhais

*Notes*
 - no crontrols for fPAR | meteo factors
 - set the potential GPP as maxRUE * f_PAR [gC/m2/dat]
 - usually  GPP = e_max x f[clim] x FAPAR x f_PAR  here  GPP = GPPpot x f[clim] x FAPAR  GPPpot = e_max x f_PAR  f[clim] & FAPAR are [maybe] calculated dynamically
"""
gppPotential_Monteith
