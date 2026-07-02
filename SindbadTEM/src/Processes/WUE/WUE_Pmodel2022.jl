export WUE_Pmodel2022

#! format: on
@bounds @describe @units @timescale @with_kw struct WUE_Pmodel2022{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,T15,T16,T17,T18,T19,T20,T21,T22} <: WUE
    # Original parameters from the struct
    g1::T1 = 3.0 | (0.5, 12.0) | "stomatal conductance parameter" | "kPa^0.5" | ""
    ζ::T2 = 1.0 | (0.85, 3.5) | "sensitivity of WUE to ambient co2" | "" | ""
    diffusivity_ratio::T3 = 1.6 | (-Inf, Inf) | "Ratio of the molecular diffusivities for water vapor and CO2" | "" | ""
    gs25_0::T4 = 4.332 | (3.0, 6.0) | "reference value of gamma" | "Pa" | ""
    kphio_C3_p1::T5 = 0.352 | (0.2, 0.5) | "used in the calculation of kphio" | "" | ""
    kphio_C3_p2::T6 = 0.022 | (0.01, 0.04) | "used in the calculation of kphio" | "" | ""
    kphio_C3_p3::T7 = -0.00034 | (-0.001, -0.0001) | "used in the calculation of kphio" | "" | ""
    beta::T8 = 146.0 | (100.0, 200.0) | "unit cost for C3 plants" | "" | ""
    dha::T9 = 37830.0 | (-Inf, Inf) | "activation energy for Jmax" | "J mol^-1" | ""
    tk_ref::T10 = 298.15 | (-Inf, Inf) | "reference temperature" | "K" | ""
    k_Po::T11 = 101325.0 | (-Inf, Inf) | "standard atmospheric pressure" | "Pa" | ""
    k_R::T12 = 8.3145 | (-Inf, Inf) | "universal gas constant" | "J mol^-1 K^-1" | ""
    k_co::T13 = 209476.0 | (-Inf, Inf) | "CO2 compensation point at 25°C" | "ppm" | ""
    dhao::T14 = 36380.0 | (-Inf, Inf) | "activation energy for Ko" | "J mol^-1" | ""
    dhac::T15 = 79430.0 | (-Inf, Inf) | "activation energy for Kc" | "J mol^-1" | ""
    kc25::T16 = 39.97 | (-Inf, Inf) | "Michaelis-Menten constant for CO2 at 25°C" | "Pa" | ""
    k_To::T17 = 298.15 | (-Inf, Inf) | "reference temperature" | "K" | ""
    k_CtoK::T18 = 273.15 | (-Inf, Inf) | "conversion from Celsius to Kelvin" | "K" | ""
    huber_tk_ast::T19 = 647.096 | (-Inf, Inf) | "critical temperature of water" | "K" | ""
    huber_rho_ast::T20 = 322.0 | (-Inf, Inf) | "critical density of water" | "kg m^-3" | ""
    p_std::T21 = 101325.0 | (-Inf, Inf) | "standard atmospheric pressure" | "Pa" | ""
    ko25::T22 = 27480.0 | (-Inf, Inf) | "Michaelis-Menten constant for O2 at 25°C" | "Pa" | ""
end
#! format: on

# function define(params::WUE_Pmodel2022, forcing, land, helpers)
#     @unpack_WUE_Pmodel2022 params

#     huber_H_ij = Matrix{Float64}(undef, 7, 6)
#     huber_H_ij[1,:] = [0.520094, 0.0850895, -1.08374, -0.289555, 0.0, 0.0]
#     huber_H_ij[2,:] = [0.222531, 0.999115, 1.88797, 1.26613, 0.0, 0.120573]
#     huber_H_ij[3,:] = [-0.281378, -0.906851, -0.772479, -0.489837, -0.25704, 0.0]
#     huber_H_ij[4,:] = [0.161913, 0.257399, 0.0, 0.0, 0.0, 0.0]
#     huber_H_ij[5,:] = [-0.0325372, 0.0, 0.0, 0.0698452, 0.0, 0.0]
#     huber_H_ij[6,:] = [0.0, 0.0, 0.0, 0.0, 0.00872102, 0.0]
#     huber_H_ij[7,:] = [0.0, 0.0, 0.0, -0.00435673, 0.0, -0.000593264]

#     # degree C
#     # Pa to bar
#     visc_std = cal_viscosity_h2o(params, land, k_To - k_CtoK, 1e-05 * p_std, huber_H_ij) # viscosity of water at the standard temperature and pressure

#     @pack_nt (huber_H_ij, visc_std) ⇒ land.diagnostics
#     return land
# end

function compute(params::WUE_Pmodel2022, forcing, land, helpers)

    @unpack_WUE_Pmodel2022 params
    @unpack_nt begin
        # (PA_W, f_PAR, TA_W, CA_W) ⇐ forcing
        Chi_opt ⇐ forcing
        # (visc_std, huber_H_ij) ⇐ land.diagnostics
    end

    ## calculate variables
    vpd, tk, patm, ca, pbar = data_processing(land, forcing, helpers)

    # gammastar, kmm = cal_gammastar_kmm(params, land, tk, patm)
    # visc_env = cal_viscosity_h2o(params, land, f_airT_day, pbar, huber_H_ij)

    # ns_star = visc_env / visc_std

    # ### Χ
    # xi = @fastmath sqrt((beta * (kmm + gammastar)) / (1.6 * ns_star))
    # ciNoCO2 = @fastmath gammastar / ca + (1 - gammastar / ca) * xi / (xi + sqrt(vpd * 1000)) # units of VPD should be Pa

    ciNoCO2 = Chi_opt

    WUE = @fastmath (2000 * ca * (1 - ciNoCO2) / (3 * vpd * 1000 * diffusivity_ratio))

    ## pack land variables
    @pack_nt begin
        ciNoCO2 ⇒ land.states
        WUE ⇒ land.diagnostics
    end
    return land
