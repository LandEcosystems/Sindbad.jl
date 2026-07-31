using LinearAlgebra
using YAXArrays, NetCDF, Zarr
using YAXArrayBase
using NCDatasets
using DimensionalData
using Dates
using UnicodePlots
using ProgressMeter

mainpath = "/Net/Groups/BGI/scratch/skoirala/v202312_wroasted/fluxNet_0.04_CLIFF/fluxnetBGI2021.BRK15.DD/data/ERAinterim.v2/daily"
path_input = joinpath(mainpath,"DE-Hai.1979.2017.daily.nc")

files = readdir(mainpath);
path_input = joinpath(mainpath, files[10]);
ds = NCDataset(path_input)

function select_variables(ds)
    sizes = []
    name_variables = keys(ds)
    for k in name_variables
        v = ds[k]
        push!(sizes, size(v))
    end
    selection = length.(sizes) .>= 3
    return name_variables[selection], sizes
end

name_variables, sizes = select_variables(ds);

function attr_dict(ds)
    d = Dict{String,Any}()
    for (attname, attval) in ds.attrib
        d[string(attname)] = attval
    end
    d
end

inpath1 = joinpath(mainpath, files[9]);
ds1 = NCDataset(inpath1);

varws = ds1["WS_QC"]
att = attr_dict(varws)

gattr1 = attr_dict(ds1)
k = keys(gattr1)

# vcat(gattr1["PFT"], gattr1["PFT"]) |> unique

function attributes_sites(mainpath, files_sites)
    ds = NCDataset(joinpath(mainpath, files_sites[1]))
    gs_attr_o = attr_dict(ds)
    gs_attr = Dict{String,Any}()
    for k in keys(gs_attr_o)
        gs_attr[k] = [gs_attr_o[k]]
    end

    for f_path in files_sites[2:end]
        ds = NCDataset(joinpath(mainpath, f_path))
        g_attr = attr_dict(ds)
        for k in keys(g_attr)
            gs_attr[k] = vcat(gs_attr[k], g_attr[k])
        end
    end
    # if is unique, reduce entries to one
    for k in keys(gs_attr)
        u_val = unique(gs_attr[k])
        if length(u_val) == 1
            gs_attr[k] = u_val[1]
        end
    end
    return gs_attr
end


function attributes_variable(mainpath, file, name_variable)
    ds = NCDataset(joinpath(mainpath, file))
    attr_o = attr_dict(ds[name_variable])
    gs_attr = Dict{String,Any}()
    for k in keys(attr_o)
        gs_attr[k] = [attr_o[k]]
    end
    return gs_attr
end

function attributes_variable(gs_attr, attr_i)
    for k in keys(gs_attr)
        gs_attr[k] = vcat(gs_attr[k], attr_i[k])
    end
    return gs_attr
end

function reduce_attributes_variable(gs_attr)
    # if is unique, reduce entries to one
    for k in keys(gs_attr)
        u_val = unique(gs_attr[k])
        if length(u_val) == 1
            gs_attr[k] = u_val[1]
        end
    end
    return gs_attr
end


# new cube
files = readdir(mainpath)
# sfiles = split.(files, ".")
# locations = [string(sf[1]) for sf in sfiles]
# n_files = length(locations)
# alldates = ds1["time"][:]
# n_steps = length(alldates)

function variable_names(mainpath, file)
    ds = NCDataset(joinpath(mainpath, file))
    return keys(ds)
end

