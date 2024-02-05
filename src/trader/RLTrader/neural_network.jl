using Flux

# store model and opt state in a struct 
struct Network
    name::String
    model::Any
    opt_state::Any
end

# construct basic neural network
function _construct_neural_network(
    name::String,
    in_dim::Int,
    out_dim::Int;
    activation = nothing,
)::Network
    # specify the model
    if activation == "softmax"
        model =
            Chain(
                Dense(in_dim => 64, relu),
                LSTM(64 => 64),
                Dense(64 => out_dim, relu),
                softmax,
            ) |> gpu
    elseif activation == "sigmoid"
        model = Chain(Dense(in_dim => out_dim, σ)) |> gpu
    elseif activation == "tanh"
        model =
            Chain(Dense(in_dim => 64, relu), LSTM(64 => 64), Dense(64 => out_dim, tanh)) |>
            gpu
    else
        model =
            Chain(Dense(in_dim => 64, relu), LSTM(64 => 64), Dense(64 => out_dim)) |> gpu
    end
    opt_state = Flux.setup(Adam(0.0001), model)

    return Network(name, model, opt_state)
end
