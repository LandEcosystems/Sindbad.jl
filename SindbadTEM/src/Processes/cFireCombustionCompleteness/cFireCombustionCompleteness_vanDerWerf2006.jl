export cFireCombustionCompleteness_vanDerWerf2006

#! format: off
@bounds @describe @units @timescale @with_kw struct cFireCombustionCompleteness_vanDerWerf2006{T1} <: cFireCombustionCompleteness
    fire_cc_scalar::T1 = 1.0 | (0.5, 2.0) | "scalar for the per-pool fire combustion completeness (ccMin/ccMax)" | "-" | ""
end
#! format: on

function define(params::cFireCombustionCompleteness_vanDerWerf2006, forcing, land, helpers)
    ## instantiate variables
    @unpack_nt begin
        cEco ⇐ land.pools
        zix ⇐ helpers.pools
        c_model ⇐ land.models
    end

    c_fire_ccMax = zero.(cEco)
    c_fire_ccMin = zero.(cEco)
    c_Fire_cci = zero.(cEco)
    c_Fire_cc_fW = zero.(cEco)

    # The fixed per-pool-name (ccMin, ccMax, weight) table for whichever
    # cCycleBase family is actually active, resolved once here since it is
    # structural, not a value precompute could ever change -- see fireCCTable
    # (poolConfigurations/poolConfigurations.jl) and its per-configuration
    # methods (CASA.jl/GSI.jl/MGMT.jl).
    fire_cc_table = fireCCTable(c_model)

    # zix_lit_soil_mic: every non-vegetation pool whose combustion completeness
    # is scaled by soil water in compute below (litter, soil, and microbial --
    # the microbial pools are new here; the old cc_lut-based code never gave
    # them any ccMin/ccMax at all, so they never combusted).
    zix_lit_soil_mic = (zix.cLit..., zix.cSoil..., zix.cMic...)

    ## pack land variables
    @pack_nt begin
        (c_fire_ccMin, c_fire_ccMax, c_Fire_cci, c_Fire_cc_fW, fire_cc_table) ⇒ land.diagnostics
        zix_lit_soil_mic ⇒ land.cFireCombustionCompleteness
    end
    return land
end

function precompute(params::cFireCombustionCompleteness_vanDerWerf2006, forcing, land, helpers)
    ## unpack parameters
    @unpack_cFireCombustionCompleteness_vanDerWerf2006 params

    ## unpack land variables
    @unpack_nt begin
        fire_cc_table ⇐ land.diagnostics
        (c_fire_ccMin, c_fire_ccMax) ⇐ land.diagnostics
    end

    ## calculate variables
    (c_fire_ccMin, c_fire_ccMax) = getFireCCFromParams(c_fire_ccMin, c_fire_ccMax, fire_cc_table, fire_cc_scalar, helpers)

    ## pack land variables
    @pack_nt (c_fire_ccMin, c_fire_ccMax) ⇒ land.diagnostics
    return land
end

function compute(params::cFireCombustionCompleteness_vanDerWerf2006, forcing, land, helpers)
    @unpack_cFireCombustionCompleteness_vanDerWerf2006 params
    ## unpack land variables
    @unpack_nt begin
        (c_fire_ccMin, c_fire_ccMax, c_Fire_cci, c_Fire_cc_fW ) ⇐ land.diagnostics
        gpp_f_soilW ⇐ land.diagnostics
        zix ⇐ helpers.pools
        soilW ⇐ land.pools
        ∑w_sat ⇐ land.properties
        (z_zero, o_one) ⇐ land.constants
        zix_lit_soil_mic ⇐ land.cFireCombustionCompleteness
    end

    totalSoilW = at_least_zero(totalS(soilW))
    soilW_nor = at_most_one(totalSoilW / ∑w_sat)

    # for all litter/soil/microbial pools c_Fire_cc_fW = soilW_nor
    for izix in zix_lit_soil_mic
        @rep_elem soilW_nor ⇒ (c_Fire_cc_fW, izix)
    end
    # for all veg pools c_Fire_cc_fW = gpp_f_soilW
    for zixVeg in zix.cVeg
        @rep_elem gpp_f_soilW ⇒ (c_Fire_cc_fW, zixVeg)
    end

    # for all cEco pools
    for zix_idx in zix.cEco
        cci = (c_fire_ccMax[zix_idx] - c_fire_ccMin[zix_idx]) * (o_one - c_Fire_cc_fW[zix_idx]) + c_fire_ccMin[zix_idx]
        @rep_elem cci ⇒ (c_Fire_cci, zix_idx)
    end

    # ## pack land variables
    @pack_nt begin
        (c_Fire_cci, c_Fire_cc_fW) ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cFireCombustionCompleteness_vanDerWerf2006}) = "Uses the van der Werf et al. (2006) method to calculate combustion completeness."

