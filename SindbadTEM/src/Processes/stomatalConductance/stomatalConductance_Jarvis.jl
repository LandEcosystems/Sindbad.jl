export stomatalConductance_Jarvis

@bounds @describe @units @timescale @with_kw struct stomatalConductance_Jarvis{T1, T2, T3, T4, T5, T6, T7} <: stomatalConductance
    R_sc::T1 = 100 | (-Inf, Inf) | "scaling factor relevant to Solar radiation" | "W m-2" | ""
    r_cs_max::T2 = 5000 | (-Inf, Inf) | "maximum canopy resistance related to PFTs" | "s m-1" | ""
    Tmin::T3 = 0 | (-Inf, Inf) | "minimum temperature for stomatal conductance" | "deg C" | ""
    Topt::T4 = 25 | (-Inf, Inf) | "optimal temperature for stomatal conductance" | "deg C" | ""
    Tmax::T5 = 40 | (-Inf, Inf) | "maximum temperature for stomatal conductance" | "deg C" | ""
    Rgas::T6 = 0.008314 | (-Inf, Inf) | "universal gas constant" | "KJ mol-1 K-1" | ""
    k_Temp::T7 = 0.0016 | (-Inf, Inf) | "temperature stress coefficient" | "unitless" | ""
end

function compute(params::stomatalConductance_Jarvis, forcing, land, helpers)
    @unpack_stomatalConductance_Jarvis params

    ## unpack land variables
    @unpack_nt begin
        (f_psurf_day, f_airT_day) ⇐ forcing
        (z_zero, o_one, t_two) ⇐ land.constants
    end

    ### Canopy resistance, s m-1
    rs_c, rs_c_p = cal_r_sc(params, forcing, land, helpers)

    ### convert to m2 s umol-1 CO2 -- based on the ideal gas law
    patm = f_psurf_day # kPa
    T = f_airT_day # deg C
    rs = rs_c * Rgas * (T + 273.15) / (patm * 1e6) # m2 s umol-1 C

    ### Canopy conductance
    gs_c = 1 / rs # umolC m-2 s-1
    # convert to molC m-2 day-1
    gs_c = gs_c * 86400 / 1e6 # molC m-2 day-1

    ## pack land variables
    @pack_nt (gs_c, rs, rs_c, rs_c_p) ⇒ land.diagnostics

    return land
end

function cal_r_sc(params::stomatalConductance_Jarvis, forcing, land, helpers)

    @unpack_stomatalConductance_Jarvis params
    @unpack_nt begin
        (f_VPD_day, f_airT_day, f_SW) ⇐ forcing
        LAI ⇐ land.states
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
        (sp_θ_wp, sp_θ_fc, soil_layer_thickness) ⇐ land.properties # m3 m-3
        max_root_depth  ⇐ land.diagnostics
        tolerance ⇐ helpers.numbers
        root_over ⇐ land.rootWaterEfficiency
    end

    LAI_max, w_max, h_c_min, h_c_max, k_VPD, z_0g, r_cs_min, Cr = get_pft_value(params, forcing, land, helpers)

    # radiation stress
    R_solar = f_SW # shortwave radiation, MJ m-2 d-1
    R_solar = R_solar * 1e6 / 86400 # convert to W m-2
    f = 0.55 * 2 * (R_solar ./ (86400 * 1e-6)) ./ (R_sc .* LAI)
    f1_Rs = (f .+ r_cs_min ./ r_cs_max) ./ (f .+ 1)

    # Temperature stress
    T = f_airT_day # deg C
    f2_T = (Tmin < T && T < Tmax) ? 1 - k_Temp * (Topt - T) ^ 2 : 0

    # VPD stress
    VPD = max(f_VPD_day, tolerance) # kPa
    f3_VPD = ifelse.(VPD .> 4, 0, 1 .- k_VPD .* VPD)

    # root water moisture stress -- based on field capacity and wilting point
    root_layer = sum(root_over .> 0)

    θ_root = (sum(soilW[1 : root_layer]) + sum(ΔsoilW[1 : root_layer])) / sum(soil_layer_thickness[1 : root_layer]) # m3 m-3
    θ_wp = mean(sp_θ_wp[1 : root_layer]) # m3 m-3
    θ_fc = mean(sp_θ_fc[1 : root_layer]) # m3 m-3

    f4_theta = ifelse.(θ_root .>= θ_fc, 1, ifelse.(θ_root .> θ_wp .&& θ_root .< θ_fc, (θ_root .- θ_wp) ./ (θ_fc .- θ_wp), 0))

    # efficient LAI
    F_s = 0.3 .* LAI .+ 1.2

    # canopy resistance, s m-1
    r_sc = r_cs_min .* F_s ./ (LAI .* f1_Rs .* f2_T .* f3_VPD .* f4_theta)
    r_sc = clamp.(r_sc, r_cs_min, r_cs_max)

    if isa(r_sc, Number)
        r_sc = isinf(r_sc) ? r_cs_max : r_sc
    else
        r_sc[isinf.(r_sc)] .= r_cs_max
    end

    # potential canopy resistance for calculate potential transpiration -- no water stress, s m-1
    r_sc_p = r_cs_min .* F_s ./ (LAI .* f1_Rs .* f2_T .* f3_VPD)
    r_sc_p = clamp.(r_sc, r_cs_min, r_cs_max)

    if isa(r_sc_p, Number)
        r_sc_p = isinf(r_sc_p) ? r_cs_max : r_sc_p
    else
        r_sc_p[isinf.(r_sc_p)] .= r_cs_max
    end

    return r_sc, r_sc_p
