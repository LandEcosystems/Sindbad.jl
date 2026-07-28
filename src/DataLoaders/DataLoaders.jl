"""
    DataLoaders

The `DataLoaders` module provides tools for ingesting and preprocessing SINDBAD input data. It supports reading, cleaning, masking, and managing forcing/observation data with an emphasis on spatial and temporal dimensions.

# Purpose
Streamline the ingestion and preprocessing of input data for SINDBAD experiments.

# Dependencies
## Related (SINDBAD ecosystem)
- `OmniTools`: Utility functions for handling NamedTuples, printing, and shared helpers.

## External (third-party)
- `AxisKeys`: Labeled multidimensional arrays (`KeyedArray`).
- `DimensionalData`: Dimension-aware indexing/slicing.
- `FillArrays`: Efficient filled-array representations.
- `YAXArrays`, `YAXArrayBase`: Multidimensional array/cube abstractions used for IO and spatial data. `YAXArrays.open_dataset` reads both netcdf and zarr sources uniformly.
- `NetCDF`, `Zarr`: not called directly for I/O; merely having them loaded activates YAXArrayBase's `NetCDFExt`/`ZarrExt` backends that `open_dataset` dispatches to. `NetCDF` is also used directly by some example scripts via `DataLoaders.NetCDF.open`.

## Internal (within `Sindbad`)
- `Sindbad.Setup`
- `Sindbad.Types`
- `SindbadTEM`

# Included Files
- **`utilsDataLoaders.jl`**: Utility functions for data preprocessing (cleaning, masking, bounds checks).
- **`spatialSubset.jl`**: Spatial operations (extracting subsets based on spatial dimensions).
- **`getForcing.jl`**: Extracting and processing forcing data (environmental drivers).
- **`getObservation.jl`**: Reading and processing observational data for evaluation/validation.
- **`handleModelObsData.jl`**: Helpers for aligning forcing/observation/model outputs for cost evaluation.

# Notes
- The module uses `YAXArrays` directly; it does not re-export it.
- Designed to handle large datasets efficiently, leveraging chunked and compressed data formats like NetCDF and Zarr.
- Ensures compatibility with SINDBAD's experimental framework by integrating spatial and temporal data management tools.

"""
module DataLoaders
   using SindbadTEM
   using ..Setup
   using ..Types
   using SindbadTEM.OmniTools
   using AxisKeys: KeyedArray, AxisKeys
   using FillArrays
   using Dates
   using DimensionalData
   using DimensionalData: DimensionalData as DD
   using NetCDF
   using YAXArrayBase
   using YAXArrays: YAXArrays, Cube, YAXArray
   using YAXArrays.DAT: InDims
   using Zarr
   using TimeSamplers

   include("utilsDataLoaders.jl")
   include("spatialSubset.jl")
   include("getForcing.jl")
   include("getObservation.jl")
   include("handleModelObsData.jl")
   
end # module DataLoaders
