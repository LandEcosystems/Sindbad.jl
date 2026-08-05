export cAllocationRadiation_GSI

#! format: off
@bounds @describe @units @timescale @with_kw struct cAllocationRadiation_GSI{T1,T2,T3} <: cAllocationRadiation
    τ_rad::T1 = 0.02 | (0.001, 1.0) | "temporal change rate for the light-limiting function" | "" | ""
    slope_rad::T2 = 1.0 | (0.01, 200.0) | "slope parameters of a logistic function based on mean daily y shortwave downward radiation" | "" | ""
    base_rad::T3 = 10.0 | (0.0, 100.0) | "inflection point parameters of a logistic function based on mean daily y shortwave downward radiation" | "" | ""
end
#! format: on

function define(params::cAllocationRadiation_GSI, forcing, land, helpers)
    ## unpack helper
    @unpack_cAllocationRadiation_GSI params

    ## calculate variables
    # assume the initial c_allocation_c_allocation_f_cloud as one
    c_allocation_f_cloud_prev = one(slope_rad)

    ## pack land variables
    @pack_nt c_allocation_f_cloud_prev ⇒ land.diagnostics
    return land
end

function compute(params::cAllocationRadiation_GSI, forcing, land, helpers)
    ## unpack parameters and forcing
    @unpack_cAllocationRadiation_GSI params
    @unpack_nt f_PAR ⇐ forcing

    ## unpack land variables
    @unpack_nt begin
        c_allocation_f_cloud_prev ⇐ land.diagnostics
        (z_zero, o_one) ⇐ land.constants
    end
    ## calculate variables
    # computation for the radiation effect on decomposition/mineralization
    c_allocation_c_allocation_f_cloud = (one(slope_rad) / (one(slope_rad) + exp(-slope_rad * (f_PAR - base_rad))))
    c_allocation_c_allocation_f_cloud = c_allocation_f_cloud_prev + (c_allocation_c_allocation_f_cloud - c_allocation_f_cloud_prev) * τ_rad
    # set the prev
    c_allocation_f_cloud_prev = c_allocation_c_allocation_f_cloud

    ## pack land variables
    @pack_nt (c_allocation_c_allocation_f_cloud, c_allocation_f_cloud_prev) ⇒ land.diagnostics
    return land
end

purpose(::Type{cAllocationRadiation_GSI}) = "Calculates the radiation effect on allocation using the GSI method."

@doc """

$(getModelDocString(cAllocationRadiation_GSI))

---

# Extended help

*References*
 - Forkel M, Carvalhais N, Schaphoff S, von Bloh W, Migliavacca M, Thurner M, Thonicke K [2014] Identifying environmental controls on vegetation greenness phenology through model–data integration. Biogeosciences, 11, 7025–7050.
 - Forkel, M., Migliavacca, M., Thonicke, K., Reichstein, M., Schaphoff, S., Weber, U., Carvalhais, N. (2015).  Codominant water control on global interannual variability and trends in land surface phenology & greenness.
 - Jolly, William M., Ramakrishna Nemani, & Steven W. Running. "A generalized, bioclimatic index to predict foliar phenology in response to climate." Global Change Biology 11.4 [2005]: 619-632.

*Versions*
 - 1.0 on 12.01.2020 [skoirala | @dr-ko]  

*Created by*
 - ncarvalhais, sbesnard, skoirala
"""
cAllocationRadiation_GSI
