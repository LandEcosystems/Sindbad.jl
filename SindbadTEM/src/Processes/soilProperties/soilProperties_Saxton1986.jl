export soilProperties_Saxton1986, unsatK

struct kSaxton1986 end

#! format: off
@bounds @describe @units @timescale @with_kw struct soilProperties_Saxton1986{T1,T2,T3,TN} <: soilProperties
    ψ_fc::T1 = 33.0 | (30.0, 35.0) | "matric potential at field capacity" | "kPa" | ""
    ψ_wp::T2 = 1500.0 | (1000.0, 1800.0) | "matric potential at wilting point" | "kPa" | ""
    ψ_sat::T3 = 0.0 | (0.0, 5.0) | "matric potential at saturation" | "kPa" | ""
    a1::TN = -4.396 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    a2::TN = -0.0715 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    a3::TN = -0.000488 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    a4::TN = -4.285e-05 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    b1::TN = -3.14 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    b2::TN = -0.00222 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    b3::TN = -3.484e-05 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    c1::TN = 0.332 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    c2::TN = -0.0007251 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    c3::TN = 0.1276 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    d1::TN = -0.108 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    d2::TN = 0.341 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    e1::TN = 2.778e-6 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    e2::TN = 12.012 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    e3::TN = -0.0755 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    e4::TN = -3.895 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    e5::TN = 0.03671 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    e6::TN = -0.1103 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    e7::TN = 0.00087546 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    f1::TN = 2.302 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    n2::TN = 2.0 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    n24::TN = 24.0 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    n10::TN = 10.0 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    n100::TN = 100.0 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    n1000::TN = 1000.0 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    n1500::TN = 1000.0 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    n3600::TN = 3600.0 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
end

function define(params::soilProperties_Saxton1986, forcing, land, helpers)
    @unpack_soilProperties_Saxton1986 params
    @unpack_nt soilW ⇐ land.pools

    ## Instantiate variables
    sp_α = zero(soilW)
    sp_β = zero(soilW)
    sp_k_fc = zero(soilW)
    sp_θ_fc = zero(soilW)
    sp_ψ_fc = zero(soilW)
    sp_k_wp = zero(soilW)
    sp_θ_wp = zero(soilW)
    sp_ψ_wp = zero(soilW)
    sp_k_sat = zero(soilW)
    sp_θ_sat = zero(soilW)
    sp_ψ_sat = zero(soilW)

    unsat_k_model = kSaxton1986()

    ## pack land variables
    @pack_nt begin
        (sp_k_fc, sp_k_sat, sp_k_wp, sp_α, sp_β, sp_θ_fc, sp_θ_sat, sp_θ_wp, sp_ψ_fc, sp_ψ_sat, sp_ψ_wp) ⇒ land.properties
        (n100, n1000, n2, n24, n3600, e1, e2, e3, e4, e5, e6, e7) ⇒ land.soilProperties
        unsat_k_model ⇒ land.models
    end
    return land
end

function precompute(params::soilProperties_Saxton1986, forcing, land, helpers)
    ## unpack parameters
    @unpack_soilProperties_Saxton1986 params

    ## unpack land variables
    @unpack_nt (sp_α, sp_β, sp_k_fc, sp_θ_fc, sp_ψ_fc, sp_k_wp, sp_θ_wp, sp_ψ_wp, sp_k_sat, sp_θ_sat, sp_ψ_sat) ⇐ land.properties
    @unpack_nt soilW ⇐ land.pools

    ## calculate variables
    # number of layers & creation of arrays
    # calculate & set the soil hydraulic properties for each layer
    for sl in eachindex(soilW)
        (α, β, k_fc, θ_fc, ψ_fc) = calcPropsSaxton1986(params, land, helpers, sl, ψ_fc)
        (_, _, k_wp, θ_wp, ψ_wp) = calcPropsSaxton1986(params, land, helpers, sl, ψ_wp)
        (_, _, k_sat, θ_sat, ψ_sat) = calcPropsSaxton1986(params, land, helpers, sl, ψ_sat)
        @rep_elem α ⇒ (sp_α, sl, :soilW)
        @rep_elem β ⇒ (sp_β, sl, :soilW)
        @rep_elem k_fc ⇒ (sp_k_fc, sl, :soilW)
        @rep_elem θ_fc ⇒ (sp_θ_fc, sl, :soilW)
        @rep_elem ψ_fc ⇒ (sp_ψ_fc, sl, :soilW)
        @rep_elem k_wp ⇒ (sp_k_wp, sl, :soilW)
        @rep_elem θ_wp ⇒ (sp_θ_wp, sl, :soilW)
        @rep_elem ψ_wp ⇒ (sp_ψ_wp, sl, :soilW)
        @rep_elem k_sat ⇒ (sp_k_sat, sl, :soilW)
        @rep_elem θ_sat ⇒ (sp_θ_sat, sl, :soilW)
        @rep_elem ψ_sat ⇒ (sp_ψ_sat, sl, :soilW)
    end

    ## pack land variables
    @pack_nt begin
        (sp_k_fc, sp_k_sat, sp_k_wp, sp_α, sp_β, sp_θ_fc, sp_θ_sat, sp_θ_wp, sp_ψ_fc, sp_ψ_sat, sp_ψ_wp) ⇒ land.properties
    end
    return land
