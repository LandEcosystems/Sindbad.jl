# Experiment Configuration

The `experiment.json` file serves as the primary configuration file for SINDBAD experiments, defining all necessary settings for model execution and data handling.

## Configuration Structure

The file is organized into several main sections:

### Basics

The `basics` section defines core experiment settings and metadata.

:::tabs

== Explanation
```json
"basics": {
    "config_files": {
      "forcing": "Name of the forcing data configuration file",
      "model_structure": "Name of the model structure configuration file",
      "optimization": "Name of the parameter optimization configuration file"
    },
    "domain": "Experiment domain identifier",
    "name": "Experiment name",
    "time": {
      "date_begin": "Start date of the experiment (YYYY-MM-DD)",
      "date_end": "End date of the experiment (YYYY-MM-DD)",
      "temporal_resolution": "Model simulation time step (one of: 'second', 'minute', 'hour', 'day', 'month', 'year', optionally prefixed with an integer count, e.g. '8-day', '6-hour')"
    }
}
```

== Example
```json
"basics": {
    "config_files": {
      "forcing": "forcing.json",
      "model_structure": "model_structure.json",
      "optimization": "optimization.json"
    },
    "domain": "FLUXNET",
    "name": "WROASTED",
    "time": {
      "date_begin": "1979-01-01",
      "date_end": "2017-12-31",
      "temporal_resolution": "day"
    }
}
```
:::

### Execution Rules

The `exe_rules` section defines model execution settings and performance configurations.

:::tabs

== Explanation
```json
"exe_rules": {
    "land_output_type": "Output array backend for model time series",
    "longtuple_size": "Length of the longtuple for model storage",
    "model_array_type": "Data backend for arrays/vectors within models",
    "model_number_type": "Numeric type used in models",
    "parallelization": "Parallelization backend for spatial operations",
    "tolerance": "Numerical tolerance for error checking",
    "yax_max_cache": "Cache size for YaxArray-based model runs"
}
```

== Example
```json
"exe_rules": {
    "land_output_type": "array",
    "longtuple_size": null,
    "model_array_type": "static_array",
    "model_number_type": "Float32",
    "parallelization": "threads",
    "tolerance": 1.0e-2,
    "yax_max_cache": 2e9
}
```
:::

### Flags

The `flags` section controls experiment execution modes and features. All fields accept boolean values (`true` or `false`).

:::tabs

== Explanation
```json
"flags": {
    "calc_cost": "Enable/disable cost calculation against observations",
    "catch_model_errors": "Stop execution on internal model errors",
    "debug_model": "Run single time step with diagnostics",
    "filter_nan_pixels": "Remove NaN pixels from input arrays",
    "inline_update": "Update model state within time step",
    "run_forward": "Enable forward model run",
    "run_optimization": "Enable parameter calibration",
    "save_info": "Save experiment info as JLD2 file",
    "spinup_TEM": "Enable model spinup",
    "store_spinup": "Save spinup sequence end states",
    "use_forward_diff": "Enable Dual type for ForwardDiff.jl"
}
```

== Example
```json
"flags": {
    "calc_cost": true,
    "catch_model_errors": false,
    "debug_model": false,
    "filter_nan_pixels": false,
    "inline_update": false,
    "run_forward": true,
    "run_optimization": true,
    "save_info": true,
    "spinup_TEM": true,
    "store_spinup": false,
    "use_forward_diff": false
}
```
:::

### Model Output

The `model_output` section configures output format, variables, and storage settings.

:::tabs

== Explanation
```json
"model_output": {
    "depth_dimensions": {
      "d_cEco": 8,
      "d_snow": "snowW"
    },
    "format": "Output format ('zarr' or 'nc')",
    "output_array_type": "Output array backend",
    "path": "Custom output path (null for default)",
    "plot_model_output": "Enable output plotting",
    "save_single_file": "Save all variables in one file",
    "variables": {
      "field.name:depth/layers": "Layer specification (null for 1 layer, string for depth dimension, or number for layers)"
    }
}
```

== Example
```json
"model_output": {
    "depth_dimensions": {
      "d_cEco": 8,
      "d_snow": "snowW",
      "d_soil": "soilW",
      "d_tws": "TWS"
    },
    "format": "zarr",
    "output_array_type": "array",
    "path": null,
    "plot_model_output": false,
    "save_single_file": true,
    "variables": {
      "diagnostics.auto_respiration_f_airT": null,
      "diagnostics.c_eco_k_f_soilW": "d_cEco",
      "diagnostics.root_water_efficiency": 4
    }
}
```
:::

::: info Variable Naming Convention

Variables follow the `field.subfield` convention of the `land` structure.

:::

### Model Spinup

The `model_spinup` section configures model initialization procedures.

:::tabs

== Explanation
```json
"model_spinup": {
    "restart_file": "Path to restart file (null for no restart)",
    "sequence": [
      {
        "forcing": "Forcing data source for sequence block",
        "n_repeat": "Number of sequence repetitions",
        "spinup_mode": "Models or methods to use in block"
      }
    ]
}
```

== Example
```json
"model_spinup": {
    "restart_file": null,
    "sequence": [
      {
        "forcing": "first_year",
        "n_repeat": 200,
        "spinup_mode": "all_forward_models"
      }
    ]
}
```
:::
