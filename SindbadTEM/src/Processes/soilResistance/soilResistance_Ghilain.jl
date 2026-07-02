export soilResistance_Ghilain

@bounds @describe @units @timescale @with_kw struct soilResistance_Ghilain{T1, T2} <: soilResistance
    r_ss_min::T1 = 50 | (-Inf, Inf) | "minimum soil resistance" | "s m-1" | ""
    r_ss_max::T2 = 5000 | (-Inf, Inf) | "maximum soil resistance" | "s m-1" | ""
end

function compute(params::soilResistance_Ghilain, forcing, land, helpers)
    @unpack_soilResistance_Ghilain params

    ### Soil resistance, s m-1
    rs_s = cal_Rs_s(params, forcing, land, helpers)

    ## pack land variables
    @pack_nt rs_s ⇒ land.diagnostics

    return land
end

function cal_Rs_s(params::soilResistance_Ghilain, forcing, land, helpers)

    @unpack_soilResistance_Ghilain params
    @unpack_nt begin
        soilW ⇐ land.pools
        ΔsoilW ⇐ land.pools
        (sp_θ_wp, sp_θ_fc, soil_layer_thickness) ⇐ land.properties # m3 m-3
    end

    LAI_max, w_max, h_c_min, h_c_max, k_VPD, z_0g, r_cs_min, Cr = get_pft_value(params, forcing, land, helpers)

    θ_top = (soilW[1] + ΔsoilW[1]) / soil_layer_thickness[1] # m3 m-3
    θ_wp = sp_θ_wp[1] # m3 m-3
    θ_fc = sp_θ_fc[1] # m3 m-3

    θ_g = (θ_top - θ_wp) / (θ_fc - θ_wp) # unitless, soil moisture stress factor

    # soil resistance, s m-1
    r_ss = r_ss_min .* (θ_g) .^ (-3)
    r_ss = clamp.(r_ss, r_ss_min, r_ss_max)

    if isa(r_ss, Number)
        r_ss = isinf(r_ss) ? r_ss_max : r_ss
    else
        r_ss[isinf.(r_ss)] .= r_ss_max
    end

    return r_ss
end

function get_pft_value(params::soilResistance_Ghilain, forcing, land, helpers)

    @unpack_soilResistance_Ghilain params
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

purpose(::Type{soilResistance_Ghilain}) = "calculate the soil resistance based on soil moisture, field capacity and wilting point."

@doc """

$(getModelDocString(soilResistance_Ghilain))

---

# Extended help

*References*

*Versions*
 - 1.0 on 11.08.2025 [jzhou]

*Created by*
 - jzhou

*Notes*
"""
soilResistance_Ghilain
