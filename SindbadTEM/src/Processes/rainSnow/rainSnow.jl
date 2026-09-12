export rainSnow

abstract type rainSnow <: LandEcosystem end

purpose(::Type{rainSnow}) = "Rain and snow partitioning."

includeApproaches(rainSnow, @__DIR__)

@doc """ 
	$(getModelDocString(rainSnow))
"""
rainSnow

# define a common update interface for all rainSnow models
function update(params::rainSnow, forcing, land, helpers)
    @unpack_rainSnow_Tair params

    ## unpack variables
    @unpack_nt begin
        snowW ⇐ land.pools
        ΔsnowW ⇐ land.pools
    end

    @add_to_elem ΔsnowW[1] ⇒ (snowW, 1, :snowW)

    # reset delta storage	
    @rep_elem zero(eltype(ΔsnowW)) ⇒ (ΔsnowW, 1)
    ## pack land variables
    @pack_nt begin
        snowW ⇒ land.pools
        ΔsnowW ⇒ land.pools
    end
    return land
end