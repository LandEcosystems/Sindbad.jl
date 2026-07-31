```@docs
Sindbad.Visualization
```
## Functions

### namedTupleToFlareJSON
```@docs
namedTupleToFlareJSON
```

:::details Code

```julia
function namedTupleToFlareJSON(info::NamedTuple)
    function _convert_to_flare(nt::NamedTuple, name="sindbad_info")
        children = []
        for field in propertynames(nt)
            value = getfield(nt, field)
            if value isa NamedTuple
                push!(children, _convert_to_flare(value, string(field)))
            else
                # println("field: $field, value: $value")
                push!(children, Dict("name" => string(field), "value" => 1))
            end
        end
        return Dict("name" => name, "children" => children)
    end

    return _convert_to_flare(info)
end
```

:::


----

### plotIOModelStructure
```@docs
plotIOModelStructure
```

:::details Code

```julia
    function plotIOModelStructure(info, which_function, which_field)
        backend = info.helpers.run.visualization_backend
        return plotIOModelStructure(info, which_function, which_field, _resolvedBackend(plotIOModelStructure, backend, info, which_function, which_field))
    end

    function plotIOModelStructure(info, which_function, which_field, ::VisualizationTypes)
        print_info(plotIOModelStructure, @__FILE__, @__LINE__, _visualizationFallbackMessage(plotIOModelStructure, info.helpers.run.visualization_backend), n_f=4)
        return nothing
    end
```

:::


----

### plotPerformanceHistograms
```@docs
plotPerformanceHistograms
```

:::details Code

```julia
    function plotPerformanceHistograms(out_opti)
        backend = out_opti.info.helpers.run.visualization_backend
        return plotPerformanceHistograms(out_opti, _resolvedBackend(plotPerformanceHistograms, backend, out_opti))
    end

    function plotPerformanceHistograms(out_opti, ::VisualizationTypes)
        print_info(plotPerformanceHistograms, @__FILE__, @__LINE__, _visualizationFallbackMessage(plotPerformanceHistograms, out_opti.info.helpers.run.visualization_backend), n_f=4)
        return nothing
    end
```

:::


----

### plotTimeSeries
```@docs
plotTimeSeries
```

:::details Code

```julia
    function plotTimeSeries(out_opti)
        backend = out_opti.info.helpers.run.visualization_backend
        return plotTimeSeries(out_opti, _resolvedBackend(plotTimeSeries, backend, out_opti))
    end

    function plotTimeSeries(out, cost_options)
        backend = out.info.helpers.run.visualization_backend
        return plotTimeSeries(out, cost_options, _resolvedBackend(plotTimeSeries, backend, out, cost_options))
    end

    function plotTimeSeries(info, opt_dat, def_dat)
        backend = info.helpers.run.visualization_backend
        return plotTimeSeries(info, opt_dat, def_dat, _resolvedBackend(plotTimeSeries, backend, info, opt_dat, def_dat))
    end

    function plotTimeSeriesWithObs(out, obs_array, cost_options)
        backend = out.info.helpers.run.visualization_backend
        return plotTimeSeries(out.info, obs_array, cost_options, out.output, _resolvedBackend(plotTimeSeries, backend, out.info, obs_array, cost_options, out.output))
    end

    function plotTimeSeries(out_opti, ::VisualizationTypes)
        print_info(plotTimeSeries, @__FILE__, @__LINE__, _visualizationFallbackMessage(plotTimeSeries, out_opti.info.helpers.run.visualization_backend), n_f=4)
        return nothing
    end

    function plotTimeSeries(out, cost_options, ::VisualizationTypes)
        print_info(plotTimeSeries, @__FILE__, @__LINE__, _visualizationFallbackMessage(plotTimeSeries, out.info.helpers.run.visualization_backend), n_f=4)
        return nothing
    end

    function plotTimeSeries(info, opt_dat, def_dat, ::VisualizationTypes)
        print_info(plotTimeSeries, @__FILE__, @__LINE__, _visualizationFallbackMessage(plotTimeSeries, info.helpers.run.visualization_backend), n_f=4)
        return nothing
    end

    function plotTimeSeries(info, obs_array, cost_options, def_dat, ::VisualizationTypes)
        print_info(plotTimeSeries, @__FILE__, @__LINE__, _visualizationFallbackMessage(plotTimeSeries, info.helpers.run.visualization_backend), n_f=4)
        return nothing
    end
```

:::


----

### plotTimeSeriesDebug
```@docs
plotTimeSeriesDebug
```

----

### plotTimeSeriesWithObs
```@docs
plotTimeSeriesWithObs
```

:::details Code

```julia
    function plotTimeSeriesWithObs(out, obs_array, cost_options)
        backend = out.info.helpers.run.visualization_backend
        return plotTimeSeries(out.info, obs_array, cost_options, out.output, _resolvedBackend(plotTimeSeries, backend, out.info, obs_array, cost_options, out.output))
    end
```

:::


----

```@meta
CollapsedDocStrings = false
DocTestSetup= quote
using Sindbad.Visualization
end
```
