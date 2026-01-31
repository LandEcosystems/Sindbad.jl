## Installation

In the Julia REPL type:

```julia
using Pkg
Pkg.add("Sindbad")
```

or install `main` with the latest changes

````julia
julia> ]
pkg > add https://github.com/LandEcosystems/Sindbad.jl.git
````

The ] character starts the Julia package manager. Hit backspace key to return to Julia prompt.

## Check installation

Check SINDBAD version with:

````julia
julia> ]
pkg > st Sindbad
````

## Start using Sindbad.Simulation

Sindbad comes with several predefined models, which you can use individually or in combination.

```julia
using Sindbad.Simulation
```