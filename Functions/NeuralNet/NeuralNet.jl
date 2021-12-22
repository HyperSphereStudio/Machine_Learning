export NeuralNetDesigner, NeuralNet, push_layer!

mutable struct NeuralNetDesigner{T, InputDim <: Integer, OutputDim <: Integer}
    layers::Vector{Layer}
    init_constant_vector::Vector{T}
    error_function::ErrorFunction{T}
    optimizer::Optimizer{T}
    constant_bounds::Vector{Bound{T}}

    function NeuralNetDesigner{T, I, O}(error_function=NeuralNet.meanabserr, optimizer=nothing) where T where I where O
            new{T, I, O}(Vector{Layer}(undef, 0), zeros(T, 0), error_function, optimizer)
    end

    function (d::NeuralNetDesigner{T})()::TrainableNeuralNet{T, InputDim, OutputDim} where T
            TrainableNeuralNet{T}(d)
    end

    function Base.push_layer!(designer::NeuralNetDesigner{T, I, O}, layer::Layer{T}) where T where I where O
        push!(designer.layers, layer.layer_function)
        designer.init_constant_vector
    end

end

struct NeuralNet{T, InputDim <: Integer, OutputDim <: Integer} <: AbstractMathmaticalFunction{T}
    layers::Array{Layer, 1}
    constants::ConstantPool{T}
    constant_bounds::Array{Bound{T}, 1}
    error_function::ErrorFunction{T}

    function NeuralNet{T, I, O}(designer::NeuralNetDesigner{T}) where T  where I where O
            new{T, I, O}(designer.input_length, designer.output_length, layers,
                designer.init_constant_vector, designer.constant_bounds, designer.error_function)
    end

    function (f::NeuralNet{T, I, O})(args::Input{T}; Data_Type=T) where T where I where O
            const_ptr = APtr(f.constants)
            output_vec = Data_Type[]
            for l in f.layers
                    args = l(const_ptr, output_vec, args)
                    const_ptr += l.constant_count
            end
    end
end

function train!(f::NeuralNet{T, I, O}, data::AbstractDataSet; optimizer::Optimizer{T}=blackboxoptimizer) where T where I where O
        optimizer(f.constants, 
                function (newcons)
                        for i in 1:length(newcons)
                                constants[i] = newcons[i]
                        end
                        error_function(data)
                end, f.constant_bounds)
end