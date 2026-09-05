export soilProperties_Saxton2006, unsatK

struct kSaxton2006 end

#! format: off
@bounds @describe @units @timescale @with_kw struct soilProperties_Saxton2006{T1,T2,T3,T4,T5,TN} <: soilProperties
    DF::T1 = 1.0 | (0.9, 1.3) | "Density correction factor" | "" | ""
    Rw::T2 = 0.0 | (0.0, 1.0) | "Weight fraction of gravel (decimal)" | "g g-1" | ""
    matric_soil_density::T3 = 2.65 | (2.5, 3.0) | "Matric soil density" | "g cm-3" | ""
    gravel_density::T4 = 2.65 | (2.5, 3.0) | "density of gravel material" | "g cm-3" | ""
    EC::T5 = 36.0 | (30.0, 40.0) | "SElectrical conductance of a saturated soil extract" | "dS m-1 (dS/m = mili-mho cm-1)" | ""
    a1::TN = -0.024 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    a2::TN = 0.487 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    a3::TN = 0.006 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    a4::TN = 0.005 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    a5::TN = 0.013 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    a6::TN = 0.068 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    a7::TN = 0.031 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    b1::TN = 0.14 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    b2::TN = 0.02 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    c1::TN = -0.251 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    c2::TN = 0.195 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    c3::TN = 0.011 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    c4::TN = 0.006 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    c5::TN = 0.027 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    c6::TN = 0.452 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    c7::TN = 0.299 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    d1::TN = 1.283 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    d2::TN = 0.374 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    d3::TN = 0.015 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    e1::TN = 0.278 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    e2::TN = 0.034 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    e3::TN = 0.022 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    e4::TN = 0.018 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    e5::TN = 0.027 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    e6::TN = 0.584 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    e7::TN = 0.078 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    f1::TN = 0.636 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    f2::TN = 0.107 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    g1::TN = -21.67 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    g2::TN = 27.93 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    g3::TN = 81.97 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    g4::TN = 71.12 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    g5::TN = 8.29 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    g6::TN = 14.05 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    g7::TN = 27.16 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    h1::TN = 0.02 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    h2::TN = 0.113 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    h3::TN = 0.70 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    i1::TN = 0.097 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    i2::TN = 0.043 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    n02::TN = 0.2 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    n24::TN = 24.0 | (-Inf, Inf) | "Saxton Parameters" | "" | "day"
    n33::TN = 33.0 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    n36::TN = 36.0 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    n1500::TN = 1500.0 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
    n1930::TN = 1930.0 | (-Inf, Inf) | "Saxton Parameters" | "" | ""
end
# b::T =  | (-Inf, Inf) | "Saxton Parameters" | ""

function define(params::soilProperties_Saxton2006, forcing, land, helpers)
    @unpack_soilProperties_Saxton2006 params

    @unpack_nt begin
        soilW ⇐ land.pools
    end
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

    # generate the function handle to calculate soil hydraulic property
    unsat_k_model = kSaxton2006()

    ## pack land variables
    @pack_nt (sp_k_fc, sp_k_sat, sp_k_wp, sp_α, sp_β, sp_θ_fc, sp_θ_sat, sp_θ_wp, sp_ψ_fc, sp_ψ_sat, sp_ψ_wp) ⇒ land.properties
    @pack_nt unsat_k_model ⇒ land.models
    return land
end


function precompute(params::soilProperties_Saxton2006, forcing, land, helpers)
    @unpack_soilProperties_Saxton2006 params

    @unpack_nt begin
        (sp_k_fc, sp_k_sat, sp_k_wp, sp_α, sp_β, sp_θ_fc, sp_θ_sat, sp_θ_wp, sp_ψ_fc, sp_ψ_sat, sp_ψ_wp) ⇐ land.properties
    end
    ## calculate variables
    # calculate & set the soil hydraulic properties for each layer
    for sl in eachindex(sp_α)
        (α, β, k_sat, θ_sat, ψ_sat, k_fc, θ_fc, ψ_fc, k_wp, θ_wp, ψ_wp) = calcPropsSaxton2006(params, land, helpers, sl)
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
    @pack_nt (sp_k_fc, sp_k_sat, sp_k_wp, sp_α, sp_β, sp_θ_fc, sp_θ_sat, sp_θ_wp, sp_ψ_fc, sp_ψ_sat, sp_ψ_wp) ⇒ land.properties
    return land
end

purpose(::Type{soilProperties_Saxton2006}) = "Soil hydraulic properties based on Saxton (2006)."

@doc """

$(getModelDocString(soilProperties_Saxton2006))

---

# Extended help

*References*
 - Saxton, K. E., & Rawls, W. J. (2006). Soil water characteristic estimates by  texture & organic matter for hydrologic solutions.  Soil science society of America Journal, 70[5], 1569-1578.

*Versions*
 - 1.0 on 21.11.2019
 - 1.1 on 03.12.2019 [skoirala | @dr-ko]: handling potentail vertical distribution of soil texture  

*Created by*
 - Nuno Carvalhais [ncarvalhais]
 - skoirala | @dr-ko
"""
soilProperties_Saxton2006

