export cCycleBase, adjustPackPoolComponents

abstract type cCycleBase <: LandEcosystem end

purpose(::Type{cCycleBase}) = "Defines the base properties of the carbon cycle components. For example, components of carbon pools, their turnover rates, and flow matrix."

"""
    adjustPackPoolComponents(land, helpers, ::cCycleBase)

Scatter the combined `cEco` vector back into every component pool it is built from,
and pack the results into `land.pools`.

Defined once for every `cCycleBase` approach. `setComponentFromMainPool` generates
the unrolled scatter from the pool names an experiment actually configured, so an
approach that adds, drops or renames a pool needs no method of its own.

`all_components` is every key of the element's `zix` except `cEco` itself, which is
both the main pools and the leaf pools.
"""
function adjustPackPoolComponents(land, helpers, ::cCycleBase)
    return setComponentFromMainPool(land, helpers,
        helpers.pools.vals.self.cEco,
        helpers.pools.vals.all_components.cEco,
        helpers.pools.vals.zix.cEco)
end

# Pool structures and flow topologies the approaches below declare against. Included
# explicitly because includeApproaches globs `cCycleBase_*.jl` and skips this name.
include("poolConfigurations.jl")

includeApproaches(cCycleBase, @__DIR__)

@doc """ 
	$(getModelDocString(cCycleBase))
"""
cCycleBase
