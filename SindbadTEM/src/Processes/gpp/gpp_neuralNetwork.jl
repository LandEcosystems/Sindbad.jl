export gpp_neuralNetwork

struct gpp_neuralNetwork <: gpp end

purpose(::Type{gpp_neuralNetwork}) = "GPP predicted directly by a pretrained neural network model. `define`, `precompute`, and `compute` for this approach are implemented in the `SindbadFluxExt` package extension (activates once `using Flux` is loaded alongside `using Sindbad`)."

@doc """

$(getModelDocString(gpp_neuralNetwork))

---

# Extended help

*References*

*Versions*
 - 1.0 on 06.08.2026 [skoirala]

*Created by*
 - skoirala

*Notes*
This approach requires `using Flux` to be loaded (it activates the `SindbadFluxExt`
extension, which provides the real `define`/`precompute`/`compute` methods). Without
Flux loaded, this approach silently falls back to the generic `LandEcosystem` no-op
methods rather than erroring.

Configuration for the underlying model is read from `helpers.hybrid.process_ml_models.gpp`,
which is populated from the `hybrid.process_ml_models.gpp` section of `experiment.json`.
"""
gpp_neuralNetwork
