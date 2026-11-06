export gppDiffRadiation_De2025_Enhancement

#! format: off
@bounds @describe @units @timescale @with_kw struct gppDiffRadiation_De2025_Enhancement{T1,T2} <: gppDiffRadiation
    α::T1 = 0.4 | (0.0, 2.0) | "relative enhancement of LUE at CI = 1 over LUE at CI = 0" | "" | ""
    μ::T2 = 1.0 | (0.2, 5.0) | "shape exponent of the response to cloudiness index" | "" | ""
end
#! format: on

function precompute(params::gppDiffRadiation_De2025_Enhancement, forcing, land, helpers)
    ## unpack parameters
    @unpack_gppDiffRadiation_De2025_Enhancement params
    ## calculate variables
    gpp_f_cloud = one(α)
    ## pack land variables
    @pack_nt gpp_f_cloud ⇒ land.diagnostics
    return land
end

function compute(params::gppDiffRadiation_De2025_Enhancement, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_gppDiffRadiation_De2025_Enhancement params
    @unpack_nt (f_rg, f_rg_pot) ⇐ forcing
    @unpack_nt z_zero ⇐ land.constants

    ## calculate variables
    rg_frac = safe_divide(f_rg, f_rg_pot)
    CI = clamp_zero_one(one(rg_frac) - rg_frac)

    # branch at CI = 0 keeps the derivative with respect to μ finite, as 0^μ would
    # need log(0)
    CI_μ = CI > zero(CI) ? CI ^ μ : zero(CI) * zero(μ)

    cScGPP = one(α) + α * CI_μ
    # no enhancement without potential radiation
    gpp_f_cloud = f_rg_pot > z_zero ? cScGPP : one(cScGPP)

    ## pack land variables
    @pack_nt gpp_f_cloud ⇒ land.diagnostics
    return land
end

purpose(::Type{gppDiffRadiation_De2025_Enhancement}) = "Cloudiness as an enhancement of GPP potential, 1 + α CI^μ, with values of 1 at CI = 0 and 1 + α at CI = 1."

@doc """

$(getModelDocString(gppDiffRadiation_De2025_Enhancement))

---

# Extended help

gpp_f_cloud = 1 + α * CI^μ, where CI = 1 - f_rg/f_rg_pot is the cloudiness index.
CI = 0 gives 1 and CI = 1 gives 1 + α. μ < 1 makes the enhancement saturate under
light cloud, μ = 1 is linear, and μ > 1 limits it to heavy cloud.

The scalar exceeds 1, so it suits gppDemand_mult. With gppDemand_min it is never the
minimum and has no effect. Under this framing gpp_potential is the clear sky
potential, not the maximum under diffuse light.

Reported enhancements of overcast over clear sky LUE at equal PAR are 6 to 33% for
forests in Alton et al. (2007), 12 to 80% across 38 FLUXNET sites in Alton (2008), and
30 to 45% for winter wheat in van Diepen et al. (2025). Observed CI only spans about
0.25 under clear sky to 0.83 under overcast in van Diepen et al. (2025), so with
μ = 1 these enhancements need α of about 0.1 to 2.1, which sets the bounds of α.

*References*
 - Alton, P. B., North, P. R., & Los, S. O. (2007). The impact of diffuse sunlight on canopy light-use efficiency, gross photosynthetic product and net ecosystem exchange in three forest biomes. Global Change Biology, 13[4], 776-787.
 - Alton, P. B. (2008). Reduced carbon sequestration in terrestrial ecosystems under overcast skies compared to clear skies. Agricultural and Forest Meteorology, 148[10], 1641-1653.
 - Gu, L., Baldocchi, D. D., Wofsy, S. C., Munger, J. W., Michalsky, J. J., Urbanski, S. P., & Boden, T. A. (2003). Response of a deciduous forest to the Mount Pinatubo eruption: enhanced photosynthesis. Science, 299[5615], 2035-2038. DOI: 10.1126/science.1078366
 - Knohl, A., & Baldocchi, D. D. (2008). Effects of diffuse radiation on canopy gas exchange processes in a forest ecosystem. Journal of Geophysical Research: Biogeosciences, 113, G02023. DOI: 10.1029/2007JG000663
 - van Diepen, K. H. H., Kaiser, E., Hartogensis, O. K., Graf, A., Vilà-Guerau de Arellano, J., & Moene, A. F. (2025). When do clouds and aerosols lead to higher canopy photosynthesis? Agricultural and Forest Meteorology, 370, 110597. DOI: 10.1016/j.agrformet.2025.110597
 - Mercado, L. M., Bellouin, N., Sitch, S., Boucher, O., Huntingford, C., Wild, M., & Cox, P. M. (2009). Impact of changes in diffuse radiation on the global land carbon sink. Nature, 458[7241], 1014-1017. DOI: 10.1038/nature07949

*Versions*
 - 1.0 on 27.10.2026 [skoirala | @dr-ko]: variant of gppDiffRadiation_exp with cloudiness as an enhancement

*Created by*
 - skoirala
"""
gppDiffRadiation_De2025_Enhancement
