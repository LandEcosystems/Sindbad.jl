export fAPAR_LAIBareFrac

#! format: off
@bounds @describe @units @timescale @with_kw struct fAPAR_LAIBareFrac{T1} <: fAPAR
	# k_extinction::T1 = 0.005 | (0.0005, 0.05) | "effective light extinction coefficient" | "" | ""
    k_extinction::T1 = 0.5 | (0.4, 0.7) | "effective light extinction coefficient" | "" | ""
end
#! format: on

function compute(params::fAPAR_LAIBareFrac, forcing, land, helpers)
	## Automatically generated sample code for basis. Modify, correct, and use. define, precompute, and update methods can use similar coding when needed. When not, they can simply be deleted. 
	@unpack_fAPAR_LAIBareFrac params # unpack the model parameters

    ## unpack land variables
    @unpack_nt begin
        LAI ⇐ land.states
        frac_vegetation ⇐ land.states
    end
    ## calculate variables
    fAPAR = one(k_extinction) - exp(-(LAI * k_extinction))
    fAPAR_bare = fAPAR * (one(k_extinction) - frac_vegetation) # ?  frac_vegetation -> (1 - frac_B_soil) 
    fAPAR = fAPAR * frac_vegetation
    # Cross check frac_vegetation from NetCDF files! 
    # TODO:  tree_frac (1km), Ranits's, mix, use table is available if not keep it!
    # 
    # ? make sure that frac_vegetation is consistent with Ranit's table!
    ## pack land variables
    @pack_nt begin
        (fAPAR_bare, fAPAR) ⇒ land.states # TODO: now use fAPAR_bare as the output for the cost function!
    end

	return land
end


purpose(::Type{fAPAR_LAIBareFrac}) = "sets the value of fAPAR as a function of LAI with bare soil fraction"

@doc """ 

	$(getModelDocString(fAPAR_LAIBareFrac))

---

# Extended help

*References*
https://link.springer.com/article/10.1007/s11707-014-0446-7
https://www.sciencedirect.com/science/article/pii/S0034425714000010
http://dx.doi.org/10.1016/j.agrformet.2017.01.004

*Versions*
 - 1.0 on 23.04.2025 [xshan]

*Created by*
 - xshan

"""
fAPAR_LAIBareFrac

