import Sindbad.MachineLearning:
    oneHotPFT,
    vegOneHot,
    vegOneHotbatch,
    lcKAoneHotbatch,
    vegKAoneHotbatch


"""
    vegOneHotbatch(veg_classes; vegetation_labels)

# Arguments
- veg_classes: get these from `toClass.([x1, x2,...])`
- vegetation_labels: see them by typing `vegetation_labels`
"""
function vegOneHotbatch(veg_classes; vegetation_labels=vegetation_labels)
    return Flux.onehotbatch(veg_classes, vegetation_labels)
end

"""
    vegOneHot(v_class; vegetation_labels)

# Arguments    
- `v_class`: get it by doing `toClass(x; vegetation_rules)`.
- `vegetation_labels`: see them by typing `vegetation_labels`.
"""
function vegOneHot(v_class; vegetation_labels=vegetation_labels)
    return Flux.onehot(v_class, vegetation_labels)
end


"""
    oneHotPFT(pft, up_bound, veg_class)

# Arguments
- `pft`: (Plant Functional Type). Any entry not in 1:17 would be set to the last index, this includes NaN!  Last index is water/NaN
- `up_bound`: last index class, the range goes from `1:up_bound`, and any case not in that range uses the `up_bound` value. For `PFT` use `17`. 
- `veg_class`: `true` or `false`.

Returns a vector.
"""
function oneHotPFT(pft, up_bound, veg_class)
    if !veg_class
        return Flux.onehot(pft, 1:up_bound, up_bound)
    else
        _pft = pft
        if length(pft)==1
            _pft = pft[1]
        end
        return vegOneHot(toClass(_pft))
    end
end

"""
    lcKAoneHotbatch(lc_data, up_bound, lc_name, ka_labels)

# Arguments
- `lc_data`: Vector array
- `up_bound`: last index class, the range goes from `1:up_bound`, and any case not in that range uses the `up_bound` value. For `PFT` use `17` and for `KG` `32`. 
- `lc_name`: land cover approach, either `KG` or `PFT`.
- `ka_labels`: KeyedArray labels, i.e. site names
"""
function lcKAoneHotbatch(lc_data, up_bound, lc_name, ka_labels)
    oneHot_lc = Flux.onehotbatch(lc_data, 1:up_bound, up_bound)
    feat_labels = "$(lc_name)_".*string.(1:up_bound)
    if lowercase(lc_name)=="kg"
        feat_labels = KGlabels
    elseif lowercase(lc_name)=="pft"
        feat_labels = PFTlabels
    end
    return KeyedArray(Array(oneHot_lc); features=feat_labels, site=ka_labels)
end

"""
    vegKAoneHotbatch(pft_data, ka_labels)

# Arguments
- `pft_data`: Vector array
- `ka_labels`: KeyedArray labels, i.e. site names
"""
function vegKAoneHotbatch(pft_data, ka_labels)
    oneHot_veg = vegOneHotbatch(toClass.(pft_data))
    return KeyedArray(Array(oneHot_veg); features=vegetation_labels, site=ka_labels)
end