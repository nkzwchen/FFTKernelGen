local Variable = {}

function Variable.CreateVariable(name, data_type, mem_type)
    return {name_= name, data_type_ = data_type, mem_type_ = mem_type or "private"}
end

return Variable