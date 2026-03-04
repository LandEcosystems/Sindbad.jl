export getAbsDataPath
export getSindbadDataDepot

"""
    getAbsDataPath(info, data_path)

Converts a relative data path to an absolute path based on the experiment directory.

# Arguments:
- `info`: The SINDBAD experiment information object.
- `data_path`: The relative or absolute data path.

# Returns:
An absolute data path.
"""
function getAbsDataPath(info, data_path)
    if startswith(data_path, "http") || startswith(data_path, "s3://")
        return data_path
    end
    if !isabspath(data_path)
        d_data_path = getSindbadDataDepot(local_data_depot=data_path)
        if data_path == d_data_path
            data_path = joinpath(info.experiment.dirs.experiment, data_path)
        else
            data_path = joinpath(d_data_path, data_path)
        end
    end
    return data_path
end


"""
    getSindbadDataDepot(; env_data_depot_var="SINDBAD_DATA_DEPOT", local_data_depot="../data")

Retrieve the Sindbad data depot path.

# Arguments
- `env_data_depot_var`: Environment variable name for the data depot (default: "SINDBAD\\_DATA\\_DEPOT")
- `local_data_depot`: Local path to the data depot (default: "../data")

# Returns
The path to the Sindbad data depot.
"""
function getSindbadDataDepot(; env_data_depot_var="SINDBAD_DATA_DEPOT", local_data_depot="../data")
    data_depot = isabspath(local_data_depot) ? local_data_depot : haskey(ENV, env_data_depot_var) ? ENV[env_data_depot_var] : local_data_depot
    return data_depot
end
