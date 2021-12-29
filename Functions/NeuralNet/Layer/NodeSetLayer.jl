export NodeSetLayer

function NodeSetLayer(input_size::Int, nodeWrappers::AbstractArray{Nodes.Node}, const_initializer)
    return Wrapper(
                function(ST, IT, OT)
                    nodes = [wrapper(ST, IT, OT) for wrapper in nodeWrappers]
                    constant_sum = 0
                    for node in nodes
                        constant_sum += node.constant_size
                    end
                    Layer{ST, IT, OT, input_size, length(nodes)}(constant_sum, const_initializer, 
                        Func{ST, IT, OT}(
                            function (constant_pointer, inputs, outputs)
                                for i in 1:length(nodes)
                                    outputs[i] = nodes[i](constant_pointer, inputs)
                                    increment!(constant_pointer, nodes[i].constant_size)
                                end
                            end))
                end)
end