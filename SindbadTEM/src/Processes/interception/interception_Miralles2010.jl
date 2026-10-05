export interception_Miralles2010

#! format: off
@bounds @describe @units @timescale @with_kw struct interception_Miralles2010{T1,T2,T3,T4,T5} <: interception
    canopy_storage::T1 = 1.2 | (0.4, 2.0) | "Canopy storage" | "mm" | ""
    fte::T2 = 0.02 | (0.02, 0.02) | "fraction of trunk evaporation" | "" | ""
    evap_rate::T3 = 0.3 | (0.1, 0.5) | "mean evaporation rate" | "mm/hr" | ""
    trunk_capacity::T4 = 0.02 | (0.02, 0.02) | "trunk capacity" | "mm" | ""
    pd::T5 = 0.02 | (0.02, 0.02) | "fraction rain to trunks" | "" | ""
end
#! format: on

function compute(params::interception_Miralles2010, forcing, land, helpers)
    ## unpack parameters
    @unpack_interception_Miralles2010 params

    ## unpack land variables
    @unpack_nt begin
        (WBP, fAPAR) ⇐ land.states
        rain ⇐ land.fluxes
        rain_int ⇐ land.states
    end
    tmp = 1.0
    canopy_storage = canopy_storage * tmp
    fte = fte * tmp
    evap_rate = evap_rate * tmp
    trunk_capacity = trunk_capacity * tmp
    pd = pd * tmp
    #catch for division by zero
    valids = rain_int > 0.0 & fAPAR > 0.0
    Pgc = 0.0
    Pgt = 0.0
    Ic = 0.0
    Ic1 = 0.0
    Ic2 = 0.0
    It2 = 0.0
    It = 0.0
    #f_rain intensity must be larger than evap rate
    #adjusting evap rate:
    v = rain_int < evap_rate & valids == 1
    evap_rate[v] = rain_int[v]
    #Pgc: amount of gross rainfall necessary to saturate the canopy
    Pgc =
        -1 *
        (rain_int * canopy_storage / ((1.0 - fte) * evap_rate)) *
        log(1.0 - ((1.0 - fte) * evap_rate / rain_int))
    #Pgt: amount of gross rainfall necessary to saturate the trunks
    Pgt = Pgc + rain_int * trunk_capacity / (pd * fAPAR * (rain_int - evap_rate * (1.0 - fte)))
    #Ic: interception loss from canopy
    Ic1 = fAPAR * rain #Pg < Pgc
    Ic2 = fAPAR * (Pgc + ((1.0 - fte) * evap_rate / rain_int) * (rain - Pgc)) #Pg > Pgc
    v = rain <= Pgc & valids == 1
    Ic[v] = Ic1[v]
    Ic[v==0] = Ic2[v==0]
    #It: interception loss from trunks
    #It1 = trunk_capacity;# Pg < Pgt
    It2 = pd * fAPAR * (1.0 - (1.0 - fte) * evap_rate / rain_int) * (rain - Pgc)#Pg > Pgt
    v = rain <= Pgt
    It[v] = trunk_capacity[v]
    It[v==0] = It2[v==0]
    tmp = Ic + It
    tmp[rain==0.0] = 0.0
    v = tmp > rain
    tmp[v] = rain[v]
    interception = tmp
    # update the water budget pool
    WBP = WBP - interception

    ## pack land variables
    @pack_nt begin
        interception ⇒ land.fluxes
        WBP ⇒ land.states
    end
    return land
end

purpose(::Type{interception_Miralles2010}) = "Interception loss according to the Gash model of Miralles, 2010."

@doc """

$(getModelDocString(interception_Miralles2010))

---

# Extended help

*References*
 - Miralles, D. G., Gash, J. H., Holmes, T. R., de Jeu, R. A., & Dolman, A. J. (2010).  Global canopy interception from satellite observations. Journal of Geophysical ResearchAtmospheres, 115[D16].

*Versions*
 - 1.0 on 18.11.2019 [ttraut]: cleaned up the code
 - 1.1 on 22.11.2019 [skoirala | @dr-ko]: handle land.states.fAPAR, rainfall intensity & rainfall  

*Created by*
 - mjung

*Notes*
"""
interception_Miralles2010
