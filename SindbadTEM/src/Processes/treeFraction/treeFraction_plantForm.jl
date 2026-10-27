export treeFraction_plantForm

struct treeFraction_plantForm <: treeFraction end

function precompute(params::treeFraction_plantForm, forcing, land, helpers)
    @unpack_nt plant_form ⇐ land.states
    @unpack_nt (z_zero, o_one) ⇐ land.constants

    # GSI requires a tree fraction but this experiment only has categorical PFT.
    frac_tree = plant_form === :tree ? o_one : z_zero
    @pack_nt frac_tree ⇒ land.states
    return land
end

purpose(::Type{treeFraction_plantForm}) = "Derives a binary tree-cover fraction from the categorical plant form."

@doc """

$(getModelDocString(treeFraction_plantForm))

---

# Extended help

Sets `frac_tree` to one for `:tree` PFTs and zero for shrub, herb, or unknown
plant forms when continuous `f_tree_frac` forcing is unavailable.
"""
treeFraction_plantForm
