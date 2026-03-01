import Sindbad.MachineLearning:
    oneHotPFT,
    vegOneHot,
    vegOneHotbatch,
    lcKAoneHotbatch,
    vegKAoneHotbatch
    
using Sindbad.MachineLearning:
    toClass,
    vegetation_labels,
    vegetation_rules,
    KGlabels,
    PFTlabels

function vegOneHotbatch(veg_classes; vegetation_labels=vegetation_labels)
    return Flux.onehotbatch(veg_classes, vegetation_labels)
end

function vegOneHot(v_class; vegetation_labels=vegetation_labels)
    return Flux.onehot(v_class, vegetation_labels)
end

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

function vegKAoneHotbatch(pft_data, ka_labels)
    oneHot_veg = vegOneHotbatch(toClass.(pft_data))
    return KeyedArray(Array(oneHot_veg); features=vegetation_labels, site=ka_labels)
end