end

function unsatK(land, helpers, sl, ::kSaxton1986)
    @unpack_nt begin
        (st_clay, st_sand) ⇐ land.properties
        soil_layer_thickness ⇐ land.properties
        (n100, n1000, n2, n24, n3600, e1, e2, e3, e4, e5, e6, e7) ⇐ land.soilProperties
        soilW ⇐ land.pools
    end

    ## calculate variables
    clay = st_clay[sl] * n100
    sand = st_sand[sl] * n100
    soilD = soil_layer_thickness[sl]
    θ = soilW[sl] / soilD
    K = e1 * (exp(e2 + e3 * sand + (e4 + e5 * sand + e6 * clay + e7 * clay^n2) * (o_one / θ))) * n1000 * n3600 * n24

    ## pack land variables
    return K
end

"""
calculates the soil hydraulic properties based on Saxton 1986

# Extended help
"""
function calcPropsSaxton1986(params::soilProperties_Saxton1986, land, helpers, sl, WT)
    @unpack_soilProperties_Saxton1986 params

    @unpack_nt begin
        (z_zero, o_one) ⇐ land.constants
        (st_clay, st_sand) ⇐ land.properties
    end

    ## calculate variables
    # CONVERT sand AND clay TO PERCENTAGES
    clay = st_clay[sl] * n100
    sand = st_sand[sl] * n100
    # Equations
    A = exp(a1 + a2 * clay + a3 * sand^n2 + a4 * sand^n2 * clay) * n100
    B = b1 + b2 * clay^n2 + b3 * sand^n2 * clay
    # soil matric potential; ψ; kPa
    ψ = WT
    # soil moisture content at saturation [m^3/m^3]
    θ_s = c1 + c2 * sand + c3 * log10(clay)
    # air entry pressure [kPa]
    ψ_e = abs(n100 * (d1 + d2 * θ_s))
    # θ = ones(typeof(clay), size(clay))
    θ = oftype(A, o_one)
    if (ψ >= n10 && ψ <= n1500)
        θ = ψ / A^(o_one / B)
    end
    # clear ndx
    if (ψ >= ψ_e && ψ < n10)
        # θ at 10 kPa [m^3/m^3]
        θ_10 = exp((f1 - log(A)) / B)
        # ---------------------------------------------------------------------
        # ψ = 10.0 - (θ - θ_10) * (10.0 - # ψ_e) / (θ_s - θ_10)
        # ---------------------------------------------------------------------
        θ = θ_10 + (n10 - ψ) * (θ_s - θ_10) / (n10 - ψ_e)
    end
    # clear ndx
    if (ψ >= z_zero && ψ < ψ_e)
        θ = θ_s
    end
    # clear ndx
    # hydraulic conductivity [mm/day]: original equation for mm/s
    K = e1 * (exp(e2 + e3 * sand + (e4 + e5 * sand + e6 * clay + e7 * clay^n2) * (o_one / θ))) * n1000 * n3600 * n24
    α = A
    β = B
    ## pack land variables
    return α, β, K, θ, ψ
end


purpose(::Type{soilProperties_Saxton1986}) = "Soil hydraulic properties based on Saxton (1986)."

@doc """

$(getModelDocString(soilProperties_Saxton1986))

---

# Extended help

*References*
- Saxton, K. E., Rawls, W., Romberger, J. S., & Papendick, R. I. (1986). Estimating generalized soil‐water characteristics from texture. Soil science society of America Journal, 50(4), 1031-1036.

*Versions*
 - 1.0 on 21.11.2019
 - 1.1 on 03.12.2019 [skoirala | @dr-ko]: handling potentail vertical distribution of soil texture  

*Created by*
 - skoirala | @dr-ko
"""
soilProperties_Saxton1986