export oneHotPFT
export vegOneHot
export vegOneHotbatch
export lcKAoneHotbatch
export vegKAoneHotbatch
export toClass
export vegetation_labels
export vegetation_rules
export KGlabels
export PFTlabels

const vegetation_labels = ["Tree", "Shrub", "Savanna", "Herb", "Non-Veg"]
const vegetation_rules = Dict(
    1 => "Tree",
    2 => "Tree",
    3 => "Tree",
    4 => "Tree",
    5 => "Tree",
    6 => "Shrub",
    7 => "Shrub",
    8 => "Savanna",
    9 => "Savanna",
    10 => "Herb",
    11 => "Herb",
    12 => "Herb",
    14 => "Herb",
    13 => "Non-Veg",
    15 => "Non-Veg",
    16 => "Non-Veg",
    17 => "Non-Veg",
    NaN => "Non-Veg",
    missing => "Non-Veg"
    )

const KGlabels = ["Af", "Am", "As", "Aw", "BSh", "BSk", "BWh", "BWk", "Cfa", "Cfb", "Cfc", "Csa", "Csb", "Csc", "Cwa", "Cwb", "Cwc", "Dfa", "Dfb", "Dfc", "Dfd", "Dsa", "Dsb", "Dsc", "Dsd", "Dwa", "Dwb", "Dwc", "Dwd", "EF", "ET", "Ocean/UNC"]
const PFTlabels = ["ENF", "EBF", "DNF", "DBF", "MF", "CSH", "OSH", "WSA", "SAV", "GRA", "WET", "CRO", "UBL", "MOS", "SNO", "BAR", "WAT/UNC"]

"""
    toClass(x::Number; vegetation_rules)

# Arguments    
- `x`: a key `(Number)` from `vegetation_rules`
- `vegetation_rules`
"""
function toClass(x::Number; vegetation_rules=vegetation_rules)
    if ismissing(x)
        return vegetation_rules[missing]
    elseif x isa AbstractFloat && isnan(x)
        return vegetation_rules[NaN]
    end
    new_key = Int(x)
    return get(vegetation_rules, new_key, "Unknown key")
end

# Flux one-hot interface utilities
function oneHotPFT end
function vegOneHot end
function vegOneHotbatch end
function lcKAoneHotbatch end
function vegKAoneHotbatch end