export rootMaximumDepth_fracSoilD

#! format: off
@bounds @describe @units @timescale @with_kw struct rootMaximumDepth_fracSoilD{T1} <: rootMaximumDepth
    constant_frac_max_root_depth::T1 = 0.5 | (0.1, 0.8) | "root depth as a fraction of soil depth" | "" | ""
end
#! format: on

function define(params::rootMaximumDepth_fracSoilD, forcing, land, helpers)
    ## unpack parameters
    @unpack_rootMaximumDepth_fracSoilD params
    @unpack_nt soil_layer_thickness ⇐ land.properties
    ## calculate variables
    ∑soil_depth = sum(soil_layer_thickness)
    ## pack land variables
    @pack_nt begin
        ∑soil_depth ⇒ land.properties
    end
    return land
end

function precompute(params::rootMaximumDepth_fracSoilD, forcing, land, helpers)
    ## unpack parameters
    @unpack_rootMaximumDepth_fracSoilD params
    @unpack_nt soil_layer_thickness ⇐ land.properties
    ## calculate variables
    # sum here and not only in define, as define runs only for the first pixel
    ∑soil_depth = sum(soil_layer_thickness)
    # get the soil thickness & root distribution information from input
    max_root_depth = ∑soil_depth * constant_frac_max_root_depth
    # disp(["the maxRootD scalar: " constant_frac_max_root_depth])

    ## pack land variables
    @pack_nt begin
        ∑soil_depth ⇒ land.properties
        max_root_depth ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{rootMaximumDepth_fracSoilD}) = "Maximum rooting depth as a fraction of total soil depth."

@doc """

$(getModelDocString(rootMaximumDepth_fracSoilD))

---

# Extended help

*References*

*Versions*
 - 1.0 on 21.11.2019  

*Created by*
 - skoirala | @dr-ko
"""
rootMaximumDepth_fracSoilD
