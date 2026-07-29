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

full_dataset = YAXArrays.open_dataset(source_path)
year_2015 = full_dataset[time=(date_begin .. date_end)]

isdir(dest_path) && rm(dest_path; force=true, recursive=true)
YAXArrays.savedataset(year_2015; path=dest_path, driver=:zarr, overwrite=true)

@info "Wrote 2015 subset to $(dest_path)"
