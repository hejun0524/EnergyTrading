using Flux 

# store model and opt state in a struct 
struct Network 
    model
    opt_state
end

# construct basic neural network
function _construct_neural_network(
    in_dim::Int, 
    out_dim::Int;
    activation = nothing
)::Network
    # specify the model
    fc1 = Dense(in_dim => 64, relu)
    fc2 = Dense(64 => 64, relu)
    if activation === "tanh"
        out = Dense(64 => out_dim, tanh)
    elseif activation === "sigmoid"
        out = Dense(64 => out_dim, sigmoid)
    else
        out = Dense(64 => out_dim)
    end
    
    model = Chain(fc1, fc2, out) |> gpu 
    opt_state = Flux.setup(Adam(), model)

    return Network(model, opt_state)
end