@doc """

$(getModelDocString(cFireCombustionCompleteness_vanDerWerf2006))

---

# Extended help

Combustion completeness used to be 7 hardcoded struct fields, one per
compartment (`fcc_stem`, `fcc_leaf`, `fcc_leaf_lit_m`, `fcc_leaf_lit_s`,
`fcc_sol`, `fcc_root`, `fcc_cwd`), each a `[min, max, prev, current]`
4-vector, mapped onto pool indices by a hardcoded `cc_lut` written against
GSI's pool shape (`cVegRoot`/`cVegWood`/`cVegReserve`/`cVegLeaf`). This is
now generalized onto the same fixed-table-plus-bounded-scalar pattern
`cCycleBase` uses for turnover and carbon-to-nitrogen ratio:
`CASA_FIRE_CC_VANDERWERF`/`GSI_FIRE_CC_VANDERWERF`
(`poolConfigurations/CASA.jl`/`GSI.jl`) hold the fixed `(ccMin, ccMax,
weight)` data, keyed by each configuration's own pool names; `fireCCTable`
(`poolConfigurations/poolConfigurations.jl`) resolves the right table for
whichever `cCycleBase` family is active at runtime, and `getFireCCFromParams`
scales both `ccMin`/`ccMax` by the single bounded `fire_cc_scalar` and
scatters them by pool name, the same convention `getKfromTau`/
`getCNfromParams` use. `weight` (an autoregressive filter weight) is carried
in the table but not yet read anywhere -- reserved for a future filtering
feature.

`GSI_FIRE_CC_VANDERWERF` is derived from `CASA_FIRE_CC_VANDERWERF`
(`deriveFireCCTable`), not hand-duplicated, which shifts `cLitFast`/
`cLitSlow`'s values slightly from what the old `cc_lut` gave GSI (`cLitFast`
`(0.9,1.0,0.9)` -> `(0.45,0.5,0.95)`, `cLitSlow` `(0.5,0.6,0.6)` ->
`(0.35,0.4,0.875)`, both before `fire_cc_scalar`), since CASA's finer
resolution distinguishes leaf litter (burns) from root-fine litter (does
not) where GSI's single `cLitFast`/`cLitSlow` pools cannot. Every other GSI
pool's value is unchanged.

The old `cc_lut` never gave microbial pools any `ccMin`/`ccMax` at all, so
they never combusted; `CASA_FIRE_CC_VANDERWERF` now does
(`cMicSurf`/`cMicSoil`), and `compute`'s soil-water-scaling loop was
extended to cover `zix.cMic` alongside litter/soil so those values actually
take effect instead of leaving `c_Fire_cc_fW` at its zero-init (which would
otherwise combust `cMicSurf` at `ccMax` unconditionally, every timestep).

The old `cc_lut`'s keys matched GSI's pool shape, not CASA's (CASA has no
undifferentiated `cVegRoot`/`cVegReserve` -- it has
`cVegRootFine`/`cVegRootCoarse`, no reserve pool at all), which is why this
approach was only ever tested under GSI (`reference_approaches`) and CASA was
a tracked `allowed_to_fail_approaches` mismatch. `fireCCTable`'s
per-configuration dispatch fixes that for CASA as well.

*Versions*
 - 1.0 [nunocarvalhais]: original hardcoded per-compartment struct and `cc_lut`
 - 2.0 on 15.09.2026 [skoirala]: generalized onto `cCycleBase`'s
   fixed-table-plus-bounded-scalar pattern, fixing the CASA pool-shape
   mismatch and extending soil-water scaling to microbial pools

*Created by*
  - Nuno | nunocarvalhais
"""
cFireCombustionCompleteness_vanDerWerf2006

