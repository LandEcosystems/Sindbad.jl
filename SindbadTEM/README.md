# SindbadTEM.jl

[![][docs-stable-img]][docs-stable-url][![][docs-dev-img]][docs-dev-url][![][ci-img]][ci-url] [![][codecov-img]][codecov-url][![Julia][julia-img]][julia-url][![License: EUPLv1.2](https://img.shields.io/badge/License-EUPLv1.2-seagreen)](https://github.com/LandEcosystems/Sindbad/blob/main/LICENSE)

<img src="../docs/src/assets/sindbad_logo.png" align="right" style="padding-left:10px;" width="150"/>

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://landecosystems.github.io/Sindbad.jl/dev/

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://landecosystems.github.io/Sindbad.jl/stable/

[codecov-img]: https://codecov.io/gh/LandEcosystems/Sindbad/branch/main/graph/badge.svg
[codecov-url]: https://codecov.io/gh/LandEcosystems/Sindbad

[ci-img]: https://github.com/LandEcosystems/Sindbad/actions/workflows/SindbadTEM.yml/badge.svg
[ci-url]: https://github.com/LandEcosystems/Sindbad/actions/workflows/SindbadTEM.yml

[julia-img]: https://img.shields.io/badge/julia-v1.10+-blue.svg
[julia-url]: https://julialang.org/

## Overview

`SindbadTEM` is the core terrestrial ecosystem model (TEM) package of the **S**trategies to **IN**tegrate **D**ata and **B**iogeochemic**A**l mo**D**els (SINDBAD) framework.

At its core, `SindbadTEM` defines the `LandEcosystem` supertype and the process/approach interface used throughout SINDBAD (`define`, `precompute`, `compute`, `update`). It also ships a canonical variable catalog (`sindbad_tem_variables`) and utilities used by the higher-level `Sindbad` package.

## Features

- **Core types & interface**: `LandEcosystem` and supporting types in `SindbadTEM.TEMTypes`
- **Processes & approaches**: A process/approach library under `src/Processes/`
- **Variable catalog**: Canonical SINDBAD TEM variable metadata and helpers in `SindbadTEM.Variables`
- **Utilities**: Inspection/tooling helpers in `SindbadTEM.Utils`

## Installation

### From a Julia package registry (recommended)

```julia
using Pkg
Pkg.add("SindbadTEM")
```

If you want the full SINDBAD stack (data ingestion, experiment setup, simulation orchestration, optimization/ML tooling, visualization), install:

```julia
using Pkg
Pkg.add("Sindbad")
```

### From source (monorepo checkout)

`SindbadTEM` lives in the SINDBAD monorepo (`Sindbad/SindbadTEM`). Typical development setup:

```julia
using Pkg
Pkg.develop(path="path/to/Sindbad")              # top-level orchestration package
Pkg.develop(path="path/to/Sindbad/SindbadTEM")   # core TEM package from this repo
Pkg.instantiate()
```

## Quick start

```julia
using SindbadTEM

# Define a new model/approach type
struct MyModel <: LandEcosystem end

# Implement at least one of the required interface methods:
# define, precompute, compute, update
function define(params::MyModel, forcing, land, helpers)
    return land
end
```

Query metadata from the canonical variable catalog:

```julia
using SindbadTEM

# Catalog keys are symbols of the form :field__subfield
info = SindbadTEM.Variables.getVariableInfo(:fluxes__gpp, "day")
```

## Package layout

This package is included from `src/SindbadTEM.jl` and organized as:

- **`src/Types.jl`**: module `SindbadTEM.TEMTypes` (core types; includes `LandEcosystem`)
- **`src/Utils.jl`**: module `SindbadTEM.Utils` (inspection/tooling utilities)
- **`src/Variables.jl`**: module `SindbadTEM.Variables` (variable catalog + metadata helpers)
- **`src/Processes.jl`**: module `SindbadTEM.Processes` (process hierarchy + includes `src/Processes/*`)

## Dependencies

Key direct dependencies (installed automatically by Julia’s package manager) include:

- `OmniTools`
- `Accessors`
- `CodeTracking`
- `Crayons`
- `DataStructures`
- `FieldMetadata`
- `Flatten`
- `Parameters`
- `Reexport`
- `StaticArrays` / `StaticArraysCore`
- `StatsBase`

## Documentation

Comprehensive documentation is available at:
- **Stable**: https://landecosystems.github.io/Sindbad.jl/stable/
- **Development**: https://landecosystems.github.io/Sindbad.jl/dev/

## SINDBAD Contributors

SINDBAD is developed at the Department of Biogeochemical Integration of the Max Planck Institute for Biogeochemistry in Jena, Germany with active contributions from [Sujan Koirala](https://www.bgc-jena.mpg.de/person/skoirala/2206), [Xu Shan](https://www.bgc-jena.mpg.de/person/138641/2206), [Jialiang Zhou](https://www.bgc-jena.mpg.de/person/137086/2206), [Lazaro Alonso](https://www.bgc-jena.mpg.de/person/lalonso/2206), [Fabian Gans](https://www.bgc-jena.mpg.de/person/fgans/4777761), [Felix Cremer](https://www.bgc-jena.mpg.de/person/fcremer/2206), [Nuno Carvalhais](https://www.bgc-jena.mpg.de/person/ncarval/2206).

For a full list of current and previous contributors, see http://sindbad-mdi.org/pages/about/team.html

## Contributing

For contribution guidelines, please refer to the main [SINDBAD CONTRIBUTING.md](../CONTRIBUTING.md).

## Copyright and License

**SINDBAD: Strategies to Integrate Data and Biogeochemical Models**

**Copyright © 2025**  
Max-Planck-Gesellschaft zur Förderung der Wissenschaften

For copyright details, see the [NOTICE](./NOTICE) file.

---

### License

SINDBAD is free and open-source software, licensed under the [European Union Public License v1.2 (EUPL)](https://eupl.eu/1.2/en).

---

### Your Rights

You are free to:

- Copy, modify, and redistribute the code  
- Use the software as a package in your own projects, regardless of their license or copyright status  
- Apply the software in both commercial and non-commercial contexts

---

### Your Responsibilities

If you modify the code — excluding changes made solely for interoperability — you **must redistribute the modified version under the EUPL v1.2 or a compatible license**. This ensures the long-term sustainability of the project and supports an open, inclusive, and collaborative community.

---

### Disclaimer

This software is provided in the hope that it will be useful, but **without any warranty** — including, without limitation, the implied warranties of merchantability or fitness for a particular purpose.
