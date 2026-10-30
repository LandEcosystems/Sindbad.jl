# Forcing Configuration

The `forcing.json` file configures the input dataset for SINDBAD experiments, defining how forcing data is processed and integrated into model runs.

## Data Dimensions

The `data_dimension` section specifies the structure of input forcing datasets, enabling proper data processing for spatial and temporal operations.

:::tabs

== Explanation
```json
"data_dimension": {
    "time": "Name of the time dimension in the dataset",
    "permute": "Order of dimensions in the processed data",
    "space": "List of spatial dimensions"
}
```

== Example
```json
"data_dimension": {
    "time": "time",
    "permute": ["time", "longitude", "latitude"],
    "space": ["longitude", "latitude"]
}
```
:::

## Default Forcing Settings

The `default_forcing` section defines default attributes for all forcing variables. These settings apply unless overridden in individual variable configurations.

:::tabs

== Explanation
```json
"default_forcing": {
    "additive_unit_conversion": "Flag for additive (true) or multiplicative (false) unit conversion",
    "bounds": "Valid data range after unit conversion",
    "data_path": "Path to the data file (absolute or relative to experiment base)",
    "depth_dimension": "Name of depth dimension (null if none)",
    "is_categorical": "Flag for categorical variables",
    "standard_name": "Descriptive variable name",
    "sindbad_unit": "Unit used within SINDBAD",
    "source_product": "Data source identifier",
    "source_to_sindbad_unit": "Unit conversion factor",
    "source_unit": "Original data unit",
    "source_variable": "Variable name in source file",
    "space_time_type": "Data type classification"
}
```

== Example
```json
"default_forcing": {
    "additive_unit_conversion": false,
    "bounds": [],
    "data_path": "../data/BE-Vie.1979.2017.daily.nc",
    "depth_dimension": null,
    "is_categorical": false,
    "standard_name": null,
    "sindbad_unit": null,
    "source_product": "FLUXNET",
    "source_to_sindbad_unit": 1,
    "source_unit": null,
    "source_variable": null,
    "space_time_type": "spatiotemporal"
}
```
:::

## Spatial Subsetting

The `forcing_mask` section configures spatial subsetting of forcing data, enabling experiments on specific regions without creating new datasets.

:::tabs

== Explanation
```json
"forcing_mask": {
    "data_path": "Path to the mask file",
    "source_variable": "Mask variable name in the file"
}
```

== Example
```json
"forcing_mask": {
    "data_path": null,
    "source_variable": null
}
```
:::

::: info Note
Temporal subsetting is configured in the `time` section of `experiment.json`.
:::

## Resampling to a Target Resolution

The `target_resolution` section puts all forcing variables on the space grid of one variable and the time axis of another. Each variable is resampled with its `interpolation_method`, set in `default_forcing` or for the variable. A method is a name, or a group with the name in `method` and its options. The setting of a variable for an axis replaces that of `default_forcing` as a whole. Without a method, `"none"`, a variable keeps its own grid or time axis.

:::tabs

== Explanation
```json
"target_resolution": {
    "space": {"variable": "Variable whose space grid is the target", "apply": "false skips the space resampling"},
    "time": {"variable": "Variable whose time axis is the target", "apply": "false skips the time resampling"}
},
"default_forcing": {
    "interpolation_method": {
        "space": "Method name, or a group with method and options",
        "time": "Method name, or a group with method and options"
    }
}
```

== Example
```json
"target_resolution": {
    "space": {"variable": "f_pft", "apply": true},
    "time": {"variable": "f_airT", "apply": true}
},
"default_forcing": {
    "interpolation_method": {
        "space": "zhao2004",
        "time": {"method": "cubic", "boundary": "flat", "extrapolation": "nan"}
    }
},
"variables": {
    "f_pft": {"interpolation_method": {"space": "nearest"}}
}
```
:::

Space and time have separate methods, so `interpolation_method.space` takes only space methods and `interpolation_method.time` only time methods.

**Space methods**

