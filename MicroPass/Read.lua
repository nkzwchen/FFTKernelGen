
local Read = {}

function Read.CodeBlock(padding_num, offset, local_id)
    
    if (Info.micro_pass_info.input_type_ == "global") then
        return GlobalReadOffset(padding_num, offset, local_id)

end





