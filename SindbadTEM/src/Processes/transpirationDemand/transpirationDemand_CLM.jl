export transpirationDemand_CLM

#! format: off
@bounds @describe @units @timescale @with_kw struct transpirationDemand_CLM{T} <: transpirationDemand
    canopy_dry_fraction::T = 1.0 | (0.0, 1.0) | "fraction of foliage that is dry and transpiring" | "" | "CLM fdry; constant because SINDBAD has no fdry state"
    stem_to_leaf_area_ratio::T = 0.1 | (0.001, 2.0) | "effective SAI to LAI ratio" | "" | "represents CLM elai plus esai in getqflx"
    water_molar_mass::T = 0.01801528 | (0.018, 0.019) | "molar mass of water" | "kg mol-1" | ""
    seconds_per_day::T = 86400.0 | (8.0e4, 9.0e4) | "seconds per day" | "s d-1" | ""
end
#! format: on

function compute(params::transpirationDemand_CLM, forcing, land, helpers)
    @unpack_transpirationDemand_CLM params
    @unpack_nt begin
        (f_psurf_day, f_VPD_day) ⇐ forcing
        LAI ⇐ land.states
        (clm_gs_mol_unstressed, clm_gb_mol) ⇐ land.diagnostics
        z_zero ⇐ land.constants
    end
    gb = max(clm_gb_mol, z_zero)
    gs = max(clm_gs_mol_unstressed, z_zero)
    series_conductance = gb + gs > z_zero ? gb * gs / (gb + gs) : z_zero
    vapor_gradient = max(f_VPD_day, z_zero) / max(f_psurf_day, eps(typeof(f_psurf_day)))
    # Collapsed form of CLM getqflx. Conductance is converted from umol to mol;
    # kg H2O m-2 equals mm H2O.
    exposed_vegetation_area = max(LAI, z_zero) * (1 + stem_to_leaf_area_ratio)
    transpiration_demand = canopy_dry_fraction * exposed_vegetation_area *
        series_conductance * 1.0e-6 * vapor_gradient *
        water_molar_mass * seconds_per_day
    clm_transpiration_demand = transpiration_demand
    @pack_nt begin
        (transpiration_demand, clm_transpiration_demand) ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{transpirationDemand_CLM}) =
    "Unstressed single-leaf transpiration demand from the CLM5 getqflx conductance equation."

@doc """
$(getModelDocString(transpirationDemand_CLM))

Implements the gas-diffusion part of CLM `getqflx` for one canopy leaf class:
boundary-layer and stomatal conductances act in series and the water-vapour
gradient is represented by daily VPD divided by surface pressure. Effective
exposed vegetation area is `LAI + SAI`, matching CLM's `elai + esai` term.
"""
transpirationDemand_CLM