function dims_variable(mainpath, file, name_variable, locations; n_files=1)
    dims = nothing
    ax_list = nothing
    ds = NCDataset(joinpath(mainpath, file))
    v = ds[name_variable]
    var_keys = keys(v)
    if length(size(v)) == 3
        if "longitude" in var_keys && "latitude" in var_keys && "time" in var_keys
            n_steps = size(ds["time"], 1)
            ax_list = (
                Dim{:time}(ds["time"][:]),
                Dim{:site}(locations[1:n_files])
            )
            dims = (n_steps, n_files)
        else
            "longitude" in var_keys && "latitude" in var_keys && "depth_soildGrids" in var_keys
            depth = length(ds["depth_soilGrids"][:])
            ax_list = (
                Dim{:depth_soilGrids}(1:depth),
                Dim{:site}(locations[1:n_files])
            )
            dims = (depth, n_files)
        end
    elseif length(size(v)) == 4 && "longitude" in var_keys && "latitude" in var_keys && "time" in var_keys && "depth_FLUXNET" in var_keys
        n_steps = size(ds["time"], 1)
        depth = length(ds["depth_FLUXNET"][:])
        ax_list = (
            Dim{:time}(ds["time"][:]),
            Dim{:depth_FLUXNET}(1:depth),
            Dim{:site}(locations[1:n_files]),
        )
        dims = (n_steps, depth, n_files)
    end
    return dims, ax_list
end

# dims_arr, ax_list = dims_variable(mainpath, files[1], name_variables[70], locations; n_files=n_files)
# to_fill = fill(NaN, dims_arr...);

function get_data_from_file(mainpath, file, name_variable)
    ds = NCDataset(joinpath(mainpath, file))
    var_selected = ds[name_variable]
    gs_attr = attr_dict(ds[name_variable])
    new_data = nothing

    if length(size(var_selected)) == 3
        new_data = replace(var_selected[1, 1, :], missing => NaN)
    else
        new_data = replace(var_selected[1, 1, :, :], missing => NaN)
    end
    return new_data, gs_attr
end

# gs_attr_o = attributes_variable(mainpath, files[1], name_variables[1])
# gs_attr_o = attributes_variable(gs_attr_o, gs_attr_o)
# reduce_attributes_variable(gs_attr_o)


function get_data_variable(name_variable, mainpath, files)
    n_files = length(files)
    sfiles = split.(files, ".")
    locations = [string(sf[1]) for sf in sfiles]

    dims_arr, ax_list = dims_variable(mainpath, files[1], name_variable, locations; n_files=n_files)
    to_fill = fill(NaN, dims_arr...)
    gs_attr_o = attributes_variable(mainpath, files[1], name_variable)

    for (i, file) in enumerate(files)
        tmp_data, gs_attr_i = get_data_from_file(mainpath, file, name_variable)
        if length(dims_arr) == 3
            to_fill[:, :, i] = tmp_data
        else
            to_fill[:, i] = tmp_data
        end
        if i > 1
            gs_attr_o = attributes_variable(gs_attr_o, gs_attr_i)
        end
    end
    gs_attr = reduce_attributes_variable(gs_attr_o)
    return to_fill, gs_attr, ax_list
end

path_output = "/Net/Groups/BGI/work_3/scratch/lalonso/FLUXNET_v1.zarr"

global_attributes = attributes_sites(mainpath, files);

# uncomment to generate cube again

#=
f_arr, g_att, ax_list = get_data_variable(name_variables[1], mainpath, files);
ds_array = YAXArray(ax_list, f_arr, g_att)  # g_att
#ds_array.properties # gives back all those variable attributes

key_var = Symbol(name_variables[1])
data_set = YAXArrays.Dataset(; (key_var => ds_array, )..., properties = global_attributes)
savedataset(data_set, path=path_output, driver=:zarr, overwrite=true) # overwrite=true


ds_open = open_dataset(path_output, driver=:zarr)

p = Progress(length(name_variables[2:end]))
for var_name in name_variables[2:end]
    f_arr, g_att, ax_list = get_data_variable(var_name, mainpath, files);
    ds_array = YAXArray(ax_list, f_arr, g_att) 
    key_var = Symbol(var_name)
    ds_new = YAXArrays.Dataset(; (key_var => ds_array, )...)
    savedataset(ds_new, path=path_output, backend=:zarr, append=true)
    next!(p; showvalues = [(:variable_name, var_name)])
end

ds_open = open_dataset(path_output, driver=:zarr)
=#