"""
calculates the soil hydraulic conductivity for a given moisture based on Saxton; 2006

# Inputs:
 - land.pools.soilW[sl]
 - land.properties.sp_[w_sat/β/k_sat]: hydraulic parameters for each soil layer

# Outputs:
 - K: the hydraulic conductivity at unsaturated land.pools.soilW [in mm/day]

# Modifies:

# Extended help

# References:
 - Saxton, K. E., & Rawls, W. J. (2006). Soil water characteristic estimates by  texture & organic matter for hydrologic solutions.  Soil science society of America Journal, 70[5], 1569-1578.

# Versions:
 - 1.0 on 22.11.2019 [skoirala | @dr-ko]:
 - 1.1 on 03.12.2019 [skoirala | @dr-ko]: included the option to handle lookup table when set to true  from model_run.json  

# Created by
 - skoirala | @dr-ko

# Notes:
 - This function is a part of pSoil; but making the looking up table & setting the soil  properties is handled by soilWBase [by calling this function]
 - is also used by all approaches depending on kUnsat within time loop of coreTEM
"""
function unsatK(land, helpers, sl, ::kSaxton2006)
    @unpack_nt begin
        (t_two, t_three) ⇐ land.constants
        (soil_β, k_sat, w_sat) ⇐ land.properties
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
        (z_zero, o_one) ⇐ land.constants
    end

    ## calculate variables
    w_sat = w_sat[sl]
    θ_dos = (soilW[sl] + ΔsoilW[sl]) / w_sat
    θ_dos = clamp_zero_one(θ_dos)
    β = soil_β[sl]
    k_sat = k_sat[sl]
    λ = o_one / β
    K = k_sat * ((θ_dos)^(t_three + (t_two / λ)))
    return K
end

