
export InputTypes
abstract type InputTypes <: SindbadTypes end
purpose(::Type{InputTypes}) = "Abstract type for input data and processing related options in SINDBAD"

# -------------------------------- input array type in named tuple --------------------------------
export InputArrayBackend
export InputArray
export InputKeyedArray
export InputNamedDimsArray
export InputYaxArray

abstract type InputArrayBackend <: InputTypes end
purpose(::Type{InputArrayBackend}) = "Abstract type for input data array types in SINDBAD"

struct InputArray <: InputArrayBackend end
purpose(::Type{InputArray}) = "Use standard Julia arrays for input data"

struct InputKeyedArray <: InputArrayBackend end
purpose(::Type{InputKeyedArray}) = "Use keyed arrays for input data"

struct InputNamedDimsArray <: InputArrayBackend end
purpose(::Type{InputNamedDimsArray}) = "Use named dimension arrays for input data"

struct InputYaxArray <: InputArrayBackend end
purpose(::Type{InputYaxArray}) = "Use YAXArray for input data"


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

