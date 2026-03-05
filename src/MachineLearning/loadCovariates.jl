export loadCovariates

"""
    loadCovariates(sites_forcing; kind="all")

use the `kind` argument to select different sets of covariates

# Arguments
- sites_forcing: names of forcing sites
- kind: defaults to "all"

Other options
- `PFT`
- `KG`
- `KG_PFT`
- `PFT_ABCNOPSWB`
- `KG_ABCNOPSWB`
- `ABCNOPSWB`
- `veg_all`
- `veg`
- `KG_veg`
- `veg_ABCNOPSWB`
"""
function loadCovariates(::MachineLearningExperimentType, sites_forcing, covariate_path, covariate_options)
    c_read = Cube(covariate_path)
    kind = covariate_options.kind
    # select features, do only nor
    only_nor = occursin.(r"nor", c_read.features)
    nor_sel = c_read.features[only_nor].val
    nor_sel = [string.(s) for s in nor_sel] |> sort
    # select only normalized continuous variables
    ds_nor = c_read[features = At(nor_sel)]
    xfeat_nor = yaxCubeToKeyedArray(ds_nor)
    # apply PCA to xfeat_nor if needed
    # ? where is age?
    kg_data = c_read[features=At("KG")][:].data
    oneHot_KG = lcKAoneHotbatch(kg_data, 32, "KG", string.(c_read.site))
    pft_data = c_read[features=At("PFT")][:].data
    oneHot_pft = lcKAoneHotbatch(pft_data, 17, "PFT", string.(c_read.site))
    oneHot_veg = vegKAoneHotbatch(pft_data, string.(c_read.site))

    stackedFeatures = if kind=="all" 
            reduce(vcat, [oneHot_KG, oneHot_pft, xfeat_nor])
        elseif  kind=="PFT"
            reduce(vcat, [oneHot_pft])
        elseif kind=="KG"
            reduce(vcat, [oneHot_KG])
        elseif kind=="KG_PFT"
            reduce(vcat, [oneHot_KG, oneHot_pft])
        elseif kind=="PFT_ABCNOPSWB"
            reduce(vcat, [oneHot_pft, xfeat_nor])
        elseif kind=="KG_ABCNOPSWB"
            reduce(vcat, [oneHot_KG, xfeat_nor])
        elseif kind=="ABCNOPSWB"
            reduce(vcat, [xfeat_nor])
        elseif kind =="veg_all"
            reduce(vcat, [oneHot_KG, oneHot_veg, xfeat_nor])
        elseif kind=="veg"
            reduce(vcat, [oneHot_veg])
        elseif kind=="KG_veg"
            reduce(vcat, [oneHot_KG, oneHot_veg])
        elseif kind=="veg_ABCNOPSWB"
            reduce(vcat, [oneHot_veg, xfeat_nor])
        end
    # remove sites (with NaNs and duplicates)
    to_remove = [
        "CA-NS3",
        # "CA-NS4",
        "IT-CA1",
        # "IT-CA2",
        "IT-SR2",
        # "IT-SRo",
        "US-ARb",
        # "US-ARc",
        "US-GBT",
        # "US-GLE",
        "US-Tw1",
        # "US-Tw2"
        ]
    not_these = ["RU-Tks", "US-Atq", "US-UMd"] # NaNs
    not_these = vcat(not_these, to_remove)
    new_sites = setdiff(c_read.site, not_these)
    stackedFeatures = stackedFeatures(; site=new_sites)
    # get common sites between names in forcing and covariates
    sites_feature_all = [s for s in stackedFeatures.site]
    sites_common = intersect(sites_feature_all, sites_forcing)
    xfeatures = Float32.(stackedFeatures(; site=sites_common))

    return xfeatures
end