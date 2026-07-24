export cFireMortality_vanDerWerf2004

@with_kw struct cFireMortality_vanDerWerf2004{T1, T2, T3, T4} <: cFireMortality
    a::T1 = 0.01f0
    b::T2 = 0.59f0
    c::T3 = 0.6f0
    d::T4 = 0.25f0
end

function define(params::cFireMortality_vanDerWerf2004, forcing, land, helpers)
    # @unpack_cFireMortality_vanDerWerf2006 params
    ## instantiate variables
    @unpack_nt begin
        cEco ⇐ land.pools
    end
    c_Fire_k = one.(cEco)
    ## pack land variables
    @pack_nt begin
        c_Fire_k ⇒ land.diagnostics
    end
    return land
end

function compute(params::cFireMortality_vanDerWerf2004, forcing, land, helpers)
    @unpack_cFireMortality_vanDerWerf2004 params

    @unpack_nt begin
        c_Fire_k ⇐ land.diagnostics
        frac_tree ⇐ land.states
        zix ⇐ helpers.pools
        (z_zero, o_one) ⇐ land.constants
    end
    # fire mortality according to Guido's paper
    mortality = a + (b / (o_one + exp((c - frac_tree) * d)))
    # wood mortality (wood / forest biomass lost)
    for izix in zix.cVegWood
        @rep_elem mortality ⇒ (c_Fire_k, izix, :cEco)
    end

    # for the other vegetation pools the mortality scales with the frac_tree, we assume all the pools in grass have a mortality of 𝟙
    mortSplit = mortality * frac_tree + o_one * (o_one - frac_tree)
    for c_izix in (zix.cVegRoot, zix.cVegLeaf, zix.cVegReserve)
        for izix in c_izix
            @rep_elem mortSplit ⇒ (c_Fire_k, izix, :cEco)
        end
    end

    @pack_nt begin
        c_Fire_k ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cFireMortality_vanDerWerf2004}) = "Uses the van der Werf et al. (2004) method to calculate fire mortality."

@doc """

$(getModelDocString(cFireMortality_vanDerWerf2004))

---

# Extended help

*Created by*
  - Nuno | nunocarvalhais
"""
cFireMortality_vanDerWerf2004