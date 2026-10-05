export vegDynamics

abstract type vegDynamics <: LandEcosystem end

purpose(::Type{vegDynamics}) = "Obtains the raw vegetation-type class code for the pixel -- from forcing or a constant parameter -- and publishes it as land.states.veg_type for vegClass to resolve into a catalog-based classification."

includeApproaches(vegDynamics, @__DIR__)

@doc """
    $(getModelDocString(vegDynamics))

---

# Extended help

Split from the former, combined `vegClass` process so that obtaining the raw
class code (this process, catalog-agnostic) is independent of interpreting it
against a source legend and crosswalking it into a target classification
(`vegClass`, code-agnostic). Every approach here does exactly one thing: read a
raw numeric code, from `f_pft` in `forcing` or from a constant parameter, and
pack it into `land.states.veg_type`, unchanged and uninterpreted. No
approach in this process references a `VegClassification`.

`vegDynamics` must run before `vegClass` in the model's process order (see
`standardSindbadTEM.jl`), since `vegClass` reads `land.states.veg_type`
from `land.states` rather than unpacking `forcing` itself.

*Versions*
 - 1.0 on 11.09.2026 [skoirala]: split out of the former combined `vegTypes`
   process, which coupled raw-code extraction to catalog resolution
 - 2.0 on 12.09.2026 [skoirala]: renamed from `vegTypeDynamics` to
   `vegClassDynamics` (paired process `vegTypes` -> `vegClass`)
 - 3.0 on 12.09.2026 [skoirala]: renamed again, `vegClassDynamics` ->
   `vegDynamics` (too easily confused with `vegClass`)

*Created by*
 - skoirala
"""
vegDynamics
