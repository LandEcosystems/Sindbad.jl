export plantForm_PFT


struct plantForm_PFT <: plantForm end


function define(params::plantForm_PFT, forcing, land, helpers)
	## unpack NT forcing
		plant_form_pft = Dict(
			:tree  => [collect(1:5)..., 8, 9],
			:shrub => collect(6:7),
			:herb => [10, 11, 12, 14],
			)

	defined_forms_pft = vcat(values(plant_form_pft)...)
	# PFT_to_PlantForm = Dict(
	# 	1 => "Tree",
	# 	2 => "Tree",
	# 	3 => "Tree",
	# 	4 => "Tree",
	# 	5 => "Tree",
	# 	6 => "Shrub",
	# 	7 => "Shrub",
	# 	8 => "Savanna",
	# 	9 => "Savanna",
	# 	10 => "Herb",
	# 	11 => "Herb",
	# 	12 => "Herb",
	# 	14 => "Herb",
	# 	13 => "Non-Veg",
	# 	15 => "Non-Veg",
	# 	16 => "Non-Veg",
	# 	17 => "Non-Veg",
	# 	NaN => "Non-Veg",
	# 	missing => "Non-Veg"
	# 	)
	@pack_nt (plant_form_pft, defined_forms_pft) ⇒ land.plantForm
	return land
end


function precompute(params::plantForm_PFT, forcing, land, helpers)
	## unpack land variables
	@unpack_nt PFT ⇐ land.states
	@unpack_nt (plant_form_pft, defined_forms_pft) ⇐ land.plantForm

	the_pft = PFT
	plant_form = :unknown
	if the_pft ∈ defined_forms_pft
		for (pf_key, pf_values) in plant_form_pft
			if the_pft in pf_values
				plant_form=pf_key 
				break
			end
		end
	end
	@pack_nt plant_form ⇒ land.states
	return land
end

purpose(::Type{plantForm_PFT}) = "Differentiate plant form based on PFT."

@doc """ 

	$(getModelDocString(plantForm_PFT))

---

# Extended help

*References*

*Versions*
 - 1.0 on 24.04.2025 [skoirala]

*Created by*
 - skoirala

"""
plantForm_PFT

