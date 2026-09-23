export sublimation_GLEAM

#! format: off
@bounds @describe @units @timescale @with_kw struct sublimation_GLEAM{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,T15,T16,T17,T18} <: sublimation
    α::T1 = 0.95 | (0.0, 3.0) | "Priestley Taylor Coefficient for Sublimation" | "none" | ""
    deg_to_k::T2 = 273.15 | (-Inf, Inf) | "degree to Kelvin conversion" | "none" | ""
    Δ_1::T3 = 5723.265 | (-Inf, Inf) | "first parameter of Δ from Murphy & Koop [2005]" | "none" | ""
    Δ_2::T4 = 3.53068 | (-Inf, Inf) | "second parameter of Δ from Murphy & Koop [2005]" | "none" | ""
    Δ_3::T5 = 0.00728332 | (-Inf, Inf) | "third parameter of Δ from Murphy & Koop [2005]" | "none" | ""
    Δ_4::T6 = 9.550426 | (-Inf, Inf) | "fourth parameter of Δ from Murphy & Koop [2005]" | "none" | ""
    pa_to_kpa::T7 = 0.001 | (-Inf, Inf) | "pascal to kilopascal conversion" | "none" | ""
    λ_1::T8 = 46782.5 | (-Inf, Inf) | "first parameter of λ from Murphy & Koop [2005]" | "none" | ""
    λ_2::T9 = 35.8925 | (-Inf, Inf) | "second parameter of λ from Murphy & Koop [2005]" | "none" | ""
    λ_3::T10 = 0.07414 | (-Inf, Inf) | "third parameter of λ from Murphy & Koop [2005]" | "none" | ""
    λ_4::T11 = 541.5 | (-Inf, Inf) | "fourth parameter of λ from Murphy & Koop [2005]" | "none" | ""
    λ_5::T12 = 123.75 | (-Inf, Inf) | "fifth parameter of λ from Murphy & Koop [2005]" | "none" | ""
    j_to_mj::T13 = 0.000001 | (-Inf, Inf) | "joule to megajoule conversion" | "none" | ""
    g_to_kg::T14 = 0.001 | (-Inf, Inf) | "joule to megajoule conversion" | "none" | ""
    mol_mass_water::T15 = 18.01528 | (-Inf, Inf) | "molecular mass of water" | "gram" | ""
    sp_heat_air::T16 = 0.001 | (-Inf, Inf) | "specific heat of air" | "MJ/kg/K" | ""
    γ_1::T17 = 0.001 | (-Inf, Inf) | "first parameter of γ from Brunt [1952]" | "none" | ""
    γ_2::T18 = 0.622 | (-Inf, Inf) | "second parameter of γ from Brunt [1952]" | "none" | ""
end
#! format: on

function compute(params::sublimation_GLEAM, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_sublimation_GLEAM params
    @unpack_nt (f_psurf_day, f_rn, f_airT_day) ⇐ forcing

    ## unpack land variables
    @unpack_nt begin
        frac_snow ⇐ land.states
        snowW ⇐ land.pools
        ΔsnowW ⇐ land.pools
        (z_zero, o_one, t_two) ⇐ land.constants
        n_snowW = snowW ⇐ helpers.pools.n_layers
    end
    # convert temperature to Kelvin
    T = f_airT_day + deg_to_k

    # from Diego miralles: The majority of the parameters I use in GLEAM come from the equations in Murphy & Koop [2005] here attached. The slope of the vapour pressure over ice versus temperature curve (Δ) is obtained from eq. (7). You may want to do this derivative yourself because my calculus is not as good as it used to; what I get is:
    Δ = ( Δ_1 / (T^t_two) +  Δ_2/ (T - Δ_3)) * exp(Δ_4 - Δ_1 / T + Δ_2 * log(T) - Δ_3 * T)

    # That you can convert from [Pa/K] to [kPa/K] by multiplying times 0.001.
    Δ = Δ * pa_to_kpa

    # The latent heat of sublimation of ice [λ] can be found in eq. (5):
    λ = λ_1 + λ_2 * T - λ_3 * T^t_two + λ_4 * exp(-(T / λ_5)^t_two)

    # To convert from [J/mol] to [MJ/kg] I assume a molecular mass of water of
    # 18.01528 g/mol:
    λ = λ * j_to_mj / (mol_mass_water * g_to_kg)

    # Then the psychrometer "constant" (γ) can be calculated in [kPa/K] according to Brunt [1952] as: Where P is the air pressure in [kPa], which I consider as a function of the elevation [DEM] but can otherwise be set to 101.3, & ca is the specific heat of air which I assume 0.001 MJ/kg/K.
    # ca = 101.3
    γ = f_psurf_day * γ_1 / (γ_2 * λ)

    #PTterm = (fei.Δ / (fei.Δ+fei.γ)) / fei.λ
    tmp = α * f_rn * (Δ / (Δ + γ)) / λ

    PTtermSub = at_least_zero(tmp)

    # Then sublimation [mm/day] is calculated in GLEAM using a P.T. equation
    sublimation = min(snowW[1] + ΔsnowW[1], PTtermSub * frac_snow) # assumes that sublimation occurs from the 1st snow layer if there is multilayered snow model

    @add_to_elem -sublimation ⇒ (ΔsnowW, 1)

    ## pack land variables
    @pack_nt begin
        sublimation ⇒ land.fluxes
        PTtermSub ⇒ land.sublimation
        ΔsnowW ⇒ land.pools
    end
    return land
end


purpose(::Type{sublimation_GLEAM}) = "Sublimation using the Priestley-Taylor term following the GLEAM approach."

@doc """

$(getModelDocString(sublimation_GLEAM))

---

# Extended help

*References*
 - Miralles; D. G.; De Jeu; R. A. M.; Gash; J. H.; Holmes; T. R. H.  & Dolman, A. J. (2011). An application of GLEAM to estimating global evaporation.  Hydrology & Earth System Sciences Discussions, 8[1].
 - Murphy, D. M., & Koop, T. (2005). Review of the vapour pressures of ice and supercooled water for atmospheric applications. Quarterly Journal of the Royal Meteorological Society: A journal of the atmospheric sciences, applied meteorology and physical oceanography, 131(608), 1539-1565. https://patarnott.com/atms360/pdf_atms360/class2017/VaporPressureIce_SupercooledH20_Murphy.pdf
*Versions*
 - 1.0 on 18.11.2019 [ttraut]: cleaned up the code  

*Created by*
 - mjung
"""
sublimation_GLEAM
