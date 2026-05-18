export computeTEM
export definePrecomputeTEM
export precomputeTEM


"""
    computeTEM(tem_processes, forcing, land, model_helpers, ::DoDebugModel)

debug the compute function of SINDBAD TEM processes

# Arguments:
- `tem_processes`: a list of SINDBAD TEM processes to run
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `land`: a core SINDBAD NT that contains all variables for a given time step that is overwritten at every timestep
- `model_helpers`: helper NT with necessary objects for model run and type consistencies
- `::DoDebugModel`: a type dispatch to debug the compute functions of model
"""
function computeTEM(tem_processes::Tuple, forcing, land, model_helpers, ::DoDebugModel) # debug the tem_processes
    otype = typeof(land)
    return foldl_tuple_unrolled(tem_processes; init=land) do _land, model
        println("compute: $(typeof(model))")
        @time _land = Processes.compute(model, forcing, _land, model_helpers)::otype
    end
end


"""
    computeTEM(tem_processes, forcing, land, model_helpers, ::DoNotDebugModel)

run the compute function of SINDBAD TEM processes

# Arguments:
- `tem_processes`: a list of SINDBAD TEM processes to run
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `land`: a core SINDBAD NT that contains all variables for a given time step that is overwritten at every timestep
- `model_helpers`: helper NT with necessary objects for model run and type consistencies
- `::DoNotDebugModel`: a type dispatch to not debug but run the compute functions of model
"""
function computeTEM(tem_processes::Tuple, forcing, land, model_helpers, ::DoNotDebugModel) # do not debug the tem_processes 
    return computeTEM(tem_processes, forcing, land, model_helpers) 
end


"""
    computeTEM(tem_processes, forcing, land, model_helpers)

run the compute function of SINDBAD TEM processes

# Arguments:
- `tem_processes`: a list of SINDBAD TEM processes to run
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `land`: a core SINDBAD NT that contains all variables for a given time step that is overwritten at every timestep
- `model_helpers`: helper NT with necessary objects for model run and type consistencies
"""
function computeTEM(tem_processes::LongTuple, forcing, _land, model_helpers) 
    return foldl_longtuple(tem_processes, init=_land) do model, __land
        __land = Processes.compute(model, forcing, __land, model_helpers)
    end
end


"""
    computeTEM(tem_processes, forcing, land, model_helpers)

run the compute function of SINDBAD TEM processes

# Arguments:
- `tem_processes`: a list of SINDBAD TEM processes to run
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `land`: a core SINDBAD NT that contains all variables for a given time step that is overwritten at every timestep
- `model_helpers`: helper NT with necessary objects for model run and type consistencies
"""
function computeTEM(tem_processes::Tuple, forcing, land, model_helpers) 
    return foldl_tuple_unrolled(tem_processes; init=land) do _land, model
        _land = Processes.compute(model, forcing, _land, model_helpers)
    end
end

"""
    defineTEM(tem_processes, forcing, land, model_helpers)

run the define and precompute functions of SINDBAD TEM processes to instantiate all fields of land

# Arguments:
- `tem_processes`: a list of SINDBAD TEM processes to run
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `land`: a core SINDBAD NT that contains all variables for a given time step that is overwritten at every timestep
- `model_helpers`: helper NT with necessary objects for model run and type consistencies
"""
function defineTEM(tem_processes::Tuple, forcing, land, model_helpers)
    return foldl_tuple_unrolled(tem_processes; init=land) do _land, model
        _land = Processes.define(model, forcing, _land, model_helpers)
    end
end

"""
    defineTEM(tem_processes::LongTuple, forcing, land, model_helpers)

run the precompute function of SINDBAD TEM processes to instantiate all fields of land

# Arguments:
- `tem_processes`: a list of SINDBAD TEM processes to run
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `land`: a core SINDBAD NT that contains all variables for a given time step that is overwritten at every timestep
- `model_helpers`: helper NT with necessary objects for model run and type consistencies
"""
function defineTEM(tem_processes::LongTuple, forcing, _land, model_helpers)
    return foldl_longtuple(tem_processes, init=_land) do model, _land
        _land = Processes.define(model, forcing, _land, model_helpers)
    end
end


