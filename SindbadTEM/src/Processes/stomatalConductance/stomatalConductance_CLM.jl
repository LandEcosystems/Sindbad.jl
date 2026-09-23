export stomatalConductance_CLM

#! format: off
@bounds @describe @units @timescale @with_kw struct stomatalConductance_CLM{T} <: stomatalConductance
    medlyn_intercept::T = 1.0e4 | (1.0, 1.0e6) | "minimum leaf stomatal conductance" | "umol H2O m-2 leaf s-1" | "CLM medlynintercept"
    medlyn_slope::T = 4.45 | (0.1, 20.0) | "Medlyn stomatal slope" | "kPa^0.5" | "CLM medlynslope"
    boundary_layer_conductance::T = 2.0e6 | (1.0e3, 1.0e8) | "leaf boundary-layer conductance" | "umol H2O m-2 leaf s-1" | "big-leaf replacement for CLM gb_mol"
    diffusivity_ratio::T = 1.6 | (1.0, 2.0) | "water-to-CO2 molecular diffusivity ratio" | "" | "CLM Medlyn coefficient"
    boundary_co2_ratio::T = 1.4 | (1.0, 2.0) | "boundary-layer CO2 diffusion coefficient" | "" | "CLM ci equation coefficient"
    minimum_vpd::T = 0.05 | (1.0e-4, 1.0) | "minimum leaf VPD" | "kPa" | "CLM 50 Pa lower bound"
    minimum_lai::T = 1.0e-3 | (0.0, 1.0) | "minimum LAI for leaf-area conversion" | "m2 m-2" | ""
    carbon_molar_mass::T = 12.011 | (12.0, 12.1) | "molar mass of carbon" | "g mol-1" | ""
    seconds_per_day::T = 86400.0 | (8.0e4, 9.0e4) | "seconds per day" | "s d-1" | ""
end
#! format: on

function define(params::stomatalConductance_CLM, forcing, land, helpers)
    @unpack_nt z_zero ⇐ land.constants
    clm_gs_mol_unstressed = z_zero
    clm_gs_mol_stressed = z_zero
    clm_gb_mol = params.boundary_layer_conductance
    clm_leaf_assimilation = z_zero
    @pack_nt begin
        (clm_gs_mol_unstressed, clm_gs_mol_stressed,
        clm_gb_mol, clm_leaf_assimilation) ⇒ land.diagnostics
    end
    return land
end

function compute(params::stomatalConductance_CLM, forcing, land, helpers)
    @unpack_stomatalConductance_CLM params
    @unpack_nt z_zero ⇐ land.constants
    # The actual Medlyn conductance is solved together with Ci and hydraulic
    # stress in plantHydraulics_CLM. This earlier process only supplies a safe
    # initial state for the standard SINDBAD process ordering.
    clm_leaf_assimilation = z_zero
    clm_gb_mol = max(boundary_layer_conductance, eps(typeof(boundary_layer_conductance)))
    clm_gs_mol_unstressed = max(medlyn_intercept, one(medlyn_intercept))
    clm_gs_mol_stressed = clm_gs_mol_unstressed
    @pack_nt begin
        (clm_gs_mol_unstressed, clm_gs_mol_stressed,
        clm_gb_mol, clm_leaf_assimilation) ⇒ land.diagnostics
    end
    return land
end

@inline function _clm_medlyn_conductance(
    assimilation, ambient_co2, pressure_kpa, vpd_kpa,
    boundary_conductance, intercept, slope,
    diffusivity_ratio, boundary_co2_ratio, minimum_vpd,
)
    if assimilation <= zero(assimilation)
        return max(intercept, one(intercept))
    end
    pressure_pa = max(pressure_kpa * 1000, eps(typeof(pressure_kpa)))
    cair_pa = max(ambient_co2, zero(ambient_co2)) * 1.0e-6 * pressure_pa
    surface_co2_pa = max(
        cair_pa - boundary_co2_ratio / boundary_conductance * assimilation * pressure_pa,
        oftype(cair_pa, 1.0e-5),
    )
    leaf_vpd = max(vpd_kpa, minimum_vpd)
    gb = boundary_conductance * 1.0e-6
    g0 = intercept * 1.0e-6
    term = diffusivity_ratio * assimilation /
        (surface_co2_pa / pressure_pa * 1.0e6)
    b = -(2 * (g0 + term) + (slope * term) ^ 2 / (gb * leaf_vpd))
    c = g0 ^ 2 +
        (2 * g0 + term * (one(term) - slope ^ 2 / leaf_vpd)) * term
    discriminant = max(b ^ 2 - 4 * c, zero(c))
    return max((-b + sqrt(discriminant)) / 2 * 1.0e6, one(intercept))
end

purpose(::Type{stomatalConductance_CLM}) =
    "Initial state for the Medlyn conductance solved inside the daily CLM hydraulic closure."

@doc """
$(getModelDocString(stomatalConductance_CLM))

The Medlyn quadratic helper follows `ci_func_PHS`. The coupled
`plantHydraulics_CLM` process calls it while solving Farquhar photosynthesis,
Ci, transpiration, and hydraulic stress. No prescribed GPP demand is used.
"""
stomatalConductance_CLM