end

function data_processing(land, forcing, helpers)

    @unpack_nt begin
        (f_psurf_day, f_VPD_day, f_airT_day) ⇐ forcing
        ambient_CO2 ⇐ land.states # ppm
        tolerance ⇐ helpers.numbers
    end

    vpd = @fastmath max(f_VPD_day, tolerance) # kPa
    tk = @fastmath f_airT_day + 273.15 # deg C to K
    patm = @fastmath f_psurf_day * 1000 # kPa to Pa
    ca = @fastmath 1.0e-6 * ambient_CO2 * patm # ppm to Pa
    pbar = @fastmath 1e-05 * patm
    return vpd, tk, patm, ca, pbar
end

function cal_gammastar_kmm(params::WUE_Pmodel2022, land, tk, patm)

    @unpack_WUE_Pmodel2022 params
    @unpack_nt (z_zero, o_one) ⇐ land.constants

    # gammastar
    arrhenius_factor = @fastmath exp(dha * (tk - tk_ref) / (tk_ref * k_R * tk))
    gammastar = @fastmath (gs25_0 * patm / k_Po) * arrhenius_factor # Pa

    # kmm
    kc = @fastmath kc25 * exp(dhac * (tk - tk_ref) / (tk_ref * k_R * tk))
    ko = @fastmath ko25 * exp(dhao * (tk - tk_ref) / (tk_ref * k_R * tk))
    po = @fastmath k_co * 1e-06 * patm # Pa
    kmm = @fastmath kc * (o_one + po / ko)

    return gammastar, kmm
end

function cal_viscosity_h2o(params::WUE_Pmodel2022, land, tc, pbar, huber_H_ij)

     # viscosity of water at the given temperature and pressure

    @unpack_WUE_Pmodel2022 params
    @unpack_nt (z_zero, o_one) ⇐ land.constants

    huber_H_i = Float64.([1.67752, 2.20462, 0.6366564, -0.241605])
    huber_mu_ast = Float64.(1e-06)
    lambda_coef_rev = Float64.(reverse([1788.316, 21.55053, -0.4695911, 0.003096363, -7.341182e-06]))
    po_coef_rev = Float64.(reverse([5918.499, 58.05267, -1.1253317, 0.0066123869, -1.4661625e-05]))
    vinf_coef_rev = Float64.(reverse([5918.499, 58.05267, -1.1253317, 0.0066123869, -1.4661625e-05]))

    lambda_val = @fastmath evalpoly(tc, lambda_coef_rev)
    po_val = @fastmath evalpoly(tc, po_coef_rev)
    vinf_val = @fastmath evalpoly(tc, vinf_coef_rev)
    spec_vol = @fastmath vinf_val + lambda_val / (pbar + po_val)
    rho = @fastmath 1e3 / spec_vol

    tbar = @fastmath (tc + k_CtoK) / huber_tk_ast
    rbar = @fastmath rho / huber_rho_ast

    inv_tbar = @fastmath inv(tbar)
    mu0 = @fastmath (1e2 * sqrt(tbar)) / evalpoly(inv_tbar, huber_H_i)

    ctbar = inv_tbar - o_one
    mu1 = z_zero
    @inbounds @simd for row_idx in 1:6
        cf1 = ctbar^(row_idx-1)
        cf2 = z_zero
        @inbounds @simd for col_idx in 1:7
            cf2 += huber_H_ij[col_idx, row_idx] * (rbar - o_one) ^ (col_idx-1)
        end
        mu1 += cf1 * cf2
    end

    mu1 = exp(rbar * mu1)

    return mu0 * mu1 * huber_mu_ast
end

purpose(::Type{WUE_Pmodel2022}) = "calculates the WUE based on Fick's Law, and ci/ca (Χ) is a function of Temperature, VPD, CO2, and Pressure (P-Model)."

@doc """

$(getModelDocString(WUE_Pmodel2022))

---

# Extended help

*References*
 - 1. Stocker, B. D. et al. P-model v1.0: an optimality-based light use efficiency model for simulating ecosystem gross primary production. Geoscientific Model Development 13, 1545–1581 (2020).


*Versions*
 - 1.0 on 14.04.25 [jzhou | @jzhou]

*Created by*
 - jzhou | @jzhou

*Notes*
 - unit conversion: C_flux[gC m-2 d-1] < - CO2_flux[(umol CO2 m-2 s-1)] *  1e-06 [umol2mol] * 0.012011 [Cmol] * 1000 [kg2g] * 86400 [days2seconds]  from Knauer; 2019
 - water: mmol m-2 s-1: /1000 [mol m-2 s-1] * .018015 [Wmol in kg/mol] * 84600
"""
WUE_Pmodel2022