"""
calculates the soil hydraulic properties based on Saxton 2006

# Inputs:
 - : texture-based parameters
 - info
 - land.properties.sp_[clay/sand]: in fraction
 - sl: soil layer to calculate property for

# Outputs:
 - hydraulic conductivity [k], matric potention [ψ] & porosity  (θ) at saturation [Sat], field capacity [_fc], & wilting point  ( w_wp)
 - properties of moisture-retention curves: (α & β)

# Modifies:

# Extended help

# References:
 - Saxton, K. E., & Rawls, W. J. (2006). Soil water characteristic estimates by  texture & organic matter for hydrologic solutions.  Soil science society of America Journal, 70[5], 1569-1578.

# Versions:
 - 1.0 on 22.11.2019 [skoirala | @dr-ko]:

# Created by
 - skoirala | @dr-ko

# Notes:
 - _fc: Field Capacity moisture [33 kPa], #v  
 - PAW: Plant Avail. moisture [33-1500 kPa, matric soil], #v
 - PAWB: Plant Avail. moisture [33-1500 kPa, bulk soil], #v
 - SAT: Saturation moisture [0 kPa], #v
 - w_wp: Wilting point moisture [1500 kPa], #v
"""
function calcPropsSaxton2006(params::soilProperties_Saxton2006, land, helpers, sl)

    @unpack_soilProperties_Saxton2006 params
    @unpack_nt begin
        (st_clay, st_orgm, st_sand) ⇐ land.properties
        (z_zero, o_one, t_two, t_three) ⇐ land.constants
    end

    clay = st_clay[sl]
    sand = st_sand[sl]
    orgm = zero(st_orgm[sl])
    # @show sl, clay, sand, orgm
    # orgm = st_orgm[sl]
    # orgm = sp_orgm[sl]
    # orgm = z_zero
    # clay = clay
    # sand = sand
    # orgm = orgm
    ## Moisture regressions
    # θ_1500t: 1500 kPa moisture; first solution; #v
    # θ_1500: 1500 kPa moisture; #v
    θ_1500t = a1 * sand + a2 * clay + a3 * orgm + a4 * (sand * orgm) - a5 * (clay * orgm) + a6 * (sand * clay) + a7
    θ_1500 = θ_1500t + (b1 * θ_1500t - b2)
    θ_1500 = max(θ_1500, typeof(θ_1500)(0.01))
    # θ_33t: 33 kPa moisture; first solution; #v
    # θ_33: 33 kPa moisture; normal density; #v
    θ_33t = c1 * sand + c2 * clay + c3 * orgm + c4 * (sand * orgm) - c5 * (clay * orgm) + c6 * (sand * clay) + c7
    θ_33 = θ_33t + (d1 * (θ_33t)^t_two - d2 * θ_33t - d3)
    # θ_s_33t: SAT-33 kPa moisture; first solution; #v
    # θ_s_33: SAT-33 kPa moisture; normal density #v
    θ_s_33t = e1 * sand + e2 * clay + e3 * orgm - e4 * (sand * orgm) - e5 * (clay * orgm) - e6 * (sand * clay) + e7
    θ_s_33 = θ_s_33t + (f1 * θ_s_33t - f2)
    # ψ_et: Tension at air entry; first solution; kPa
    # ψ_e: Tension at air entry [bubbling pressure], kPa
    ψ_et = abs(g1 * sand - g2 * clay - g3 * θ_s_33 + g4 * (sand * θ_s_33) + g5 * (clay * θ_s_33) - g6 * (sand * clay) + g7)
    ψ_e = abs(ψ_et + (h1 * (ψ_et^t_two) - h2 * ψ_et - h3))
    # θ_s: Saturated moisture [0 kPa], normal density, #v
    # rho_N: Normal density; g cm-3
    θ_s = θ_33 + θ_s_33 - i1 * sand + i2
    rho_N = (o_one - θ_s) * gravel_density
    ## Density effects
    # rho_DF: Adjusted density; g cm-3
    # θ_s_DF: Saturated moisture [0 kPa], adjusted density, #v
    # θ_33_DF: 33 kPa moisture; adjusted density; #v
    # θ_s_33_DF: SAT-33 kPa moisture; adjusted density; #v
    # DF: Density adjustment Factor [0.9-1.3]
    rho_DF = rho_N * DF
    # θ_s_DF = 1 - (rho_DF / gravel_density); # original but does not include θ_s
    θ_s_DF = θ_s * (o_one - (rho_DF / gravel_density)) # may be includes θ_s
    θ_33_DF = θ_33 - n02 * (θ_s - θ_s_DF)
    θ_1500_DF = θ_1500 - n02 * (θ_s - θ_s_DF)
    θ_s_33_DF = θ_s_DF - θ_33_DF
    ## Moisture-Tension
    # A, B: Coefficients of moisture-tension, Eq. [11]
    # ψ_θ: Tension at moisture θ; kPa
    B = (log(n1500) - log(n33)) / (log(θ_33) - log(θ_1500))
    A = exp(log(n33) + B * log(θ_33))
    # ψ_θ = A * ((θ) ^ (-B))
    # ψ_33 = 33.0 - ((θ - θ_33) * (33.0 - ψ_e)) / (θ_s - θ_33)
    ## Moisture-Conductivity
    # λ: Slope of logarithmic tension-moisture curve
    # Ks: Saturated conductivity [matric soil], mm h-1
    # K_θ: Unsaturated conductivity at moisture θ; mm h-1
    λ = o_one / B
    Ks = n1930 * ((θ_s - θ_33)^(t_three - λ)) * n24
    # K_θ = Ks * ((θ / θ_s) ^ (3 + (2 / λ)))
    ## Gravel Effects
    # rho_B: Bulk soil density [matric plus gravel], g cm-3
    # αRho: Matric soil density/gravel density [gravel_density] = rho/2.65
    # Rv: Volume fraction of gravel [decimal], g cm -3
    # Rw: Weight fraction of gravel [decimal], g g-1
    # Kb: Saturated conductivity [bulk soil], mm h-1
    αRho = matric_soil_density / gravel_density
    Rv = (αRho * Rw) / (o_one - Rw * (o_one - αRho))
    rho_B = rho_N * (o_one - Rv) + Rv * gravel_density
    # PAW_B = PAW * (o_one - Rv)
    Kb = Ks * ((o_one - Rw) / (o_one - Rw * (o_one - (t_three * αRho / t_two))))
    ## Salinity Effects
    # ϕ_o: Osmotic potential at θ = θ_s; kPa
    # ϕ_o_θ: Osmotic potential at θ < θ_s; kPa
    # EC: Electrical conductance of a saturated soil extract, dS m-1 [dS/m = mili-mho cm-1]
    phi_o = n36 * EC
    # ϕ_o_θ = (θ_s / θ) * n36 / EC
    ## Assign the variables for returning
    α = A
    β = B
    # θ_sat = θ_s_DF
    θ_sat = θ_s
    k_sat = Kb
    ψ_sat = z_zero
    # θ_fc = θ_33_DF
    θ_fc = θ_33
    k_fc = k_sat * ((θ_fc / θ_sat)^(t_three + (t_two / λ)))
    ψ_fc = n33
    # θ_wp = θ_1500_DF
    θ_wp = θ_1500
    ψ_wp = n1500
    k_wp = k_sat * ((θ_wp / θ_sat)^(t_three + (t_two / λ)))

    ## pack land variables
    return α, β, k_sat, θ_sat, ψ_sat, k_fc, θ_fc, ψ_fc, k_wp, θ_wp, ψ_wp
end
