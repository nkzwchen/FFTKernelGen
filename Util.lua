local Util = {}

function Util.CreateVariable(name, data_type, mem_type)
    return {name_= name, data_type_ = data_type, mem_type_ = mem_type or "private"}
end

function Util.GetCodeBlock(padding_num, sub_code_block)
    return {padding_num_ = padding_num, sub_code_block_ = sub_code_block}
end

function Util.ConvertCodeBlockToString(code_block)
    local codetype = type(code_block)
    if codetype == "string" then
        return code_block
    end

    local block_padding_num = 0

    if (code_block.padding_num_ > 0) then
        block_padding_num = code_block.padding_num_ - 1
    end

    local code_str = {string.rep("    ", block_padding_num)}

    table.insert(code_str, "{\n")
    if codetype == "table" then
        for idx, sub_code_block in pairs(code_block.sub_code_block_) do
            table.insert(code_str, ConvertCodeBlockToString(sub_code_block))
        end
    else
        print("wrong code block type")
        return nil
    end
    table.insert(code_str, string.rep("    ", block_padding_num))
    table.insert(code_str, "}\n")
    return table.concat(code_str)
end
