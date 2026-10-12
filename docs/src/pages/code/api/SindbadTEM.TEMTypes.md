```@docs
SindbadTEM.TEMTypes
```
## Functions

### poolAliases
```@docs
poolAliases
```

----

### poolConfiguration
```@docs
poolConfiguration
```

:::details Code

```julia
function poolConfigurationForApproach(info, element)
    hasproperty(POOL_ELEMENT_PROCESS, element) || return nothing
    process = getproperty(POOL_ELEMENT_PROCESS, element)
    models = info.settings.model_structure.models
    hasproperty(models, process) || return nothing
    approach_name = Symbol(String(process) * "_" * string(getproperty(getproperty(models, process), :approach)))
    hasproperty(SindbadTEM.Processes, approach_name) || return nothing
    configuration = poolConfiguration(getproperty(SindbadTEM.Processes, approach_name))
    return isnothing(configuration) || isnothing(poolStructure(configuration)) ? nothing : configuration
end

function poolConfigurationFor(spec::AbstractString)
    return SindbadTEM.Processes.carbonPoolConfiguration(Symbol(spec))
end
```

:::


----

### poolStructure
```@docs
poolStructure
```

----

### vegTypeCatalog
```@docs
vegTypeCatalog
```

----

### vegTypeClassification
```@docs
vegTypeClassification
```

----

## Types

### DoCatchModelErrors
```@docs
DoCatchModelErrors
```

----

### DoDebugModel
```@docs
DoDebugModel
```

----

### DoInlineUpdate
```@docs
DoInlineUpdate
```

----

### DoNotCatchModelErrors
```@docs
DoNotCatchModelErrors
```

----

### DoNotDebugModel
```@docs
DoNotDebugModel
```

----

### DoNotInlineUpdate
```@docs
DoNotInlineUpdate
```

----

### LandEcosystem
```@docs
LandEcosystem
```

----

### SindbadTypes
```@docs
SindbadTypes
```

----

```@meta
CollapsedDocStrings = false
DocTestSetup= quote
using SindbadTEM.TEMTypes
end
```
