
export InputTypes
abstract type InputTypes <: SindbadTypes end
purpose(::Type{InputTypes}) = "Abstract type for input data and processing related options in SINDBAD"

# -------------------------------- input array type in named tuple --------------------------------
export InputArrayBackend
export InputArray
export InputKeyedArray
export InputNamedDimsArray
export InputYAXArray

abstract type InputArrayBackend <: InputTypes end
purpose(::Type{InputArrayBackend}) = "Abstract type for input data array types in SINDBAD"

struct InputArray <: InputArrayBackend end
purpose(::Type{InputArray}) = "Use standard Julia arrays for input data"

struct InputKeyedArray <: InputArrayBackend end
purpose(::Type{InputKeyedArray}) = "Use keyed arrays for input data"

struct InputNamedDimsArray <: InputArrayBackend end
purpose(::Type{InputNamedDimsArray}) = "Use named dimension arrays for input data"

struct InputYAXArray <: InputArrayBackend end
purpose(::Type{InputYAXArray}) = "Use YAXArray for input data"


# -------------------------------- forcing variable type --------------------------------
export ForcingWithTime
export ForcingWithoutTime

abstract type ForcingTime <: InputTypes end
purpose(::Type{ForcingTime}) = "Abstract type for forcing variable types in SINDBAD"

struct ForcingWithTime <: ForcingTime end
purpose(::Type{ForcingWithTime}) = "Forcing variable with time dimension"

struct ForcingWithoutTime <: ForcingTime end
purpose(::Type{ForcingWithoutTime}) = "Forcing variable without time dimension"


# -------------------------------- spatial subset --------------------------------
export Spaceid
export SpaceId
export SpaceID
export Spacelat
export Spacelatitude
export Spacelongitude
export Spacelon
export Spacesite
export SpatialSubsetter

abstract type SpatialSubsetter <: InputTypes end
purpose(::Type{SpatialSubsetter}) = "Abstract type for spatial subsetting methods in SINDBAD"

struct Spaceid <: SpatialSubsetter end
purpose(::Type{Spaceid}) = "Use site ID for spatial subsetting"

struct SpaceId <: SpatialSubsetter end
purpose(::Type{SpaceId}) = "Use site ID (capitalized) for spatial subsetting"

struct SpaceID <: SpatialSubsetter end
purpose(::Type{SpaceID}) = "Use site ID (all caps) for spatial subsetting"

struct Spacelat <: SpatialSubsetter end
purpose(::Type{Spacelat}) = "Use latitude for spatial subsetting"

struct Spacelatitude <: SpatialSubsetter end
purpose(::Type{Spacelatitude}) = "Use full latitude for spatial subsetting"

struct Spacelongitude <: SpatialSubsetter end
purpose(::Type{Spacelongitude}) = "Use full longitude for spatial subsetting"

struct Spacelon <: SpatialSubsetter end
purpose(::Type{Spacelon}) = "Use longitude for spatial subsetting"

struct Spacesite <: SpatialSubsetter end
purpose(::Type{Spacesite}) = "Use site location for spatial subsetting"



# ------------------------------ interpolation method ------------------------------
export InterpolationMethod
export SpaceInterpolationMethod
export TimeInterpolationMethod
export SpaceGridInterpolationMethod
export TimeGridInterpolationMethod
export TimeMonotonicInterpolationMethod
export SpaceInterpNone
export SpaceInterpNearest
export SpaceInterpConstant
export SpaceInterpLinear
export SpaceInterpQuadratic
export SpaceInterpCubic
export SpaceInterpLanczos
export SpaceInterpLanczosOpencv
export SpaceInterpZhao2004
export TimeInterpNone
export TimeInterpNearest
export TimeInterpConstant
export TimeInterpPrevious
export TimeInterpNext
export TimeInterpLinear
export TimeInterpQuadratic
export TimeInterpCubic
export TimeInterpLanczos
export TimeInterpLanczosOpencv
export TimeInterpLinearMonotonic
export TimeInterpFiniteDifferenceMonotonic
export TimeInterpCardinalMonotonic
export TimeInterpFritschCarlsonMonotonic
export TimeInterpFritschButlandMonotonic
export TimeInterpSteffenMonotonic
export TimeInterpAkimaMonotonic

