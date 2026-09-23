export transpirationDemand_STEMMUS

#! format: off
@bounds @describe @units @timescale @with_kw struct transpirationDemand_STEMMUS{T} <: transpirationDemand
    water_molar_mass::T = 0.01801528 | (0.018, 0.019) | "molar mass of water" | "kg mol-1" | ""
    seconds_per_day::T = 86400.0 | (8.0e4, 9.0e4) | "seconds per day" | "s d-1" | ""
    minimum_pressure::T = 1.0e-6 | (0.0, 1.0) | "minimum atmospheric pressure" | "kPa" | ""
end
#! format: on

function define(params::transpirationDemand_STEMMUS, forcing, land, helpers)
    @unpack_nt z_zero ⇐ land.constants
    transpiration_demand = z_zero
    stemmus_transpiration_demand = z_zero
    stemmus_canopy_conductance = z_zero
    @pack_nt begin
        (transpiration_demand, stemmus_transpiration_demand,
        stemmus_canopy_conductance) ⇒ land.diagnostics
    end
    return land
end

function compute(params::transpirationDemand_STEMMUS, forcing, land, helpers)
    @unpack_transpirationDemand_STEMMUS params
    @unpack_nt begin
        (f_VPD_day, f_psurf_day) ⇐ forcing
        LAI ⇐ land.states
        (stemmus_stomatal_conductance,
        stemmus_boundary_layer_conductance) ⇐ land.diagnostics
    end

    stemmus_transpiration_demand, stemmus_canopy_conductance =
        _stemmus_transpiration_from_conductance(
            stemmus_stomatal_conductance,
            stemmus_boundary_layer_conductance,
            LAI,
            f_VPD_day,
            f_psurf_day,
            water_molar_mass,
            seconds_per_day,
            minimum_pressure,
        )
    transpiration_demand = stemmus_transpiration_demand

    @pack_nt begin
        (transpiration_demand, stemmus_transpiration_demand,
        stemmus_canopy_conductance) ⇒ land.diagnostics
    end
    return land
end

@inline function _stemmus_transpiration_from_conductance(
    stomatal_conductance, boundary_conductance, lai, vpd, pressure,
    water_molar_mass, seconds_per_day, minimum_pressure,
)
    gs = max(stomatal_conductance, zero(stomatal_conductance))
    gb = max(boundary_conductance, zero(boundary_conductance))
    canopy_conductance = gs + gb > zero(gs) ? gs * gb / (gs + gb) : zero(gs)
    vapor_gradient = max(vpd, zero(vpd)) / max(pressure, minimum_pressure)
    transpiration = max(lai, zero(lai)) * canopy_conductance * vapor_gradient *
        water_molar_mass * seconds_per_day
    return max(transpiration, zero(transpiration)), canopy_conductance
end

purpose(::Type{transpirationDemand_STEMMUS}) =
    "Daily unstressed canopy transpiration demand for the STEMMUS-PHS iteration."

@doc """
$(getModelDocString(transpirationDemand_STEMMUS))

This is the daily big-leaf counterpart of the STEMMUS-SCOPE canopy latent-heat
calculation. Stomatal and boundary-layer conductances act in series; VPD over
surface pressure supplies the water-vapour mole-fraction gradient.
"""
transpirationDemand_STEMMUS
