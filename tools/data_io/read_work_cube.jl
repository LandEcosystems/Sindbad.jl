using YAXArrays, Zarr
using DimensionalData
using Dates
using UnicodePlots

path_output = "/Net/Groups/BGI/work_3/scratch/lalonso/FLUXNET_v1.zarr"

ds_open = open_dataset(path_output, driver=:zarr);

# access global properties
ds_open.properties

# access variable
nee = ds_open["NEE"] # or ds_open.NEE

# apply functions, testing type unstability
map(x -> x - 1, nee)

map(nee) do x
    isnan(x) ? 0.0 : x
end

# access variable properties
nee.properties

# select a subset of locations for the given variable

nee[site=1:5] # by number index
nee[site=At(["AR-SLu", "AR-Vir", "AT-Neu", "AU-ASM", "AU-Ade"])] # by name

# select a time span
nee[Ti(1:2)] # by number index
nee[Ti(At([DateTime("1979-01-01T00:00:00"), DateTime("1979-01-02T00:00:00")]))] # by DateTime

# select a time span and sites range

nee[Ti(1:2), site=1:5] # by number index

# by DateTime interval and site index
nee[
    Ti(DateTime("1979-01-01T00:00:00") .. DateTime("1979-01-15T00:00:00")),
    site=1:5
]

# select time range
nee[
    Ti(Between([DateTime("1979-01-01T00:00:00"), DateTime("1980-01-02T00:00:00")])),
    site=At(["AR-SLu", "AR-Vir", "AT-Neu", "AU-ASM", "AU-Ade"])
]

# similarly for depth_soildGrids
AWCh1_SoilGrids = ds_open.AWCh1_SoilGrids # or ds_open["AWCh1_SoilGrids"]
# select by index
AWCh1_SoilGrids[depth_soilGrids=1:2, site=1];

# Some plots for consistency checks
# for one site
d_nee = nee[site=10].data[:]
lineplot(d_nee, color=:yellow, title="NEE", width=100)

# check for all sites width a heatmap

heatmap(nee.data[:, :]', colormap=:inferno, title="NEE", width=150, height=50)
