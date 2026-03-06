export gpp_NeuralNetwork

const GPP_MODEL_PATH = "/Net/Groups/BGI/scratch/relghawi/Sinbad_test/Sindbad-Dev/dev/Sindbad.jl/examples/exp_WROASTED/gpp_model_v1.jld2"

#! format: off
# Keeping the structure empty as requested
struct gpp_NeuralNetwork <: gpp end
#! format: on

# 1. Create a global container that loads ONLY once when the code is run
const GPP_NN_DATA = let
    if !isfile(GPP_MODEL_PATH)
        error("ML Model not found at $GPP_MODEL_PATH")
    end
    
    data = jldopen(GPP_MODEL_PATH, "r")
    
    # Reconstruct the architecture
    m = Chain(
        Dense(5, 64, relu),
        Dense(64, 32, relu),
        Dense(32, 1, softplus)
    )
    
    Flux.loadmodel!(m, data["model_state"])
    mu = Float32.(data["mu"])
    sigma = Float32.(data["sigma"])
    close(data)
    
    # Return a NamedTuple to the constant
    (model = m, mu = mu, sigma = sigma)
end

function compute(params::gpp_NeuralNetwork, forcing, land, helpers)
    # 1. Unpack as per Sindbad convention
    @unpack_nt begin
        f_rg ⇐ forcing
        f_PAR ⇐ forcing
        f_airT ⇐ forcing
        f_VPD ⇐ forcing
        f_ambient_CO2 ⇐ forcing
    end

    # 2. Prepare the input vector
    f_vec = Float32[f_rg, f_PAR, f_airT, f_VPD, f_ambient_CO2]

    # 3. Access the data from GPP_NN_DATA (the hardcoded container) 
    # instead of params (the empty struct)
    x_norm = (reshape(f_vec, 5, 1) .- GPP_NN_DATA.mu) ./ GPP_NN_DATA.sigma
    gpp_pred = GPP_NN_DATA.model(x_norm)[1]

    # 4. Physical constraint
    gpp = max(Float64(gpp_pred), 0.0)

    # 5. Pack back into Sindbad
    @pack_nt begin
        gpp ⇒ land.fluxes
    end

    return land
end


purpose(::Type{gpp_NeuralNetwork}) = "GPP based on pre-trained neural network."

@doc """

$(getModelDocString(gpp_NeuralNetwork))

---

# Extended help

*References*

*Versions*
 - 1.0 on 22.11.2019 [skoirala | @dr-ko]

*Created by*
 - mjung
 - skoirala | @dr-ko

*Notes*
"""
gpp_NeuralNetwork