abstract type InterpolationMethod <: InputTypes end
purpose(::Type{InterpolationMethod}) = "Abstract type for the methods that put forcing and parameter data on the space and time of the run. The fields of a method are its options in the settings"

abstract type SpaceInterpolationMethod <: InterpolationMethod end
purpose(::Type{SpaceInterpolationMethod}) = "Abstract type for the methods of `interpolation_method.space`, which get the spatial axes of the data together"

abstract type TimeInterpolationMethod <: InterpolationMethod end
purpose(::Type{TimeInterpolationMethod}) = "Abstract type for the methods of `interpolation_method.time`, which get the time axis of the data"

abstract type SpaceGridInterpolationMethod <: SpaceInterpolationMethod end
purpose(::Type{SpaceGridInterpolationMethod}) = "Abstract type for Interpolations.jl methods in space that interpolate on the positions of the values along each axis"

abstract type TimeGridInterpolationMethod <: TimeInterpolationMethod end
purpose(::Type{TimeGridInterpolationMethod}) = "Abstract type for Interpolations.jl methods in time that interpolate on the positions of the values"

abstract type TimeMonotonicInterpolationMethod <: TimeInterpolationMethod end
purpose(::Type{TimeMonotonicInterpolationMethod}) = "Abstract type for monotonic Interpolations.jl methods in time that interpolate on the time coordinates"

# space

struct SpaceInterpNone <: SpaceInterpolationMethod end
purpose(::Type{SpaceInterpNone}) = "keep the data on its own grid without interpolation"

Base.@kwdef struct SpaceInterpNearest <: SpaceGridInterpolationMethod
    extrapolation::String = "flat"
end
purpose(::Type{SpaceInterpNearest}) = "take the value of the nearest grid, BSpline(Constant()) of Interpolations.jl"

const SpaceInterpConstant = SpaceInterpNearest

Base.@kwdef struct SpaceInterpLinear <: SpaceGridInterpolationMethod
    extrapolation::String = "flat"
end
purpose(::Type{SpaceInterpLinear}) = "interpolate linearly along each axis, BSpline(Linear()) of Interpolations.jl"

Base.@kwdef struct SpaceInterpQuadratic <: SpaceGridInterpolationMethod
    boundary::String = "line"
    grid::String = "on_grid"
    extrapolation::String = "flat"
end
purpose(::Type{SpaceInterpQuadratic}) = "quadratic B-spline of Interpolations.jl. It is fitted to the whole field, so one invalid value makes the whole field invalid"

Base.@kwdef struct SpaceInterpCubic <: SpaceGridInterpolationMethod
    boundary::String = "line"
    grid::String = "on_grid"
    extrapolation::String = "flat"
end
purpose(::Type{SpaceInterpCubic}) = "cubic B-spline of Interpolations.jl. It is fitted to the whole field, so one invalid value makes the whole field invalid"

Base.@kwdef struct SpaceInterpLanczos <: SpaceGridInterpolationMethod
    order::Int = 4
    extrapolation::String = "flat"
end
purpose(::Type{SpaceInterpLanczos}) = "Lanczos resampling of Interpolations.jl with `order` lobes"

Base.@kwdef struct SpaceInterpLanczosOpencv <: SpaceGridInterpolationMethod
    extrapolation::String = "flat"
end
purpose(::Type{SpaceInterpLanczosOpencv}) = "Lanczos resampling of order 4 as in OpenCV, Lanczos4OpenCV of Interpolations.jl"

Base.@kwdef struct SpaceInterpZhao2004 <: SpaceInterpolationMethod
    power::Int = 4
end
purpose(::Type{SpaceInterpZhao2004}) = "weight the four surrounding grids of the source by cos(π/2 d/d_max)^power of their great-circle distance d, with d_max the largest distance between the four, as in equations 3 to 5 of Zhao et al. 2005, Remote Sensing of Environment 95"

# time

struct TimeInterpNone <: TimeInterpolationMethod end
purpose(::Type{TimeInterpNone}) = "keep the data on its own time axis without interpolation"

Base.@kwdef struct TimeInterpNearest <: TimeGridInterpolationMethod
    extrapolation::String = "flat"
end
purpose(::Type{TimeInterpNearest}) = "take the nearest value in time, BSpline(Constant()) of Interpolations.jl"

