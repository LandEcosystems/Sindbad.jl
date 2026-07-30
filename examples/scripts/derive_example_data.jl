using YAXArrays
using Dates

# Slices one calendar year (2015) out of the full FLUXNET_v2023_12_1D_REPLACED_Noise003_v1.zarr
# cube (site x time) and writes it locally so the `setups/LUE` and `setups/WROASTED` examples
# have a small, fast dataset to run against.
#
# `source_path` currently points at a local copy of the source cube. Once this derived file is
# uploaded to the sindbad S3 bucket, the setups' `forcing.json`/`optimization.json` will be
# updated to read `synthetic_data_examples.zarr` directly from there instead of from
# `examples/data/` (which is git-ignored and not meant to be committed).
source_path = get(ENV, "SINDBAD_TUTORIALS_DATA_DEPOT", nothing)
if isnothing(source_path)
    error(
        "Set the SINDBAD_TUTORIALS_DATA_DEPOT environment variable to the local path of " *
        "FLUXNET_v2023_12_1D_REPLACED_Noise003_v1.zarr before running this script.",
    )
end
source_path = joinpath(source_path, "FLUXNET_v2023_12_1D_REPLACED_Noise003_v1.zarr")

dest_path = joinpath(@__DIR__, "..", "data", "synthetic_data_examples.zarr")

date_begin = DateTime(2015, 1, 1)
date_end = DateTime(2015, 12, 31)

# Only the variables actually referenced (as `source_variable`) by setups/LUE and
# setups/WROASTED's forcing.json/optimization.json, restricted to the observational_constraints
# each optimization.json actually reads. All raw (non-gap-filled) FLUXNET tower variables and
# their `_QC*`/`_RANDUNC` companions are deliberately excluded: real tower coverage in this cube
# ends around 2014, so every `_QC*`/`_RANDUNC` variable is 100% NaN for 2015 regardless of site.
# Keeping only this list gives a small, gap-free dataset instead of a mostly-empty one.
keep_variables = [
    :atmCO2_SCRIPPS_global, :CLYPPT_SoilGrids, :dist_frac_sb2018, :fire_frac, :tree_frac,
    :veg_frac, :f_pft, :OCSTHA_SoilGrids, :SW_IN_ERAIv2_gfld, :P_ERAIv2_gfld,
    :SW_IN_POT_ONEFlux, :NETRAD_ERAIv2_gfld, :SNDPPT_SoilGrids, :SLTPPT_SoilGrids,
    :TA_ERAIv2_gfld, :TA_DayTime_ERAIv2_gfld, :VPD_ERAIv2_gfld, :VPD_DayTime_ERAIv2_gfld,
    :GPP_NT, :agb_merged_PFT, :LE, :NDVI_MCD43A, :NEE, :RECO_NT, :T_NT_TEA,
]

full_dataset = YAXArrays.open_dataset(source_path)
year_2015 = full_dataset[time=(date_begin .. date_end)]
minimal_year_2015 = YAXArrays.Dataset(;
    properties=year_2015.properties,
    (v => year_2015.cubes[v] for v in keep_variables)...,
)

isdir(dest_path) && rm(dest_path; force=true, recursive=true)
YAXArrays.savedataset(minimal_year_2015; path=dest_path, driver=:zarr, overwrite=true)

@info "Wrote 2015 subset to $(dest_path)"