"""
    definePrecomputeTEM(tem_processes, forcing, land, model_helpers)

run the define and precompute functions of SINDBAD TEM processes to instantiate all fields of land

# Arguments:
- `tem_processes`: a list of SINDBAD TEM processes to run
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `land`: a core SINDBAD NT that contains all variables for a given time step that is overwritten at every timestep
- `model_helpers`: helper NT with necessary objects for model run and type consistencies
"""
function definePrecomputeTEM(tem_processes::Tuple, forcing, land, model_helpers)
    return foldl_tuple_unrolled(tem_processes; init=land) do _land, model
        _land = Processes.define(model, forcing, _land, model_helpers)
        _land = Processes.precompute(model, forcing, _land, model_helpers)
    end
end

"""
    definePrecomputeTEM(tem_processes::LongTuple, forcing, land, model_helpers)

run the precompute function of SINDBAD TEM processes to instantiate all fields of land

# Arguments:
- `tem_processes`: a list of SINDBAD TEM processes to run
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `land`: a core SINDBAD NT that contains all variables for a given time step that is overwritten at every timestep
- `model_helpers`: helper NT with necessary objects for model run and type consistencies
"""
function definePrecomputeTEM(tem_processes::LongTuple, forcing, _land, model_helpers)
    return foldl_longtuple(tem_processes, init=_land) do model, _land
        _land = Processes.define(model, forcing, _land, model_helpers)
        _land = Processes.precompute(model, forcing, _land, model_helpers)
    end
end


"""
    precomputeTEM(tem_processes, forcing, land, model_helpers, ::DoDebugModel)

debug the precompute function of SINDBAD TEM processes

# Arguments:
- `tem_processes`: a list of SINDBAD TEM processes to run
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `land`: a core SINDBAD NT that contains all variables for a given time step that is overwritten at every timestep
- `model_helpers`: helper NT with necessary objects for model run and type consistencies
- `::DoDebugModel`: a type dispatch to debug the compute functions of model
"""
function precomputeTEM(tem_processes::Tuple, forcing, land, model_helpers, ::DoDebugModel) # debug the tem_processes
    otype = typeof(land)
    return foldl_tuple_unrolled(tem_processes; init=land) do _land, model
        println("precompute: $(typeof(model))")
        @time _land = Processes.precompute(model, forcing, _land, model_helpers)::otype
    end
end


"""
    precomputeTEM(tem_processes, forcing, land, model_helpers, ::DoNotDebugModel)

run the precompute function of SINDBAD TEM processes

# Arguments:
- `tem_processes`: a list of SINDBAD TEM processes to run
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `land`: a core SINDBAD NT that contains all variables for a given time step that is overwritten at every timestep
- `model_helpers`: helper NT with necessary objects for model run and type consistencies
- `::DoNotDebugModel`: a type dispatch to not debug but run the compute functions of model
"""
function precomputeTEM(tem_processes::Tuple, forcing, land, model_helpers, ::DoNotDebugModel) # do not debug the tem_processes 
    return precomputeTEM(tem_processes, forcing, land, model_helpers) 
end


"""
    precomputeTEM(tem_processes, forcing, land, model_helpers)

run the precompute function of SINDBAD TEM processes to instantiate all fields of land

# Arguments:
- `tem_processes`: a list of SINDBAD TEM processes to run
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `land`: a core SINDBAD NT that contains all variables for a given time step that is overwritten at every timestep
- `model_helpers`: helper NT with necessary objects for model run and type consistencies
"""
function precomputeTEM(tem_processes::LongTuple, forcing, _land, model_helpers)
    return foldl_longtuple(tem_processes, init=_land) do model, _land
        Processes.precompute(model, forcing, _land, model_helpers)
    end
end

"""
    precomputeTEM(tem_processes, forcing, land, model_helpers)

run the precompute function of SINDBAD TEM processes to instantiate all fields of land

# Arguments:
- `tem_processes`: a list of SINDBAD TEM processes to run
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `land`: a core SINDBAD NT that contains all variables for a given time step that is overwritten at every timestep
- `model_helpers`: helper NT with necessary objects for model run and type consistencies
"""
function precomputeTEM(tem_processes::Tuple, forcing, land, model_helpers)
    return foldl_tuple_unrolled(tem_processes; init=land) do _land, model
        _land = Processes.precompute(model, forcing, _land, model_helpers)
    end
end

