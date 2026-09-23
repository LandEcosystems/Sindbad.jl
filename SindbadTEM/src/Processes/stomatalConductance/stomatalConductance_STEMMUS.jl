export stomatalConductance_STEMMUS

#! format: off
@bounds @describe @units @timescale @with_kw struct stomatalConductance_STEMMUS{T} <: stomatalConductance
    stomatal_method::T = 2.0 | (1.0, 2.0) | "stomatal scheme: 1 Ball-Berry, 2 Medlyn" | "" | ""
    ballberry_slope::T = 9.0 | (0.1, 30.0) | "Ball-Berry slope" | "" | ""
    ballberry_intercept::T = 0.01 | (0.0, 1.0) | "Ball-Berry minimum stomatal conductance" | "mol H2O m-2 leaf s-1" | ""
    medlyn_slope::T = 9.0 | (0.1, 30.0) | "Medlyn slope" | "kPa^0.5" | ""
    medlyn_intercept::T = 0.001 | (0.0, 1.0) | "Medlyn minimum stomatal conductance" | "mol H2O m-2 leaf s-1" | ""
    boundary_layer_conductance::T = 2.0 | (1.0e-3, 100.0) | "effective leaf boundary-layer conductance" | "mol H2O m-2 leaf s-1" | ""
    minimum_vpd::T = 0.05 | (1.0e-4, 1.0) | "minimum VPD in the Medlyn equation" | "kPa" | ""
    minimum_lai::T = 1.0e-6 | (0.0, 1.0) | "minimum LAI used for leaf-area conversion" | "m2 m-2" | ""
    carbon_molar_mass::T = 12.011 | (12.0, 12.1) | "molar mass of carbon" | "g mol-1" | ""
    seconds_per_day::T = 86400.0 | (8.0e4, 9.0e4) | "seconds per day" | "s d-1" | ""
end
#! format: on

function define(params::stomatalConductance_STEMMUS, forcing, land, helpers)
    @unpack_nt z_zero ⇐ land.constants

    stemmus_leaf_assimilation = z_zero
    stemmus_stomatal_conductance = z_zero
    stemmus_stomatal_resistance = oftype(z_zero, Inf)
    stemmus_boundary_layer_conductance = params.boundary_layer_conductance
    stemmus_stomatal_method = params.stomatal_method
    stemmus_ballberry_slope = params.ballberry_slope
    stemmus_ballberry_intercept = params.ballberry_intercept
    stemmus_medlyn_slope = params.medlyn_slope
    stemmus_medlyn_intercept = params.medlyn_intercept
    stemmus_minimum_vpd = params.minimum_vpd

    @pack_nt begin
        (stemmus_leaf_assimilation, stemmus_stomatal_conductance,
        stemmus_stomatal_resistance, stemmus_boundary_layer_conductance,
        stemmus_stomatal_method, stemmus_ballberry_slope,
        stemmus_ballberry_intercept, stemmus_medlyn_slope,
        stemmus_medlyn_intercept, stemmus_minimum_vpd) ⇒ land.diagnostics
    end
    return land
end

function compute(params::stomatalConductance_STEMMUS, forcing, land, helpers)
    @unpack_stomatalConductance_STEMMUS params
    @unpack_nt begin
        (f_airT_day, f_VPD_day) ⇐ forcing
        (LAI, ambient_CO2) ⇐ land.states
        gpp_demand ⇐ land.diagnostics
        z_zero ⇐ land.constants
    end

    stemmus_leaf_assimilation = _stemmus_leaf_assimilation(
        gpp_demand, LAI, minimum_lai, carbon_molar_mass, seconds_per_day,
    )
    relative_humidity = _stemmus_relative_humidity(f_airT_day, f_VPD_day)
    stemmus_stomatal_conductance = _stemmus_stomatal_conductance(
        stomatal_method, stemmus_leaf_assimilation, ambient_CO2,
        f_VPD_day, relative_humidity, ballberry_slope,
        ballberry_intercept, medlyn_slope, medlyn_intercept, minimum_vpd,
    )
    stemmus_stomatal_resistance = stemmus_stomatal_conductance > z_zero ?
        inv(stemmus_stomatal_conductance) : oftype(z_zero, Inf)
    stemmus_boundary_layer_conductance = boundary_layer_conductance
    stemmus_stomatal_method = stomatal_method
    stemmus_ballberry_slope = ballberry_slope
    stemmus_ballberry_intercept = ballberry_intercept
    stemmus_medlyn_slope = medlyn_slope
    stemmus_medlyn_intercept = medlyn_intercept
    stemmus_minimum_vpd = minimum_vpd

    @pack_nt begin
        (stemmus_leaf_assimilation, stemmus_stomatal_conductance,
        stemmus_stomatal_resistance, stemmus_boundary_layer_conductance,
        stemmus_stomatal_method, stemmus_ballberry_slope,
        stemmus_ballberry_intercept, stemmus_medlyn_slope,
        stemmus_medlyn_intercept, stemmus_minimum_vpd) ⇒ land.diagnostics
    end
    return land
end

@inline function _stemmus_leaf_assimilation(gpp, lai, minimum_lai, carbon_molar_mass, seconds_per_day)
    leaf_area = max(lai, minimum_lai)
    return max(gpp, zero(gpp)) / (carbon_molar_mass * leaf_area) * 1.0e6 / seconds_per_day
end

@inline function _stemmus_relative_humidity(air_temperature, vpd)
    saturation_vapor_pressure = 0.6108 * exp(17.27 * air_temperature / (air_temperature + 237.3))
    return clamp(one(vpd) - max(vpd, zero(vpd)) / max(saturation_vapor_pressure, eps(typeof(vpd))), zero(vpd), one(vpd))
end

@inline function _stemmus_stomatal_conductance(
    method, assimilation, ambient_co2, vpd, relative_humidity,
    ballberry_slope, ballberry_intercept, medlyn_slope,
    medlyn_intercept, minimum_vpd,
)
    co2 = max(ambient_co2, oftype(ambient_co2, 1.0e-6))
    assimilation = max(assimilation, zero(assimilation))
    if method < oftype(method, 1.5)
        return max(
            ballberry_intercept,
            ballberry_intercept + ballberry_slope * assimilation * relative_humidity / co2,
        )
    end
    leaf_vpd = max(vpd, minimum_vpd)
    return max(
        medlyn_intercept,
        medlyn_intercept + 1.6 * (one(method) + medlyn_slope / sqrt(leaf_vpd)) * assimilation / co2,
    )
end

purpose(::Type{stomatalConductance_STEMMUS}) =
    "Daily big-leaf Ball-Berry or Medlyn conductance for the STEMMUS-PHS coupling."

@doc """
$(getModelDocString(stomatalConductance_STEMMUS))

The MATLAB model solves sunlit and shaded leaves separately. SINDBAD has no
SCOPE leaf-angle and within-canopy radiation state, so this approach preserves
the Ball-Berry/Medlyn equations after aggregating assimilation to one daily
effective leaf.
"""
stomatalConductance_STEMMUS
