"""
Extension methods for `Sindbad.MachineLearning.gradientSite`.

This file is included from the extension module and can use `ForwardDiff`.
"""

# Bring the target function into scope for adding methods. This should be done using `import` and not `using`.
import Sindbad.MachineLearning: gradientSite, gradientParameterType

# get all the types needed to dispatch the function. These types should defined in a corresponding file in Sindbad so that they can be used for dispatching and setup, if that were needed.
using Sindbad: ForwardDiffGrad

"""
    SindbadGradientTag

The tag of the ForwardDiff duals of `gradientSite`. A fixed tag, instead of one from the
type of the loss function, makes the type of the duals known before the loss functions
are built, so `getGradientLand` can build the land in that type.
"""
struct SindbadGradientTag end

sindbadTag(::Type{V}) where {V} = ForwardDiff.Tag(SindbadGradientTag(), V)

"""
    sindbadChunkSize(n_parameters, gradient_options)

Returns the chunk size of the gradient: `chunk_size` of `gradient_options`, at most
`n_parameters`, or the size that ForwardDiff picks by default when it is not set or
not positive.
"""
function sindbadChunkSize(n_parameters, gradient_options)
    chunk_size = get(gradient_options, :chunk_size, nothing)
    if isnothing(chunk_size) || chunk_size < 1
        return ForwardDiff.pickchunksize(n_parameters)
    end
    return min(Int(chunk_size), n_parameters)
end

function gradientParameterType(::ForwardDiffGrad, n_parameters, ::Type{V}, gradient_options) where {V}
    return ForwardDiff.Dual{typeof(sindbadTag(V)),V,sindbadChunkSize(n_parameters, gradient_options)}
end

function gradientSite(::ForwardDiffGrad, x_vals::AbstractArray, gradient_options::NamedTuple, loss_f::F) where {F}
    ∇x = similar(x_vals) # pre-allocate
    # the duals have the type of gradientParameterType, so the loss uses the land built
    # in that type by getGradientLand. The tag is not that of loss_f, so the tag check
    # is turned off.
    chunk = ForwardDiff.Chunk{sindbadChunkSize(length(x_vals), gradient_options)}()
    cfg = ForwardDiff.GradientConfig(loss_f, x_vals, chunk, sindbadTag(eltype(x_vals)))
    ForwardDiff.gradient!(∇x, loss_f, x_vals, cfg, Val{false}())
    return ∇x
end