| Method | Options | Notes |
|:--|:--|:--|
| `none` | | no resampling |
| `nearest`, `constant` | `extrapolation` | value of the nearest grid |
| `linear` | `extrapolation` | linear along each axis |
| `quadratic`, `cubic` | `boundary`, `grid`, `extrapolation` | B-spline fitted to the whole field, so one invalid value makes the whole field invalid |
| `lanczos` | `order`, `extrapolation` | Lanczos with `order` lobes, 4 by default |
| `lanczos_opencv` | `extrapolation` | Lanczos of order 4 as in OpenCV |
| `zhao2004` | `power` | weights the four surrounding grids by cos(π/2 d/d_max)^`power` of their great-circle distance, equations 3 to 5 of Zhao et al. 2005, Remote Sensing of Environment 95; `power` is 4 by default |

**Time methods**

| Method | Options | Notes |
|:--|:--|:--|
| `none` | | no resampling |
| `nearest`, `constant` | `extrapolation` | nearest value in time |
| `previous`, `next` | `extrapolation` | previous or next value in time |
| `linear` | `extrapolation` | linear |
| `quadratic`, `cubic` | `boundary`, `grid`, `extrapolation` | B-spline fitted to the whole series, so one invalid value makes the whole series invalid |
| `lanczos` | `order`, `extrapolation` | Lanczos with `order` lobes, 4 by default |
| `lanczos_opencv` | `extrapolation` | Lanczos of order 4 as in OpenCV |
| `linear_monotonic`, `finite_difference_monotonic`, `fritsch_carlson_monotonic`, `fritsch_butland_monotonic`, `steffen_monotonic`, `akima_monotonic` | `extrapolation` | monotonic methods on the time coordinates |
| `cardinal_monotonic` | `tension`, `extrapolation` | `tension` from 0 to 1, 0 by default |

The options take these values, with the default first:
- `extrapolation`: `flat`, `line`, `periodic`, `reflect`, `throw`, `nan`
- `boundary`: `line`, `flat`, `free`, `periodic`, `reflect`
- `grid`: `on_grid`, `on_cell`

A name is written in snake case, and the first letter of each word may be upper case, so `"Linear"` and `"linear"` are the same method. Parameter maps that vary in time take the time methods in their `interpolation_method.time`, with `previous` as the default.

::: tip Custom methods
A method is a type: add a subtype of `SpaceInterpolationMethod` or `TimeInterpolationMethod` with its options as fields in `src/Types/InputTypes.jl`, and a method of `resampleValues!` in `src/DataLoaders/resampleCube.jl`. `resampleValues!` gets the source values with the coordinates and cell bounds of every resampled axis, so a space method can combine latitude and longitude, and a method can keep the sums or means of cells. The name in the settings is the type name without `SpaceInterp` or `TimeInterp` in snake case, e.g. `SpaceInterpZhao2004` is `"zhao2004"`.
:::

## Variable Configuration

The `variables` section lists all forcing variables required for the experiment. Only settings that differ from `default_forcing` need to be specified.

:::tabs

== Explanation
```json
"variables": {
    "f_variable_name": {
        "bounds": "Valid range for the variable",
        "standard_name": "Descriptive name",
        "sindbad_unit": "SINDBAD unit",
        "source_unit": "Original unit",
        "source_variable": "Variable name in source file"
    }
}
```

== Example
```json
"variables": {
    "f_ambient_CO2": {
        "bounds": [200, 500],
        "standard_name": "ambient_CO2",
        "sindbad_unit": "ppm",
        "source_unit": "ppm",
        "source_variable": "atmCO2_SCRIPPS_global"
    },
    "f_clay": {
        "bounds": [0.0, 100.0],
        "standard_name": "CLAY",
        "sindbad_unit": "-",
        "source_product": "soilgrids",
        "source_to_sindbad_unit": 0.01,
        "source_unit": "%",
        "source_variable": "CLYPPT_SoilGrids",
        "space_time_type": "spatiovertical"
    }
}
```
:::

::: tip Variable Naming Convention
- Use `f_` prefix for forcing variables loaded from data files
- This convention distinguishes them from variables computed within SINDBAD
:::

::: warning Data Validation
- Values outside specified bounds are truncated, not replaced with NaN
- Ensure all required variables are available in the forcing dataset
- Verify unit conversions and data types match model requirements
:::