end

function get_pft_value(params::stomatalConductance_Jarvis, forcing, land, helpers)

    @unpack_stomatalConductance_Jarvis params
    @unpack_nt PFT ⇐ land.PFT

    # PFT_to_PlantForm = Dict(
	# 	1 => "Tree",
	# 	2 => "Tree",
	# 	3 => "Tree",
	# 	4 => "Tree",
	# 	5 => "Tree",
	# 	6 => "Shrub",
	# 	7 => "Shrub",
	# 	8 => "Savanna",
	# 	9 => "Savanna",
	# 	10 => "Herb",
	# 	11 => "Herb",
	# 	12 => "Herb",
	# 	14 => "Herb",
	# 	13 => "Non-Veg",
	# 	15 => "Non-Veg",
	# 	16 => "Non-Veg",
	# 	17 => "Non-Veg",
	# 	NaN => "Non-Veg",
	# 	missing => "Non-Veg"
	# 	)

    ### PFTs from 1-17
    # ENF
    # EBF
    # DNF
    # DBF
    # MF
    # CSH
    # OSH
    # WSA
    # SAV
    # GRA
    # WET
    # CRO
    # URB
    # CVM
    # SNO
    # BSV
    # WAT

    PFT = Int(PFT)

    # only includes PFTs from 1-12
    LAI_max = [5.5, 7, 3.3, 7, 5.7, 4.6, 3, 1.5, 0.9, 1.8, 6, 7] 
    w_max = [0.001, 0.05, 0.001, 0.08, 0.04, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01]
    h_c_min = [17, 30, 17, 25, 20, 1.5, 1, 0.8, 0.1, 0.05, 0.05, 0]
    h_c_max = [17, 30, 17, 25, 20, 1.5, 1, 0.8, 0.8, 0.8, 1.0, 0.8]
    k_VPD = [0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.155, 0.00, 0.23]
    z_0g = [0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.01, 0.01, 0.005]
    r_cs_min = [125, 150, 150, 100, 125, 150, 100, 70, 70, 40, 100, 40]
    Cr = [0.45, 0.59, 0.45, 0.59, 0.59, 0.56, 0.56, 0.5, 0.5, 0.5, 0.0, 0.62]

    return LAI_max[PFT], w_max[PFT], h_c_min[PFT], h_c_max[PFT], k_VPD[PFT], z_0g[PFT], r_cs_min[PFT], Cr[PFT]
end

purpose(::Type{stomatalConductance_Jarvis}) = "calculate the stomatal Conductance based on Jarvis model."

@doc """

$(getModelDocString(stomatalConductance_Jarvis))

---

# Extended help

*References*

*Versions*
 - 1.0 on 11.08.2025 [jzhou]

*Created by*
 - jzhou

*Notes*
"""
stomatalConductance_Jarvis
