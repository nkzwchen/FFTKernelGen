local CodeBlock = {}

function CodeBlock.GetCodeBlock(padding_num, sub_code_block)
    return {padding_num_ = padding_num, sub_code_block_ = sub_code_block}
end

function CodeBlock.ConvertCodeBlockToString(code_block)
    local codetype = type(code_block)
    if codetype == "string" then
        return code_block
    end

    local block_padding_num = 0

    if (code_block.padding_num_ > 0) then
        block_padding_num = code_block.padding_num_ - 1
    end
    
    local code_str = {"\n"}

    table.insert(code_str, string.rep("    ", block_padding_num))

    table.insert(code_str, "{\n")
    if codetype == "table" then
        for idx, sub_code_block in pairs(code_block.sub_code_block_) do
            table.insert(code_str, CodeBlock.ConvertCodeBlockToString(sub_code_block))
        end
    else
        print("wrong code block type")
        return nil
    end
    table.insert(code_str, string.rep("    ", block_padding_num))
    table.insert(code_str, "}\n\n")
    return table.concat(code_str, "", 1)
end

return CodeBlock