const TimeInterpConstant = TimeInterpNearest

Base.@kwdef struct TimeInterpPrevious <: TimeGridInterpolationMethod
    extrapolation::String = "flat"
end
purpose(::Type{TimeInterpPrevious}) = "take the previous value in time, BSpline(Constant(Previous)) of Interpolations.jl"

Base.@kwdef struct TimeInterpNext <: TimeGridInterpolationMethod
    extrapolation::String = "flat"
end
purpose(::Type{TimeInterpNext}) = "take the next value in time, BSpline(Constant(Next)) of Interpolations.jl"

Base.@kwdef struct TimeInterpLinear <: TimeGridInterpolationMethod
    extrapolation::String = "flat"
end
purpose(::Type{TimeInterpLinear}) = "interpolate linearly in time, BSpline(Linear()) of Interpolations.jl"

Base.@kwdef struct TimeInterpQuadratic <: TimeGridInterpolationMethod
    boundary::String = "line"
    grid::String = "on_grid"
    extrapolation::String = "flat"
end
purpose(::Type{TimeInterpQuadratic}) = "quadratic B-spline of Interpolations.jl. It is fitted to the whole series, so one invalid value makes the whole series invalid"

Base.@kwdef struct TimeInterpCubic <: TimeGridInterpolationMethod
    boundary::String = "line"
    grid::String = "on_grid"
    extrapolation::String = "flat"
end
purpose(::Type{TimeInterpCubic}) = "cubic B-spline of Interpolations.jl. It is fitted to the whole series, so one invalid value makes the whole series invalid"

Base.@kwdef struct TimeInterpLanczos <: TimeGridInterpolationMethod
    order::Int = 4
    extrapolation::String = "flat"
end
purpose(::Type{TimeInterpLanczos}) = "Lanczos resampling of Interpolations.jl with `order` lobes"

Base.@kwdef struct TimeInterpLanczosOpencv <: TimeGridInterpolationMethod
    extrapolation::String = "flat"
end
purpose(::Type{TimeInterpLanczosOpencv}) = "Lanczos resampling of order 4 as in OpenCV, Lanczos4OpenCV of Interpolations.jl"

Base.@kwdef struct TimeInterpLinearMonotonic <: TimeMonotonicInterpolationMethod
    extrapolation::String = "flat"
end
purpose(::Type{TimeInterpLinearMonotonic}) = "LinearMonotonicInterpolation of Interpolations.jl"

Base.@kwdef struct TimeInterpFiniteDifferenceMonotonic <: TimeMonotonicInterpolationMethod
    extrapolation::String = "flat"
end
purpose(::Type{TimeInterpFiniteDifferenceMonotonic}) = "FiniteDifferenceMonotonicInterpolation of Interpolations.jl"

Base.@kwdef struct TimeInterpCardinalMonotonic <: TimeMonotonicInterpolationMethod
    tension::Float64 = 0.0
    extrapolation::String = "flat"
end
purpose(::Type{TimeInterpCardinalMonotonic}) = "CardinalMonotonicInterpolation of Interpolations.jl with `tension` from 0 to 1"

Base.@kwdef struct TimeInterpFritschCarlsonMonotonic <: TimeMonotonicInterpolationMethod
    extrapolation::String = "flat"
end
purpose(::Type{TimeInterpFritschCarlsonMonotonic}) = "FritschCarlsonMonotonicInterpolation of Interpolations.jl"

Base.@kwdef struct TimeInterpFritschButlandMonotonic <: TimeMonotonicInterpolationMethod
    extrapolation::String = "flat"
end
purpose(::Type{TimeInterpFritschButlandMonotonic}) = "FritschButlandMonotonicInterpolation of Interpolations.jl"

Base.@kwdef struct TimeInterpSteffenMonotonic <: TimeMonotonicInterpolationMethod
    extrapolation::String = "flat"
end
purpose(::Type{TimeInterpSteffenMonotonic}) = "SteffenMonotonicInterpolation of Interpolations.jl"

Base.@kwdef struct TimeInterpAkimaMonotonic <: TimeMonotonicInterpolationMethod
    extrapolation::String = "flat"
end
purpose(::Type{TimeInterpAkimaMonotonic}) = "AkimaMonotonicInterpolation of Interpolations.jl"
